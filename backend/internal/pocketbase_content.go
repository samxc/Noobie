package internal

import (
	"context"
	"sort"
	"strings"

	"github.com/pocketbase/pocketbase/core"
)

func PocketStates(app core.App) ([]State, error) {
	records, err := app.FindAllRecords("noobie_states")
	if err != nil {
		return nil, err
	}
	items := make([]State, 0, len(records))
	for _, record := range records {
		items = append(items, State{Code: record.GetString("code"), Name: record.GetString("name")})
	}
	sort.Slice(items, func(a, b int) bool { return items[a].Name < items[b].Name })
	return items, nil
}

func PocketCities(app core.App, state string) ([]City, error) {
	records, err := app.FindAllRecords("noobie_cities")
	if err != nil {
		return nil, err
	}
	state = strings.ToUpper(strings.TrimSpace(state))
	items := []City{}
	for _, record := range records {
		item := City{
			ID:        record.GetString("external_id"),
			State:     record.GetString("state"),
			Name:      record.GetString("name"),
			Latitude:  record.GetFloat("latitude"),
			Longitude: record.GetFloat("longitude"),
		}
		if state == "" || item.State == state {
			items = append(items, item)
		}
	}
	sort.Slice(items, func(a, b int) bool {
		if items[a].State == items[b].State {
			return items[a].Name < items[b].Name
		}
		return items[a].State < items[b].State
	})
	return items, nil
}

func PocketPlaceCategories(app core.App) ([]PlaceCategory, error) {
	records, err := app.FindAllRecords("noobie_place_categories")
	if err != nil {
		return nil, err
	}
	items := make([]PlaceCategory, 0, len(records))
	for _, record := range records {
		items = append(items, PlaceCategory{
			ID:          record.GetString("external_id"),
			Label:       record.GetString("label"),
			Description: record.GetString("description"),
			OSMFilter:   record.GetString("osm_filter"),
		})
	}
	sort.Slice(items, func(a, b int) bool { return items[a].Label < items[b].Label })
	return items, nil
}

func PocketPlaces(app core.App, filter PlaceFilter) ([]Place, error) {
	records, err := app.FindAllRecords("noobie_places")
	if err != nil {
		return nil, err
	}
	categoryLabels := map[string]string{}
	if categories, err := PocketPlaceCategories(app); err == nil {
		for _, category := range categories {
			categoryLabels[category.ID] = category.Label
		}
	}
	limit := filter.Limit
	if limit <= 0 || limit > 100 {
		limit = 40
	}
	query := strings.ToLower(strings.TrimSpace(filter.Query))
	items := []Place{}
	for _, record := range records {
		item := Place{
			ID:            record.GetString("external_id"),
			Name:          record.GetString("name"),
			Category:      record.GetString("category"),
			CategoryLabel: categoryLabels[record.GetString("category")],
			State:         record.GetString("state"),
			City:          record.GetString("city"),
			Address:       record.GetString("address"),
			Latitude:      record.GetFloat("latitude"),
			Longitude:     record.GetFloat("longitude"),
			Phone:         record.GetString("phone"),
			Website:       record.GetString("website"),
			OpeningHours:  record.GetString("opening_hours"),
			Source:        record.GetString("source"),
			Tags:          record.GetStringSlice("tags"),
		}
		item.MapLinks = MapLinksFor(item.Name, item.Latitude, item.Longitude)
		if filter.State != "" && item.State != strings.ToUpper(filter.State) {
			continue
		}
		if filter.City != "" && !strings.EqualFold(item.City, filter.City) {
			continue
		}
		if filter.Category != "" && item.Category != filter.Category {
			continue
		}
		if query != "" && !containsAnyLower(query, item.Name, item.Address, strings.Join(item.Tags, " ")) {
			continue
		}
		items = append(items, item)
	}
	sort.Slice(items, func(a, b int) bool { return items[a].Name < items[b].Name })
	if len(items) > limit {
		items = items[:limit]
	}
	return items, nil
}

