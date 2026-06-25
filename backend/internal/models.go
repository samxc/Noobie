package internal

type State struct {
	Code string `json:"code"`
	Name string `json:"name"`
}

type City struct {
	ID        string  `json:"id"`
	State     string  `json:"state"`
	Name      string  `json:"name"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type PlaceCategory struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	Description string `json:"description"`
	OSMFilter   string `json:"osm_filter"`
}

type Place struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	Category      string   `json:"category"`
	CategoryLabel string   `json:"category_label"`
	State         string   `json:"state"`
	City          string   `json:"city"`
	Address       string   `json:"address"`
	Latitude      float64  `json:"latitude"`
	Longitude     float64  `json:"longitude"`
	Phone         string   `json:"phone,omitempty"`
	Website       string   `json:"website,omitempty"`
	OpeningHours  string   `json:"opening_hours,omitempty"`
	Source        string   `json:"source"`
	Tags          []string `json:"tags"`
	MapLinks      MapLinks `json:"map_links"`
}

type GuideCategory struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	Description string `json:"description"`
}

type Guide struct {
	ID            string   `json:"id"`
	Category      string   `json:"category"`
	CategoryLabel string   `json:"category_label"`
	Title         string   `json:"title"`
	Summary       string   `json:"summary"`
	Body          string   `json:"body"`
	State         string   `json:"state,omitempty"`
	Priority      int      `json:"priority"`
	Tags          []string `json:"tags"`
	OfficialURL   string   `json:"official_url,omitempty"`
}

type Checklist struct {
	ID       string   `json:"id"`
	Title    string   `json:"title"`
	Stage    string   `json:"stage"`
	Items    []string `json:"items"`
	Priority int      `json:"priority"`
}

type Translation struct {
	ID       string `json:"id"`
	Locale   string `json:"locale"`
	Key      string `json:"key"`
	Value    string `json:"value"`
	Reviewed bool   `json:"reviewed"`
}

type RentalListing struct {
	ID         string   `json:"id"`
	Price      string   `json:"price"`
	Address    string   `json:"address"`
	Beds       int      `json:"beds"`
	Baths      int      `json:"baths"`
	Commute    string   `json:"commute"`
	SafetyNote string   `json:"safety_note"`
	ImageURL   string   `json:"image_url"`
	Source     string   `json:"source"`
	Tags       []string `json:"tags"`
}

type AssistantAnswer struct {
	Answer string  `json:"answer"`
	Guides []Guide `json:"guides"`
	Places []Place `json:"places"`
}

type MapLinks struct {
	Google string `json:"google"`
	Apple  string `json:"apple"`
	Geo    string `json:"geo"`
}

type SearchResponse[T any] struct {
	Items []T `json:"items"`
}
