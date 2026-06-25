package internal

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

type RentalProxy struct {
	token  string
	client *http.Client
}

func NewRentalProxy(token string, client *http.Client) *RentalProxy {
	if client == nil {
		client = &http.Client{Timeout: 20 * time.Second}
	}
	return &RentalProxy{token: strings.TrimSpace(token), client: client}
}

func (p *RentalProxy) Search(ctx context.Context, suburb string, maxWeeklyRent int) ([]RentalListing, error) {
	suburb = strings.TrimSpace(suburb)
	if suburb == "" {
		suburb = "Sydney"
	}
	if maxWeeklyRent <= 0 {
		maxWeeklyRent = 450
	}
	if p.token == "" {
		return SampleRentals(suburb, maxWeeklyRent), nil
	}

	body, _ := json.Marshal(map[string]any{
		"listingType": "Rent",
		"locations": []map[string]string{
			{"state": "", "region": "", "area": "", "suburb": suburb},
		},
		"maxPrice": maxWeeklyRent,
		"pageSize": 12,
	})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://api.domain.com.au/v1/listings/residential/_search", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+p.token)
	req.Header.Set("Content-Type", "application/json")

	res, err := p.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode < 200 || res.StatusCode >= 300 {
		return nil, fmt.Errorf("domain rental search returned %d", res.StatusCode)
	}

	var raw []domainSearchItem
	if err := json.NewDecoder(res.Body).Decode(&raw); err != nil {
		return nil, err
	}
	items := make([]RentalListing, 0, len(raw))
	for _, item := range raw {
		if listing, ok := item.toRentalListing(); ok {
			items = append(items, listing)
		}
	}
	return items, nil
}

func SampleRentals(suburb string, maxWeeklyRent int) []RentalListing {
	return []RentalListing{
		{ID: "sample-glebe", Price: "$360/wk", Address: "Bright room near university links, Glebe NSW", Beds: 1, Baths: 1, Commute: "18m campus", SafetyNote: "Good transport, inspect street lighting", ImageURL: "https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80", Source: "Sample", Tags: []string{"sharehouse", "student"}},
		{ID: "sample-brunswick", Price: "$330/wk", Address: "Sharehouse room close to tram, Brunswick VIC", Beds: 1, Baths: 2, Commute: "12m tram", SafetyNote: "Ask about bills and quiet hours", ImageURL: "https://images.unsplash.com/photo-1560185007-cde436f6a4d0?auto=format&fit=crop&w=1200&q=80", Source: "Sample", Tags: []string{"tram", "sharehouse"}},
		{ID: "sample-westend", Price: "$310/wk", Address: "Student-friendly unit room, West End QLD", Beds: 1, Baths: 1, Commute: "22m bus", SafetyNote: "Verify bond lodging before payment", ImageURL: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80", Source: "Sample", Tags: []string{"bond", "bus"}},
		{ID: "sample-parramatta", Price: "$340/wk", Address: "Room near station and shops, Parramatta NSW", Beds: 1, Baths: 2, Commute: "7m station", SafetyNote: "Inspect locks, mould and kitchen storage", ImageURL: "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80", Source: "Sample", Tags: []string{"station", "shops"}},
	}
}

type domainSearchItem struct {
	Listing domainListing `json:"listing"`
}

type domainListing struct {
	ID              any                   `json:"id"`
	ListingID       any                   `json:"listingId"`
	Price           any                   `json:"price"`
	DisplayAddress  string                `json:"displayableAddress"`
	PropertyDetails domainPropertyDetails `json:"propertyDetails"`
	PriceDetails    domainPriceDetails    `json:"priceDetails"`
	Media           []domainMedia         `json:"media"`
}

type domainPropertyDetails struct {
	DisplayAddress string `json:"displayableAddress"`
	Bedrooms       int    `json:"bedrooms"`
	Bathrooms      int    `json:"bathrooms"`
}

type domainPriceDetails struct {
	DisplayPrice string `json:"displayPrice"`
}

type domainMedia struct {
	URL string `json:"url"`
}

func (i domainSearchItem) toRentalListing() (RentalListing, bool) {
	listing := i.Listing
	id := fmt.Sprintf("%v", coalesce(fmt.Sprintf("%v", listing.ID), fmt.Sprintf("%v", listing.ListingID)))
	if id == "" || id == "<nil>" {
		return RentalListing{}, false
	}
	address := listing.PropertyDetails.DisplayAddress
	if address == "" {
		address = listing.DisplayAddress
	}
	if address == "" {
		address = "Address available on request"
	}
	price := listing.PriceDetails.DisplayPrice
	if price == "" {
		price = fmt.Sprintf("%v", listing.Price)
	}
	if price == "" || price == "<nil>" {
		price = "Contact agent"
	}
	image := "https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80"
	if len(listing.Media) > 0 && listing.Media[0].URL != "" {
		image = listing.Media[0].URL
	}
	return RentalListing{
		ID:         id,
		Price:      price,
		Address:    address,
		Beds:       listing.PropertyDetails.Bedrooms,
		Baths:      listing.PropertyDetails.Bathrooms,
		Commute:    "Check commute",
		SafetyNote: "Inspect lighting, locks and transport before applying",
		ImageURL:   image,
		Source:     "Domain",
		Tags:       []string{"live import"},
	}, true
}
