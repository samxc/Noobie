package internal

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"math"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	_ "modernc.org/sqlite"
)

type Store struct {
	db *sql.DB
}

type PlaceFilter struct {
	State    string
	City     string
	Category string
	Query    string
	Limit    int
}

type GuideFilter struct {
	Category string
	Query    string
	State    string
	Limit    int
}

func OpenStore(path string) (*Store, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return nil, err
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(1)

	store := &Store{db: db}
	if err := store.init(context.Background()); err != nil {
		_ = db.Close()
		return nil, err
	}
	return store, nil
}

func (s *Store) Close() error {
	return s.db.Close()
}

func (s *Store) init(ctx context.Context) error {
	statements := []string{
		`PRAGMA journal_mode=WAL`,
		`CREATE TABLE IF NOT EXISTS states (
			code TEXT PRIMARY KEY,
			name TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS cities (
			id TEXT PRIMARY KEY,
			state TEXT NOT NULL,
			name TEXT NOT NULL,
			latitude REAL NOT NULL,
			longitude REAL NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS place_categories (
			id TEXT PRIMARY KEY,
			label TEXT NOT NULL,
			description TEXT NOT NULL,
			osm_filter TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS places (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL,
			category TEXT NOT NULL,
			state TEXT NOT NULL,
			city TEXT NOT NULL,
			address TEXT NOT NULL,
			latitude REAL NOT NULL,
			longitude REAL NOT NULL,
			phone TEXT DEFAULT '',
			website TEXT DEFAULT '',
			opening_hours TEXT DEFAULT '',
			source TEXT NOT NULL,
			tags TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS guide_categories (
			id TEXT PRIMARY KEY,
			label TEXT NOT NULL,
			description TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS guides (
			id TEXT PRIMARY KEY,
			category TEXT NOT NULL,
			title TEXT NOT NULL,
			summary TEXT NOT NULL,
			body TEXT NOT NULL,
			state TEXT DEFAULT '',
			priority INTEGER NOT NULL,
			tags TEXT NOT NULL,
			official_url TEXT DEFAULT ''
		)`,
		`CREATE VIRTUAL TABLE IF NOT EXISTS guides_fts USING fts5(
			id UNINDEXED,
			title,
			summary,
			body,
			tags
		)`,
		`CREATE TABLE IF NOT EXISTS checklists (
			id TEXT PRIMARY KEY,
			title TEXT NOT NULL,
			stage TEXT NOT NULL,
			items TEXT NOT NULL,
			priority INTEGER NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS translations (
			id TEXT PRIMARY KEY,
			locale TEXT NOT NULL,
			key TEXT NOT NULL,
			value TEXT NOT NULL,
			reviewed INTEGER NOT NULL DEFAULT 0
		)`,
		`CREATE TABLE IF NOT EXISTS rental_sources (
			id TEXT PRIMARY KEY,
			label TEXT NOT NULL,
			enabled INTEGER NOT NULL DEFAULT 0,
			config TEXT NOT NULL DEFAULT '{}'
		)`,
		`CREATE TABLE IF NOT EXISTS assistant_answers (
			id TEXT PRIMARY KEY,
			intent TEXT NOT NULL,
			patterns TEXT NOT NULL,
			answer_template TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS saved_items (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			item_type TEXT NOT NULL,
			item_id TEXT NOT NULL,
			created_at TEXT DEFAULT CURRENT_TIMESTAMP
		)`,
	}

	for _, statement := range statements {
		if _, err := s.db.ExecContext(ctx, statement); err != nil {
			return err
		}
	}
	return s.seed(ctx)
}

