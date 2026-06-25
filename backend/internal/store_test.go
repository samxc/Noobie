package internal

import (
	"context"
	"strings"
	"testing"
)

func TestGuideSearchFindsGP(t *testing.T) {
	store, err := OpenStore(t.TempDir() + "/noobie.db")
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()

	guides, err := store.Guides(context.Background(), GuideFilter{Query: "what is a GP", Limit: 5})
	if err != nil {
		t.Fatal(err)
	}
	if len(guides) == 0 {
		t.Fatal("expected at least one guide")
	}
	if !strings.Contains(strings.ToLower(guides[0].Title), "gp") {
		t.Fatalf("expected top guide to mention GP, got %q", guides[0].Title)
	}
}

func TestPlaceFilterAndMapLinks(t *testing.T) {
	store, err := OpenStore(t.TempDir() + "/noobie.db")
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()

	places, err := store.Places(context.Background(), PlaceFilter{State: "NSW", City: "Sydney", Category: "groceries", Limit: 10})
	if err != nil {
		t.Fatal(err)
	}
	if len(places) == 0 {
		t.Fatal("expected grocery places in Sydney")
	}
	if places[0].MapLinks.Google == "" || places[0].MapLinks.Apple == "" || places[0].MapLinks.Geo == "" {
		t.Fatalf("expected map links, got %#v", places[0].MapLinks)
	}
}

func TestAssistantUsesHealthSafetyAnswer(t *testing.T) {
	store, err := OpenStore(t.TempDir() + "/noobie.db")
	if err != nil {
		t.Fatal(err)
	}
	defer store.Close()

	answer, err := store.Assistant(context.Background(), "Should I go to hospital or GP?", "NSW")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(answer.Answer, "000") {
		t.Fatalf("expected emergency disclaimer, got %q", answer.Answer)
	}
	if len(answer.Guides) == 0 {
		t.Fatal("expected guide source cards")
	}
}
