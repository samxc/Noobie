package internal

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"time"
)

const defaultOverpassEndpoint = "https://overpass-api.de/api/interpreter"

type OverpassImporter struct {
	client   *http.Client
	endpoint string
}

func NewOverpassImporter(client *http.Client, endpoint string) *OverpassImporter {
	if client == nil {
		client = &http.Client{Timeout: 30 * time.Second}
	}
	if endpoint == "" {
		endpoint = defaultOverpassEndpoint
	}
	return &OverpassImporter{client: client, endpoint: endpoint}
}

func (i *OverpassImporter) ImportCategory(ctx context.Context, store *Store, cityID, categoryID string, radiusMeters int) (int, error) {
	if radiusMeters <= 0 || radiusMeters > 10000 {
		radiusMeters = 5000
	}
	city, err := store.CityByID(ctx, cityID)
	if err != nil {
		return 0, fmt.Errorf("city %q: %w", cityID, err)
	}
	category, err := store.PlaceCategoryByID(ctx, categoryID)
	if err != nil {
		return 0, fmt.Errorf("category %q: %w", categoryID, err)
	}

	query := BuildOverpassQuery(city, category, radiusMeters)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, i.endpoint, strings.NewReader(url.Values{"data": {query}}.Encode()))
	if err != nil {
		return 0, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("User-Agent", "Noobie/0.1 places cache importer")

	res, err := i.client.Do(req)
	if err != nil {
		return 0, err
	}
	defer res.Body.Close()
	if res.StatusCode < 200 || res.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(res.Body, 4096))
		return 0, fmt.Errorf("overpass returned %d: %s", res.StatusCode, strings.TrimSpace(string(body)))
	}

	places, err := ParseOverpassPlaces(res.Body, city, category)
	if err != nil {
		return 0, err
	}
	return store.ImportPlaces(ctx, places)
}

func BuildOverpassQuery(city City, category PlaceCategory, radiusMeters int) string {
	filter := strings.TrimSpace(category.OSMFilter)
	if filter == "" {
		filter = `["name"]`
	}
	return fmt.Sprintf(`[out:json][timeout:25];
(
  node%s(around:%d,%.6f,%.6f);
  way%s(around:%d,%.6f,%.6f);
  relation%s(around:%d,%.6f,%.6f);
);
out center tags 80;`, filter, radiusMeters, city.Latitude, city.Longitude, filter, radiusMeters, city.Latitude, city.Longitude, filter, radiusMeters, city.Latitude, city.Longitude)
}

func ParseOverpassPlaces(reader io.Reader, city City, category PlaceCategory) ([]Place, error) {
	var payload overpassPayload
	if err := json.NewDecoder(reader).Decode(&payload); err != nil {
		return nil, err
	}

	seen := map[string]bool{}
	places := make([]Place, 0, len(payload.Elements))
	for _, element := range payload.Elements {
		place, ok := element.toPlace(city, category)
		if !ok || seen[place.ID] {
			continue
		}
		seen[place.ID] = true
		places = append(places, place)
	}
	sort.Slice(places, func(a, b int) bool {
		return places[a].Name < places[b].Name
	})
	return places, nil
}

type overpassPayload struct {
	Elements []overpassElement `json:"elements"`
}

type overpassElement struct {
	Type   string            `json:"type"`
	ID     int64             `json:"id"`
	Lat    float64           `json:"lat"`
	Lon    float64           `json:"lon"`
	Center overpassCenter    `json:"center"`
	Tags   map[string]string `json:"tags"`
}

type overpassCenter struct {
	Lat float64 `json:"lat"`
	Lon float64 `json:"lon"`
}

func (e overpassElement) toPlace(city City, category PlaceCategory) (Place, bool) {
	name := strings.TrimSpace(e.Tags["name"])
	if name == "" {
		return Place{}, false
	}
	lat, lon := e.Lat, e.Lon
	if lat == 0 && lon == 0 {
		lat, lon = e.Center.Lat, e.Center.Lon
	}
	if lat == 0 && lon == 0 {
		return Place{}, false
	}

	tags := publicTags(e.Tags)
	return Place{
		ID:           fmt.Sprintf("osm:%s:%s:%d", category.ID, e.Type, e.ID),
		Name:         name,
		Category:     category.ID,
		State:        city.State,
		City:         city.Name,
		Address:      addressFromTags(e.Tags, city),
		Latitude:     lat,
		Longitude:    lon,
		Phone:        firstTag(e.Tags, "contact:phone", "phone"),
		Website:      firstTag(e.Tags, "contact:website", "website"),
		OpeningHours: e.Tags["opening_hours"],
		Source:       "overpass",
		Tags:         tags,
		MapLinks:     MapLinksFor(name, lat, lon),
	}, true
}

func addressFromTags(tags map[string]string, city City) string {
	parts := []string{}
	if value := strings.TrimSpace(strings.Join([]string{tags["addr:housenumber"], tags["addr:street"]}, " ")); value != "" {
		parts = append(parts, value)
	}
	for _, key := range []string{"addr:suburb", "addr:city", "addr:state", "addr:postcode"} {
		if value := strings.TrimSpace(tags[key]); value != "" {
			parts = append(parts, value)
		}
	}
	if len(parts) == 0 {
		return city.Name + " " + city.State
	}
	return strings.Join(parts, ", ")
}

func firstTag(tags map[string]string, keys ...string) string {
	for _, key := range keys {
		if value := strings.TrimSpace(tags[key]); value != "" {
			return value
		}
	}
	return ""
}

func publicTags(tags map[string]string) []string {
	keys := []string{"amenity", "shop", "tourism", "leisure", "railway", "public_transport", "brand", "operator"}
	values := []string{}
	for _, key := range keys {
		if value := strings.TrimSpace(tags[key]); value != "" {
			values = append(values, value)
		}
	}
	return values
}

func overpassFixture(body string) io.Reader {
	return bytes.NewBufferString(body)
}