func PocketGuides(app core.App, filter GuideFilter) ([]Guide, error) {
	records, err := app.FindAllRecords("noobie_guides")
	if err != nil {
		return nil, err
	}
	categoryLabels := map[string]string{}
	if categories, err := PocketGuideCategories(app); err == nil {
		for _, category := range categories {
			categoryLabels[category.ID] = category.Label
		}
	}
	limit := filter.Limit
	if limit <= 0 || limit > 100 {
		limit = 30
	}
	queryTerms := searchTerms(filter.Query)
	items := []Guide{}
	for _, record := range records {
		item := Guide{
			ID:            record.GetString("external_id"),
			Category:      record.GetString("category"),
			CategoryLabel: categoryLabels[record.GetString("category")],
			Title:         record.GetString("title"),
			Summary:       record.GetString("summary"),
			Body:          record.GetString("body"),
			State:         record.GetString("state"),
			Priority:      record.GetInt("priority"),
			Tags:          record.GetStringSlice("tags"),
			OfficialURL:   record.GetString("official_url"),
		}
		if filter.Category != "" && item.Category != filter.Category {
			continue
		}
		if filter.State != "" && item.State != "" && item.State != strings.ToUpper(filter.State) {
			continue
		}
		haystack := strings.ToLower(item.Title + " " + item.Summary + " " + item.Body + " " + strings.Join(item.Tags, " "))
		if len(queryTerms) > 0 && !matchesAnyTerm(haystack, queryTerms) {
			continue
		}
		items = append(items, item)
	}
	sort.Slice(items, func(a, b int) bool {
		if items[a].Priority == items[b].Priority {
			return items[a].Title < items[b].Title
		}
		return items[a].Priority > items[b].Priority
	})
	if len(items) > limit {
		items = items[:limit]
	}
	return items, nil
}

func PocketGuideCategories(app core.App) ([]GuideCategory, error) {
	records, err := app.FindAllRecords("noobie_guide_categories")
	if err != nil {
		return nil, err
	}
	items := make([]GuideCategory, 0, len(records))
	for _, record := range records {
		items = append(items, GuideCategory{
			ID:          record.GetString("external_id"),
			Label:       record.GetString("label"),
			Description: record.GetString("description"),
		})
	}
	return items, nil
}

func PocketChecklists(app core.App) ([]Checklist, error) {
	records, err := app.FindAllRecords("noobie_checklists")
	if err != nil {
		return nil, err
	}
	items := make([]Checklist, 0, len(records))
	for _, record := range records {
		items = append(items, Checklist{
			ID:       record.GetString("external_id"),
			Title:    record.GetString("title"),
			Stage:    record.GetString("stage"),
			Items:    record.GetStringSlice("items"),
			Priority: record.GetInt("priority"),
		})
	}
	sort.Slice(items, func(a, b int) bool { return items[a].Priority > items[b].Priority })
	return items, nil
}

func PocketAssistant(ctx context.Context, app core.App, question, state string) (AssistantAnswer, error) {
	question = strings.TrimSpace(question)
	if question == "" {
		return AssistantAnswer{Answer: "Ask me about health, rooms, jobs, transport, groceries, scams or study support.", Guides: []Guide{}, Places: []Place{}}, nil
	}
	guides, err := PocketGuides(app, GuideFilter{Query: question, State: state, Limit: 5})
	if err != nil {
		return AssistantAnswer{}, err
	}
	places, err := PocketPlaces(app, PlaceFilter{State: state, Query: question, Limit: 5})
	if err != nil {
		return AssistantAnswer{}, err
	}
	if guides == nil {
		guides = []Guide{}
	}
	if places == nil {
		places = []Place{}
	}
	return AssistantAnswer{Answer: composeAnswer(question, guides, places), Guides: guides, Places: places}, nil
}

func containsAnyLower(query string, values ...string) bool {
	for _, value := range values {
		if strings.Contains(strings.ToLower(value), query) {
			return true
		}
	}
	return false
}

func matchesAnyTerm(haystack string, terms []string) bool {
	for _, term := range terms {
		if strings.Contains(haystack, term) {
			return true
		}
	}
	return false
}

func searchTerms(query string) []string {
	stop := map[string]bool{
		"a": true, "an": true, "and": true, "are": true, "do": true, "for": true,
		"how": true, "i": true, "in": true, "is": true, "it": true, "of": true,
		"or": true, "should": true, "the": true, "to": true, "what": true, "when": true,
	}
	raw := strings.FieldsFunc(strings.ToLower(query), func(r rune) bool {
		return !(r >= 'a' && r <= 'z') && !(r >= '0' && r <= '9')
	})
	terms := []string{}
	for _, term := range raw {
		if len(term) < 2 || stop[term] {
			continue
		}
		terms = append(terms, term)
	}
	return terms
}
