package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"

	"noobie/backend/internal"
)

func main() {
	app := pocketbase.New()

	dataDir := getenv("NOOBIE_DATA_DIR", filepath.Join(".", "data"))
	store, err := internal.OpenStore(filepath.Join(dataDir, "noobie.db"))
	if err != nil {
		log.Fatal(err)
	}
	defer store.Close()

	rentals := internal.NewRentalProxy(os.Getenv("DOMAIN_API_TOKEN"), nil)
	importer := internal.NewOverpassImporter(nil, os.Getenv("OVERPASS_ENDPOINT"))

	app.OnBootstrap().BindFunc(func(e *core.BootstrapEvent) error {
		if err := e.Next(); err != nil {
			return err
		}
		return internal.EnsurePocketBaseCollections(e.App)
	})

	app.OnServe().BindFunc(func(e *core.ServeEvent) error {
		router := e.Router
		router.GET("/api/noobie/health", func(e *core.RequestEvent) error {
			return e.JSON(http.StatusOK, map[string]any{"ok": true, "service": "noobie-backend"})
		})
		router.GET("/api/noobie/states", func(e *core.RequestEvent) error {
			items, err := internal.PocketStates(e.App)
			if err != nil {
				items, err = store.States(e.Request.Context())
			}
			return jsonResult(e, internal.SearchResponse[internal.State]{Items: items}, err)
		})
		router.GET("/api/noobie/cities", func(e *core.RequestEvent) error {
			items, err := internal.PocketCities(e.App, e.Request.URL.Query().Get("state"))
			if err != nil {
				items, err = store.Cities(e.Request.Context(), e.Request.URL.Query().Get("state"))
			}
			return jsonResult(e, internal.SearchResponse[internal.City]{Items: items}, err)
		})
		router.GET("/api/noobie/place-categories", func(e *core.RequestEvent) error {
			items, err := internal.PocketPlaceCategories(e.App)
			if err != nil {
				items, err = store.PlaceCategories(e.Request.Context())
			}
			return jsonResult(e, internal.SearchResponse[internal.PlaceCategory]{Items: items}, err)
		})
		router.GET("/api/noobie/places/search", func(e *core.RequestEvent) error {
			query := e.Request.URL.Query()
			filter := internal.PlaceFilter{
				State:    query.Get("state"),
				City:     query.Get("city"),
				Category: query.Get("category"),
				Query:    query.Get("q"),
				Limit:    intQuery(e, "limit", 40),
			}
			items, err := internal.PocketPlaces(e.App, filter)
			if err != nil {
				items, err = store.Places(e.Request.Context(), filter)
			}
			return jsonResult(e, internal.SearchResponse[internal.Place]{Items: items}, err)
		})
		router.GET("/api/noobie/guides/search", func(e *core.RequestEvent) error {
			query := e.Request.URL.Query()
			filter := internal.GuideFilter{
				State:    query.Get("state"),
				Category: query.Get("category"),
				Query:    query.Get("q"),
				Limit:    intQuery(e, "limit", 30),
			}
			items, err := internal.PocketGuides(e.App, filter)
			if err != nil {
				items, err = store.Guides(e.Request.Context(), filter)
			}
			return jsonResult(e, internal.SearchResponse[internal.Guide]{Items: items}, err)
		})
		router.GET("/api/noobie/checklists", func(e *core.RequestEvent) error {
			items, err := internal.PocketChecklists(e.App)
			if err != nil {
				items, err = store.Checklists(e.Request.Context())
			}
			return jsonResult(e, internal.SearchResponse[internal.Checklist]{Items: items}, err)
		})
		router.GET("/api/noobie/map-link", func(e *core.RequestEvent) error {
			query := e.Request.URL.Query()
			lat, latErr := strconv.ParseFloat(query.Get("lat"), 64)
			lng, lngErr := strconv.ParseFloat(query.Get("lng"), 64)
			if latErr != nil || lngErr != nil {
				return e.JSON(http.StatusBadRequest, map[string]string{"error": "lat and lng are required numbers"})
			}
			return e.JSON(http.StatusOK, internal.MapLinksFor(query.Get("name"), lat, lng))
		})
		router.POST("/api/noobie/assistant/ask", func(e *core.RequestEvent) error {
			var body assistantRequest
			if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
				return e.JSON(http.StatusBadRequest, map[string]string{"error": "invalid JSON body"})
			}
			answer, err := internal.PocketAssistant(e.Request.Context(), e.App, body.Question, body.State)
			if err != nil {
				answer, err = store.Assistant(e.Request.Context(), body.Question, body.State)
			}
			return jsonResult(e, answer, err)
		})
		router.POST("/api/noobie/rentals/search", func(e *core.RequestEvent) error {
			var body rentalRequest
			if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
				return e.JSON(http.StatusBadRequest, map[string]string{"error": "invalid JSON body"})
			}
			items, err := rentals.Search(e.Request.Context(), body.Suburb, body.MaxWeeklyRent)
			return jsonResult(e, internal.SearchResponse[internal.RentalListing]{Items: items}, err)
		})
		router.POST("/api/noobie/import/overpass", func(e *core.RequestEvent) error {
			if err := requireImportKey(e.Request); err != nil {
				return e.JSON(http.StatusForbidden, map[string]string{"error": err.Error()})
			}
			var body importRequest
			if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
				return e.JSON(http.StatusBadRequest, map[string]string{"error": "invalid JSON body"})
			}
			count, err := importer.ImportCategory(e.Request.Context(), store, body.CityID, body.CategoryID, body.RadiusMeters)
			return jsonResult(e, map[string]any{"imported": count}, err)
		})
		return e.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}

type assistantRequest struct {
	Question string `json:"question"`
	State    string `json:"state"`
}

type rentalRequest struct {
	Suburb        string `json:"suburb"`
	MaxWeeklyRent int    `json:"max_weekly_rent"`
}

type importRequest struct {
	CityID       string `json:"city_id"`
	CategoryID   string `json:"category_id"`
	RadiusMeters int    `json:"radius_meters"`
}

func jsonResult(e *core.RequestEvent, data any, err error) error {
	if err != nil {
		status := http.StatusInternalServerError
		if errors.Is(err, context.Canceled) {
			status = http.StatusRequestTimeout
		}
		return e.JSON(status, map[string]string{"error": err.Error()})
	}
	return e.JSON(http.StatusOK, data)
}

func intQuery(e *core.RequestEvent, key string, fallback int) int {
	value, err := strconv.Atoi(e.Request.URL.Query().Get(key))
	if err != nil {
		return fallback
	}
	return value
}

func requireImportKey(req *http.Request) error {
	expected := strings.TrimSpace(os.Getenv("NOOBIE_IMPORT_KEY"))
	if expected == "" {
		return errors.New("NOOBIE_IMPORT_KEY must be set before importing public OSM data")
	}
	if req.Header.Get("X-Noobie-Import-Key") != expected {
		return errors.New("invalid import key")
	}
	return nil
}

func getenv(key, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	return fallback
}
