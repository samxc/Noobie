package internal

import (
	"database/sql"
	"errors"

	"github.com/pocketbase/pocketbase/core"
)

func EnsurePocketBaseCollections(app core.App) error {
	definitions := []collectionDefinition{
		{
			name: "noobie_states",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("code", true, true),
				textField("name", true, true),
			},
		},
		{
			name: "noobie_cities",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("state", true, false),
				textField("name", true, true),
				numberField("latitude", true, false),
				numberField("longitude", true, false),
			},
		},
		{
			name: "noobie_place_categories",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("label", true, true),
				textField("description", true, false),
				textField("osm_filter", true, false),
			},
		},
		{
			name: "noobie_places",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("name", true, true),
				textField("category", true, false),
				textField("state", true, false),
				textField("city", true, false),
				textField("address", true, false),
				numberField("latitude", true, false),
				numberField("longitude", true, false),
				textField("phone", false, false),
				urlField("website", false, false),
				textField("opening_hours", false, false),
				textField("source", true, false),
				jsonField("tags", false),
			},
		},
		{
			name: "noobie_guide_categories",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("label", true, true),
				textField("description", true, false),
			},
		},
		{
			name: "noobie_guides",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("category", true, false),
				textField("title", true, true),
				textField("summary", true, false),
				textField("body", true, false),
				textField("state", false, false),
				numberField("priority", true, false),
				jsonField("tags", false),
				urlField("official_url", false, false),
			},
		},
		{
			name: "noobie_checklists",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("title", true, true),
				textField("stage", true, false),
				jsonField("items", true),
				numberField("priority", true, false),
			},
		},
		{
			name: "noobie_translations",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("locale", true, false),
				textField("key", true, true),
				textField("value", true, false),
				&core.BoolField{Name: "reviewed"},
			},
		},
		{
			name: "noobie_rental_sources",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("label", true, true),
				&core.BoolField{Name: "enabled"},
				jsonField("config", false),
			},
		},
		{
			name: "noobie_assistant_answers",
			fields: []core.Field{
				textField("external_id", true, false),
				textField("intent", true, true),
				jsonField("patterns", true),
				textField("answer_template", true, false),
			},
		},
		{
			name: "noobie_saved_items",
			fields: []core.Field{
				textField("user_id", true, false),
				textField("item_type", true, false),
				textField("item_id", true, false),
			},
		},
	}

	for _, definition := range definitions {
		if err := ensureCollection(app, definition); err != nil {
			return err
		}
	}
	return seedPocketBaseContent(app)
}

type collectionDefinition struct {
	name   string
	fields []core.Field
}

func ensureCollection(app core.App, definition collectionDefinition) error {
	if _, err := app.FindCollectionByNameOrId(definition.name); err == nil {
		return nil
	} else if !errors.Is(err, sql.ErrNoRows) {
		return err
	}

	collection := core.NewBaseCollection(definition.name)
	listRule := ""
	collection.ListRule = &listRule
	collection.ViewRule = &listRule
	for _, field := range definition.fields {
		collection.Fields.Add(field)
	}
	if collection.Fields.GetByName("external_id") != nil {
		collection.AddIndex("idx_"+definition.name+"_external_id", true, "external_id", "")
	}
	collection.Fields.Add(&core.AutodateField{Name: "created", OnCreate: true})
	collection.Fields.Add(&core.AutodateField{Name: "updated", OnCreate: true, OnUpdate: true})
	return app.Save(collection)
}

func seedPocketBaseContent(app core.App) error {
	for _, item := range seedStates {
		if err := upsertPocketRecord(app, "noobie_states", item.Code, map[string]any{"external_id": item.Code, "code": item.Code, "name": item.Name}); err != nil {
			return err
		}
	}
	for _, item := range seedCities {
		if err := upsertPocketRecord(app, "noobie_cities", item.ID, map[string]any{"external_id": item.ID, "state": item.State, "name": item.Name, "latitude": item.Latitude, "longitude": item.Longitude}); err != nil {
			return err
		}
	}
	for _, item := range seedPlaceCategories {
		if err := upsertPocketRecord(app, "noobie_place_categories", item.ID, map[string]any{"external_id": item.ID, "label": item.Label, "description": item.Description, "osm_filter": item.OSMFilter}); err != nil {
			return err
		}
	}
	for _, item := range seedPlaces {
		if err := upsertPocketRecord(app, "noobie_places", item.ID, map[string]any{"external_id": item.ID, "name": item.Name, "category": item.Category, "state": item.State, "city": item.City, "address": item.Address, "latitude": item.Latitude, "longitude": item.Longitude, "phone": item.Phone, "website": item.Website, "opening_hours": item.OpeningHours, "source": item.Source, "tags": item.Tags}); err != nil {
			return err
		}
	}
	for _, item := range seedGuideCategories {
		if err := upsertPocketRecord(app, "noobie_guide_categories", item.ID, map[string]any{"external_id": item.ID, "label": item.Label, "description": item.Description}); err != nil {
			return err
		}
	}
	for _, item := range seedGuides {
		if err := upsertPocketRecord(app, "noobie_guides", item.ID, map[string]any{"external_id": item.ID, "category": item.Category, "title": item.Title, "summary": item.Summary, "body": item.Body, "state": item.State, "priority": item.Priority, "tags": item.Tags, "official_url": item.OfficialURL}); err != nil {
			return err
		}
	}
	for _, item := range seedChecklists {
		if err := upsertPocketRecord(app, "noobie_checklists", item.ID, map[string]any{"external_id": item.ID, "title": item.Title, "stage": item.Stage, "items": item.Items, "priority": item.Priority}); err != nil {
			return err
		}
	}
	if err := upsertPocketRecord(app, "noobie_rental_sources", "domain", map[string]any{"external_id": "domain", "label": "Domain", "enabled": false, "config": map[string]any{}}); err != nil {
		return err
	}
	return nil
}

func upsertPocketRecord(app core.App, collectionName, externalID string, values map[string]any) error {
	collection, err := app.FindCollectionByNameOrId(collectionName)
	if err != nil {
		return err
	}
	record, err := app.FindFirstRecordByData(collection, "external_id", externalID)
	if err != nil {
		if !errors.Is(err, sql.ErrNoRows) {
			return err
		}
		record = core.NewRecord(collection)
	}
	for key, value := range values {
		record.Set(key, value)
	}
	return app.Save(record)
}

func textField(name string, required bool, presentable bool) *core.TextField {
	return &core.TextField{Name: name, Required: required, Presentable: presentable, Max: 20000}
}

func numberField(name string, required bool, onlyInt bool) *core.NumberField {
	return &core.NumberField{Name: name, Required: required, OnlyInt: onlyInt}
}

func jsonField(name string, required bool) *core.JSONField {
	return &core.JSONField{Name: name, Required: required}
}

func urlField(name string, required bool, presentable bool) *core.URLField {
	return &core.URLField{Name: name, Required: required, Presentable: presentable}
}
