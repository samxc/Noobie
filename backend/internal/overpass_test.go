package internal

import "testing"

func TestParseOverpassPlaces(t *testing.T) {
	city := City{ID: "sydney", State: "NSW", Name: "Sydney", Latitude: -33.8688, Longitude: 151.2093}
	category := PlaceCategory{ID: "groceries", Label: "Groceries"}

	places, err := ParseOverpassPlaces(overpassFixture(`{
		"elements": [
			{
				"type": "node",
				"id": 123,
				"lat": -33.87,
				"lon": 151.20,
				"tags": {
					"name": "Example Grocer",
					"shop": "supermarket",
					"addr:street": "George St",
					"addr:housenumber": "1",
					"opening_hours": "Mo-Fr 09:00-17:00"
				}
			}
		]
	}`), city, category)
	if err != nil {
		t.Fatal(err)
	}
	if len(places) != 1 {
		t.Fatalf("expected 1 place, got %d", len(places))
	}
	if places[0].ID != "osm:groceries:node:123" {
		t.Fatalf("unexpected id %q", places[0].ID)
	}
	if places[0].Address != "1 George St" {
		t.Fatalf("unexpected address %q", places[0].Address)
	}
}