func (s *Store) seed(ctx context.Context) error {
	var count int
	if err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM states`).Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	for _, item := range seedStates {
		if _, err := tx.ExecContext(ctx, `INSERT INTO states (code, name) VALUES (?, ?)`, item.Code, item.Name); err != nil {
			return err
		}
	}
	for _, item := range seedCities {
		if _, err := tx.ExecContext(ctx, `INSERT INTO cities (id, state, name, latitude, longitude) VALUES (?, ?, ?, ?, ?)`, item.ID, item.State, item.Name, item.Latitude, item.Longitude); err != nil {
			return err
		}
	}
	for _, item := range seedPlaceCategories {
		if _, err := tx.ExecContext(ctx, `INSERT INTO place_categories (id, label, description, osm_filter) VALUES (?, ?, ?, ?)`, item.ID, item.Label, item.Description, item.OSMFilter); err != nil {
			return err
		}
	}
	for _, item := range seedGuideCategories {
		if _, err := tx.ExecContext(ctx, `INSERT INTO guide_categories (id, label, description) VALUES (?, ?, ?)`, item.ID, item.Label, item.Description); err != nil {
			return err
		}
	}
	for _, item := range seedGuides {
		tags := mustJSON(item.Tags)
		if _, err := tx.ExecContext(ctx, `INSERT INTO guides (id, category, title, summary, body, state, priority, tags, official_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`, item.ID, item.Category, item.Title, item.Summary, item.Body, item.State, item.Priority, tags, item.OfficialURL); err != nil {
			return err
		}
		if _, err := tx.ExecContext(ctx, `INSERT INTO guides_fts (id, title, summary, body, tags) VALUES (?, ?, ?, ?, ?)`, item.ID, item.Title, item.Summary, item.Body, strings.Join(item.Tags, " ")); err != nil {
			return err
		}
	}
	for _, item := range seedChecklists {
		if _, err := tx.ExecContext(ctx, `INSERT INTO checklists (id, title, stage, items, priority) VALUES (?, ?, ?, ?, ?)`, item.ID, item.Title, item.Stage, mustJSON(item.Items), item.Priority); err != nil {
			return err
		}
	}
	for _, item := range seedPlaces {
		if _, err := tx.ExecContext(ctx, `INSERT INTO places (id, name, category, state, city, address, latitude, longitude, source, tags) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, item.ID, item.Name, item.Category, item.State, item.City, item.Address, item.Latitude, item.Longitude, item.Source, mustJSON(item.Tags)); err != nil {
			return err
		}
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO rental_sources (id, label, enabled, config) VALUES ('domain', 'Domain', 0, '{}')`); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *Store) States(ctx context.Context) ([]State, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT code, name FROM states ORDER BY name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []State
	for rows.Next() {
		var item State
		if err := rows.Scan(&item.Code, &item.Name); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) Cities(ctx context.Context, state string) ([]City, error) {
	query := `SELECT id, state, name, latitude, longitude FROM cities`
	args := []any{}
	if state != "" {
		query += ` WHERE state = ?`
		args = append(args, strings.ToUpper(state))
	}
	query += ` ORDER BY state, name`
	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []City
	for rows.Next() {
		var item City
		if err := rows.Scan(&item.ID, &item.State, &item.Name, &item.Latitude, &item.Longitude); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) CityByID(ctx context.Context, id string) (City, error) {
	var item City
	err := s.db.QueryRowContext(ctx, `SELECT id, state, name, latitude, longitude FROM cities WHERE id = ?`, id).
		Scan(&item.ID, &item.State, &item.Name, &item.Latitude, &item.Longitude)
	return item, err
}

func (s *Store) PlaceCategories(ctx context.Context) ([]PlaceCategory, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT id, label, description, osm_filter FROM place_categories ORDER BY label`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []PlaceCategory
	for rows.Next() {
		var item PlaceCategory
		if err := rows.Scan(&item.ID, &item.Label, &item.Description, &item.OSMFilter); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) PlaceCategoryByID(ctx context.Context, id string) (PlaceCategory, error) {
	var item PlaceCategory
	err := s.db.QueryRowContext(ctx, `SELECT id, label, description, osm_filter FROM place_categories WHERE id = ?`, id).
		Scan(&item.ID, &item.Label, &item.Description, &item.OSMFilter)
	return item, err
}

func (s *Store) Places(ctx context.Context, filter PlaceFilter) ([]Place, error) {
	limit := filter.Limit
	if limit <= 0 || limit > 100 {
		limit = 40
	}
	where := []string{"1 = 1"}
	args := []any{}
	if filter.State != "" {
		where = append(where, "p.state = ?")
		args = append(args, strings.ToUpper(filter.State))
	}
	if filter.City != "" {
		where = append(where, "lower(p.city) = lower(?)")
		args = append(args, filter.City)
	}
	if filter.Category != "" {
		where = append(where, "p.category = ?")
		args = append(args, filter.Category)
	}
	if filter.Query != "" {
		q := "%" + strings.ToLower(filter.Query) + "%"
		where = append(where, "(lower(p.name) LIKE ? OR lower(p.address) LIKE ? OR lower(p.tags) LIKE ?)")
		args = append(args, q, q, q)
	}
	args = append(args, limit)

	rows, err := s.db.QueryContext(ctx, `
		SELECT p.id, p.name, p.category, pc.label, p.state, p.city, p.address, p.latitude, p.longitude,
		       p.phone, p.website, p.opening_hours, p.source, p.tags
		FROM places p
		LEFT JOIN place_categories pc ON pc.id = p.category
		WHERE `+strings.Join(where, " AND ")+`
		ORDER BY p.source = 'seed' DESC, p.name
		LIMIT ?`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []Place
	for rows.Next() {
		item, err := scanPlace(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) Guides(ctx context.Context, filter GuideFilter) ([]Guide, error) {
	limit := filter.Limit
	if limit <= 0 || limit > 100 {
		limit = 30
	}
	args := []any{}

	var rows *sql.Rows
	var err error
	if strings.TrimSpace(filter.Query) != "" {
		ftsQuery := sanitizeFTS(filter.Query)
		where := []string{"guides_fts MATCH ?"}
		args = append(args, ftsQuery)
		if filter.Category != "" {
			where = append(where, "g.category = ?")
			args = append(args, filter.Category)
		}
		if filter.State != "" {
			where = append(where, "(g.state = '' OR g.state = ?)")
			args = append(args, strings.ToUpper(filter.State))
		}
		args = append(args, limit)
		rows, err = s.db.QueryContext(ctx, `
			SELECT g.id, g.category, gc.label, g.title, g.summary, g.body, g.state, g.priority, g.tags, g.official_url
			FROM guides_fts
			JOIN guides g ON g.id = guides_fts.id
			LEFT JOIN guide_categories gc ON gc.id = g.category
			WHERE `+strings.Join(where, " AND ")+`
			ORDER BY bm25(guides_fts), g.priority DESC
			LIMIT ?`, args...)
	} else {
		where := []string{"1 = 1"}
		if filter.Category != "" {
			where = append(where, "g.category = ?")
			args = append(args, filter.Category)
		}
		if filter.State != "" {
			where = append(where, "(g.state = '' OR g.state = ?)")
			args = append(args, strings.ToUpper(filter.State))
		}
		args = append(args, limit)
		rows, err = s.db.QueryContext(ctx, `
			SELECT g.id, g.category, gc.label, g.title, g.summary, g.body, g.state, g.priority, g.tags, g.official_url
			FROM guides g
			LEFT JOIN guide_categories gc ON gc.id = g.category
			WHERE `+strings.Join(where, " AND ")+`
			ORDER BY g.priority DESC, g.title
			LIMIT ?`, args...)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []Guide
	for rows.Next() {
		item, err := scanGuide(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) Checklists(ctx context.Context) ([]Checklist, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT id, title, stage, items, priority FROM checklists ORDER BY priority DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []Checklist
	for rows.Next() {
		var item Checklist
		var rawItems string
		if err := rows.Scan(&item.ID, &item.Title, &item.Stage, &rawItems, &item.Priority); err != nil {
			return nil, err
		}
		_ = json.Unmarshal([]byte(rawItems), &item.Items)
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) Assistant(ctx context.Context, question, state string) (AssistantAnswer, error) {
	question = strings.TrimSpace(question)
	if question == "" {
		return AssistantAnswer{Answer: "Ask me about health, rooms, jobs, transport, groceries, scams or study support."}, nil
	}

	guides, err := s.Guides(ctx, GuideFilter{Query: question, State: state, Limit: 5})
	if err != nil {
		return AssistantAnswer{}, err
	}
	places, err := s.Places(ctx, PlaceFilter{State: state, Query: question, Limit: 5})
	if err != nil {
		return AssistantAnswer{}, err
	}
	if guides == nil {
		guides = []Guide{}
	}
	if places == nil {
		places = []Place{}
	}

	answer := composeAnswer(question, guides, places)
	return AssistantAnswer{Answer: answer, Guides: guides, Places: places}, nil
}

func (s *Store) ImportPlaces(ctx context.Context, places []Place) (int, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback()

	count := 0
	for _, place := range places {
		if place.ID == "" || place.Name == "" || place.Category == "" || place.State == "" || place.City == "" {
			continue
		}
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO places (id, name, category, state, city, address, latitude, longitude, phone, website, opening_hours, source, tags)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(id) DO UPDATE SET
				name = excluded.name,
				category = excluded.category,
				state = excluded.state,
				city = excluded.city,
				address = excluded.address,
				latitude = excluded.latitude,
				longitude = excluded.longitude,
				phone = excluded.phone,
				website = excluded.website,
				opening_hours = excluded.opening_hours,
				source = excluded.source,
				tags = excluded.tags`,
			place.ID, place.Name, place.Category, place.State, place.City, place.Address,
			place.Latitude, place.Longitude, place.Phone, place.Website, place.OpeningHours,
			coalesce(place.Source, "overpass"), mustJSON(place.Tags)); err != nil {
			return 0, err
		}
		count++
	}
	return count, tx.Commit()
}

func MapLinksFor(name string, lat, lng float64) MapLinks {
	query := fmt.Sprintf("%.6f,%.6f", lat, lng)
	label := urlQuery(name)
	return MapLinks{
		Google: "https://www.google.com/maps/search/?api=1&query=" + query,
		Apple:  "https://maps.apple.com/?q=" + label + "&ll=" + query,
		Geo:    "geo:" + query + "?q=" + query + "(" + label + ")",
	}
}

func scanPlace(rows scanner) (Place, error) {
	var item Place
	var rawTags string
	if err := rows.Scan(&item.ID, &item.Name, &item.Category, &item.CategoryLabel, &item.State, &item.City, &item.Address, &item.Latitude, &item.Longitude, &item.Phone, &item.Website, &item.OpeningHours, &item.Source, &rawTags); err != nil {
		return item, err
	}
	_ = json.Unmarshal([]byte(rawTags), &item.Tags)
	item.MapLinks = MapLinksFor(item.Name, item.Latitude, item.Longitude)
	return item, nil
}

func scanGuide(rows scanner) (Guide, error) {
	var item Guide
	var rawTags string
	if err := rows.Scan(&item.ID, &item.Category, &item.CategoryLabel, &item.Title, &item.Summary, &item.Body, &item.State, &item.Priority, &rawTags, &item.OfficialURL); err != nil {
		return item, err
	}
	_ = json.Unmarshal([]byte(rawTags), &item.Tags)
	return item, nil
}

func composeAnswer(question string, guides []Guide, places []Place) string {
	lower := strings.ToLower(question)
	if strings.Contains(lower, "emergency") || strings.Contains(lower, "hospital") || strings.Contains(lower, "gp") || strings.Contains(lower, "doctor") {
		return "For urgent or life-threatening issues, call 000. For non-emergency health issues, a GP is usually your first stop. If you are unsure, call healthdirect on 1800 022 222. I found the guide cards below that explain what to do."
	}
	if strings.Contains(lower, "job") || strings.Contains(lower, "work") || strings.Contains(lower, "resume") {
		return "Start with safe, legal entry-level work like retail, hospitality, campus jobs, warehouse, tutoring or admin. Keep payslips, know your work-hour limits, and use the resume guide below to prepare applications."
	}
	if strings.Contains(lower, "room") || strings.Contains(lower, "rent") || strings.Contains(lower, "bond") {
		return "Inspect before paying, get terms in writing, check bond rules, and compare commute plus late-night safety. The housing guides and nearby place cards below are the best starting points."
	}
	if strings.Contains(lower, "grocery") || strings.Contains(lower, "shopping") || strings.Contains(lower, "chemist") {
		return "Use the place results below and open them in Maps. Compare supermarkets with local markets and cultural grocery stores; they can be cheaper for familiar staples."
	}
	if len(guides) == 0 && len(places) == 0 {
		return "I could not find a strong match yet. Try asking about GP, hospital, groceries, transport, rooms, rent, jobs, resume, TFN, OSHC, scams or budget."
	}
	return "Here are the most relevant Noobie guides and places I found. Start with the top guide, then open any saved place in Maps if it is location-specific."
}

func mustJSON(value any) string {
	data, _ := json.Marshal(value)
	return string(data)
}

func sanitizeFTS(query string) string {
	parts := strings.FieldsFunc(strings.ToLower(query), func(r rune) bool {
		return !(r >= 'a' && r <= 'z') && !(r >= '0' && r <= '9')
	})
	if len(parts) == 0 {
		return "*"
	}
	if len(parts) > 8 {
		parts = parts[:8]
	}
	return strings.Join(parts, " OR ")
}

func urlQuery(value string) string {
	return url.QueryEscape(strings.TrimSpace(value))
}

func coalesce(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}

func distanceKm(aLat, aLng, bLat, bLng float64) float64 {
	const earthRadiusKm = 6371.0
	dLat := (bLat - aLat) * math.Pi / 180
	dLng := (bLng - aLng) * math.Pi / 180
	lat1 := aLat * math.Pi / 180
	lat2 := bLat * math.Pi / 180
	h := math.Sin(dLat/2)*math.Sin(dLat/2) + math.Cos(lat1)*math.Cos(lat2)*math.Sin(dLng/2)*math.Sin(dLng/2)
	return 2 * earthRadiusKm * math.Asin(math.Sqrt(h))
}

type scanner interface {
	Scan(dest ...any) error
}
