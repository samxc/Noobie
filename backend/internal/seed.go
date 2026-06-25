package internal

var seedStates = []State{
	{Code: "NSW", Name: "New South Wales"},
	{Code: "VIC", Name: "Victoria"},
	{Code: "QLD", Name: "Queensland"},
	{Code: "ACT", Name: "Australian Capital Territory"},
	{Code: "SA", Name: "South Australia"},
	{Code: "WA", Name: "Western Australia"},
	{Code: "TAS", Name: "Tasmania"},
	{Code: "NT", Name: "Northern Territory"},
}

var seedCities = []City{
	{ID: "sydney", State: "NSW", Name: "Sydney", Latitude: -33.8688, Longitude: 151.2093},
	{ID: "parramatta", State: "NSW", Name: "Parramatta", Latitude: -33.815, Longitude: 151.0011},
	{ID: "melbourne", State: "VIC", Name: "Melbourne", Latitude: -37.8136, Longitude: 144.9631},
	{ID: "brisbane", State: "QLD", Name: "Brisbane", Latitude: -27.4698, Longitude: 153.0251},
	{ID: "canberra", State: "ACT", Name: "Canberra", Latitude: -35.2809, Longitude: 149.13},
	{ID: "adelaide", State: "SA", Name: "Adelaide", Latitude: -34.9285, Longitude: 138.6007},
	{ID: "perth", State: "WA", Name: "Perth", Latitude: -31.9523, Longitude: 115.8613},
	{ID: "hobart", State: "TAS", Name: "Hobart", Latitude: -42.8821, Longitude: 147.3272},
	{ID: "darwin", State: "NT", Name: "Darwin", Latitude: -12.4634, Longitude: 130.8456},
}

var seedPlaceCategories = []PlaceCategory{
	{ID: "groceries", Label: "Groceries", Description: "Supermarkets, local grocers and affordable essentials.", OSMFilter: `["shop"~"supermarket|convenience|greengrocer|asian_food"]`},
	{ID: "shopping", Label: "Shopping", Description: "Shopping centres, discount stores and big-box essentials.", OSMFilter: `["shop"~"mall|department_store|clothes|variety_store"]`},
	{ID: "health", Label: "Health", Description: "GPs, pharmacies, urgent care and hospitals.", OSMFilter: `["amenity"~"doctors|pharmacy|clinic|hospital"]`},
	{ID: "transport", Label: "Transport", Description: "Major stations and transport hubs.", OSMFilter: `["public_transport"~"station|stop_position"]["railway"~"station|tram_stop"]`},
	{ID: "fun", Label: "Fun & Travel", Description: "Parks, beaches, lookouts, museums, hikes and camping.", OSMFilter: `["tourism"~"attraction|museum|viewpoint|camp_site"]["leisure"~"park|nature_reserve"]`},
	{ID: "community", Label: "Community", Description: "Libraries, community centres and cultural support.", OSMFilter: `["amenity"~"library|community_centre|place_of_worship"]`},
}

var seedGuideCategories = []GuideCategory{
	{ID: "arrival", Label: "Arrival", Description: "What to do in your first days and weeks."},
	{ID: "health", Label: "Health", Description: "GP, OSHC, urgent care and hospital basics."},
	{ID: "transport", Label: "Transport", Description: "Cards, concessions, airport and safe travel."},
	{ID: "housing", Label: "Housing", Description: "Rentals, rooms, bond, inspections and scams."},
	{ID: "work", Label: "Work", Description: "Starter jobs, rights, TFN, super and wage safety."},
	{ID: "money", Label: "Money", Description: "Banking, budgeting, tax, bills and saving."},
	{ID: "study", Label: "Study", Description: "Uni systems, support, USI and academic rules."},
	{ID: "daily-life", Label: "Daily Life", Description: "Groceries, shopping, culture and local habits."},
	{ID: "safety", Label: "Safety", Description: "Emergency, scams, night safety and crisis support."},
	{ID: "resume", Label: "Resume", Description: "Resume, cover letter and job-search preparation."},
}

var seedGuides = []Guide{
	{
		ID: "what-is-a-gp", Category: "health", Title: "What is a GP?",
		Summary:  "A GP is usually your first doctor for non-emergency health problems in Australia.",
		Body:     "A GP means general practitioner. For most non-emergency health issues, book a GP before going to hospital. A GP can assess you, prescribe medicine, order tests, refer you to a specialist and help manage ongoing conditions. For serious or life-threatening symptoms call 000 or go to emergency. For unsure cases call healthdirect on 1800 022 222.",
		Priority: 100, Tags: []string{"doctor", "hospital", "healthdirect", "oshc"}, OfficialURL: "https://www.healthdirect.gov.au/",
	},
	{
		ID: "gp-vs-hospital", Category: "health", Title: "GP vs urgent care vs hospital",
		Summary:  "Use emergency departments for serious conditions; use GP, urgent care, pharmacist or healthdirect for less urgent problems.",
		Body:     "Go to emergency or call 000 for chest pain, severe breathing trouble, major injury, serious bleeding, stroke signs or severe allergic reaction. Use a GP for common illness, prescriptions, referrals and ongoing care. Use urgent care clinics for non-life-threatening issues that cannot wait. Ask a pharmacist for simple medicine advice. If you are unsure, call healthdirect.",
		Priority: 98, Tags: []string{"emergency", "urgent care", "pharmacy", "000"}, OfficialURL: "https://www.healthdirect.gov.au/hospital-emergency-departments",
	},
	{
		ID: "oshc-basics", Category: "health", Title: "OSHC basics",
		Summary:  "Most student visa holders must keep Overseas Student Health Cover for their whole stay.",
		Body:     "OSHC helps international students pay for some medical, hospital, ambulance and medicine costs. Keep your policy active for the full length of your visa. Learn how to claim, which providers are covered and what gap payment means before you need care.",
		Priority: 95, Tags: []string{"oshc", "insurance", "student visa"}, OfficialURL: "https://www.studyaustralia.gov.au/en/plan-your-move/overseas-student-health-cover-oshc",
	},
	{
		ID: "healthdirect", Category: "health", Title: "Call healthdirect when unsure",
		Summary:  "healthdirect gives free health advice and can tell you where to go.",
		Body:     "Call 1800 022 222 if you are sick or injured and unsure what to do. A registered nurse can help you choose between self-care, GP, urgent care or hospital. Save the number in your phone after arrival.",
		Priority: 94, Tags: []string{"healthdirect", "nurse", "after hours"}, OfficialURL: "https://www.healthdirect.gov.au/how-healthdirect-can-help-you",
	},
	{
		ID: "transport-cards", Category: "transport", Title: "Transport cards by state",
		Summary:  "Each state uses its own transport card or payment system.",
		Body:     "NSW uses Opal. Victoria uses myki. Queensland uses go card. ACT uses MyWay. South Australia uses metroCARD. Western Australia uses SmartRider. Check student concession rules before assuming you are eligible. Always tap on and tap off where required.",
		Priority: 90, Tags: []string{"opal", "myki", "go card", "concession", "student"},
	},
	{
		ID: "airport-arrival", Category: "transport", Title: "Airport to accommodation",
		Summary:  "Plan your airport transfer before landing, especially if arriving late.",
		Body:     "Before flying, save your accommodation address offline, check the airport train or bus route, and compare taxi/rideshare cost. If arriving late at night, consider a safer direct ride for the first trip. Keep your phone charged and avoid handing your passport to strangers.",
		Priority: 88, Tags: []string{"airport", "arrival", "taxi", "train", "safety"},
	},
	{
		ID: "late-night-transport", Category: "transport", Title: "Late-night transport safety",
		Summary:  "Check lighting, station exits and last services before choosing a room or shift.",
		Body:     "A cheap room can become unsafe or expensive if you regularly travel late. Check last trains/buses, station walking routes, rideshare costs and whether streets are well lit. Save campus security and emergency contacts.",
		Priority: 86, Tags: []string{"night", "safety", "shift work", "station"},
	},
	{
		ID: "room-scam-check", Category: "housing", Title: "Avoid rental scams",
		Summary:  "Never transfer bond or rent before inspecting and confirming the arrangement.",
		Body:     "Scam signs include pressure to pay fast, landlord overseas, no inspection, fake IDs, prices far below market and requests for gift cards or unusual transfers. Inspect in person or live video, get written terms and receipts, and use the proper state bond process.",
		Priority: 100, Tags: []string{"rent", "scam", "bond", "inspection"},
	},
	{
		ID: "bond-and-lease", Category: "housing", Title: "Bond and lease basics",
		Summary:  "Bond is a security deposit and should be handled through the proper state process.",
		Body:     "Ask whether you are on a lease, sublease or boarding arrangement. Get the amount, inclusions, notice period and house rules in writing. Bond should usually be lodged with the relevant state authority. Keep receipts and photos from move-in day.",
		Priority: 96, Tags: []string{"bond", "lease", "tenant rights"},
	},
	{
		ID: "inspection-checklist", Category: "housing", Title: "Room inspection checklist",
		Summary:  "Check safety, bills, house rules and transport before applying.",
		Body:     "Check locks, windows, mould, heating/cooling, kitchen space, laundry, internet, noise, rubbish, guest rules, cleaning roster, bill splitting, public transport and walking route after dark. Ask who else lives there.",
		Priority: 94, Tags: []string{"inspection", "sharehouse", "bills"},
	},
	{
		ID: "starter-jobs", Category: "work", Title: "Easiest starter jobs",
		Summary:  "Hospitality, retail, cleaning, warehouse and campus jobs are common first roles.",
		Body:     "New students often start with café, restaurant, retail, supermarket, warehouse, cleaning, tutoring, admin, call centre, event and campus jobs. Prioritize safe employers, legal pay, reasonable commute and rosters that do not damage study.",
		Priority: 96, Tags: []string{"jobs", "retail", "hospitality", "warehouse"},
	},
	{
		ID: "work-rights", Category: "work", Title: "International student work rights",
		Summary:  "Know your allowed hours, minimum pay and payslip rights.",
		Body:     "Student visa holders generally have work-hour limits during study periods and more flexibility during breaks. You must receive at least legal minimum entitlements, and cash work is not an excuse for underpayment. Keep records of hours, payslips and messages.",
		Priority: 95, Tags: []string{"visa", "fair work", "minimum wage", "payslip"}, OfficialURL: "https://www.fairwork.gov.au/tools-and-resources/fact-sheets/rights-and-obligations/international-students",
	},
	{
		ID: "tfn-super", Category: "work", Title: "TFN and super",
		Summary:  "A Tax File Number and superannuation account matter once you work.",
		Body:     "Apply for a TFN through official channels after arrival. Employers need it for tax. Super is retirement savings paid by employers into a super fund if you are eligible. Do not pay someone to create a TFN for you.",
		Priority: 90, Tags: []string{"tfn", "tax", "super"},
	},
	{
		ID: "resume-builder", Category: "resume", Title: "Australian resume basics",
		Summary:  "Keep it clear, short and targeted to the job.",
		Body:     "For starter jobs, use a one-page resume with name, phone, email, suburb, availability, skills, education, work experience and references if available. Do not include passport number, date of birth, marital status or full address. Match keywords from the job ad.",
		Priority: 88, Tags: []string{"resume", "cv", "jobs"},
	},
	{
		ID: "bank-account", Category: "money", Title: "Open a bank account",
		Summary:  "Open an Australian bank account early so you can receive wages and pay rent.",
		Body:     "Major banks include Commonwealth Bank, ANZ, NAB, Westpac and others. Compare account fees, card access, branch location and student options. Keep your card secure and never share one-time passcodes.",
		Priority: 86, Tags: []string{"bank", "money", "wages", "rent"},
	},
	{
		ID: "weekly-budget", Category: "money", Title: "Weekly budget basics",
		Summary:  "Plan rent, transport, groceries, phone, health and emergency savings.",
		Body:     "Your weekly budget should include rent, bond savings, bills, transport, groceries, phone, health, course costs and a small emergency buffer. Track spending for the first month because Australia can feel more expensive than expected.",
		Priority: 86, Tags: []string{"budget", "rent", "groceries"},
	},
	{
		ID: "cheap-groceries", Category: "daily-life", Title: "Where to buy groceries",
		Summary:  "Use a mix of supermarkets, local markets and cultural grocery stores.",
		Body:     "Common supermarkets include Woolworths, Coles, Aldi and IGA. Some states have strong local chains like Foodland, Drakes or Spudshed. Asian, Indian and Nepali groceries are often cheaper for rice, spices and familiar food. Compare unit prices, not just package prices.",
		Priority: 92, Tags: []string{"groceries", "aldi", "coles", "woolworths", "iga"},
	},
	{
		ID: "cheap-essentials", Category: "daily-life", Title: "Cheap household essentials",
		Summary:  "Kmart, Big W, Target, IKEA, Reject Shop and Officeworks are useful early stops.",
		Body:     "For bedding, kitchen items, stationery and basics, check Kmart, Big W, Target, IKEA, Reject Shop, Officeworks and Facebook Marketplace. Avoid buying everything new before you know what your room already has.",
		Priority: 84, Tags: []string{"shopping", "kmart", "big w", "ikea"},
	},
	{
		ID: "usi", Category: "study", Title: "USI and study admin",
		Summary:  "A Unique Student Identifier is needed for many study records in Australia.",
		Body:     "Create your USI through the official system when required. Keep copies of enrolment, CoE, student card, timetable, census date and support contact details. Ask student services early if you are confused.",
		Priority: 82, Tags: []string{"usi", "student", "enrolment"},
	},
	{
		ID: "academic-integrity", Category: "study", Title: "Academic integrity",
		Summary:  "Australian institutions take plagiarism, contract cheating and improper AI use seriously.",
		Body:     "Learn referencing rules, group-work expectations and your institution's AI policy. Do not buy assignments. Ask library or academic skills teams for help before deadlines become a crisis.",
		Priority: 82, Tags: []string{"study", "plagiarism", "referencing", "ai"},
	},
	{
		ID: "emergency-numbers", Category: "safety", Title: "Emergency and crisis numbers",
		Summary:  "Save the most important emergency contacts on day one.",
		Body:     "Call 000 for police, fire or ambulance emergencies. Call Lifeline on 13 11 14 for crisis support. Call 1800RESPECT on 1800 737 732 for family and domestic violence support. Call healthdirect on 1800 022 222 for health advice.",
		Priority: 100, Tags: []string{"000", "lifeline", "1800respect", "healthdirect"},
	},
	{
		ID: "online-scams", Category: "safety", Title: "Common scams",
		Summary:  "Be careful with fake rentals, fake jobs, bank impersonation and visa threats.",
		Body:     "Scammers may pretend to be landlords, employers, police, immigration, banks or delivery companies. Do not share codes, passwords or passport scans unless you know exactly why. Government agencies do not demand gift cards or crypto.",
		Priority: 92, Tags: []string{"scam", "bank", "visa", "rental"},
	},
}

var seedChecklists = []Checklist{
	{ID: "day-one", Title: "Day one in Australia", Stage: "arrival", Priority: 100, Items: []string{"Save emergency contacts", "Confirm accommodation address", "Get a SIM or eSIM", "Tell family you arrived", "Plan transport from airport"}},
	{ID: "first-week", Title: "First week setup", Stage: "week1", Priority: 95, Items: []string{"Open bank account", "Apply for TFN if working", "Find nearest GP/pharmacy", "Buy groceries and bedding", "Check campus support services"}},
	{ID: "first-month", Title: "First month stability", Stage: "month1", Priority: 90, Items: []string{"Review budget", "Save rental receipts", "Prepare resume", "Learn transport concessions", "Join one community or campus group"}},
}

var seedPlaces = []Place{
	{ID: "woolworths-townhall", Name: "Woolworths Town Hall", Category: "groceries", State: "NSW", City: "Sydney", Address: "George St, Sydney NSW", Latitude: -33.8731, Longitude: 151.2061, Source: "seed", Tags: []string{"supermarket", "woolworths"}},
	{ID: "coles-world-square", Name: "Coles World Square", Category: "groceries", State: "NSW", City: "Sydney", Address: "World Square, Sydney NSW", Latitude: -33.8771, Longitude: 151.2069, Source: "seed", Tags: []string{"supermarket", "coles"}},
	{ID: "westfield-sydney", Name: "Westfield Sydney", Category: "shopping", State: "NSW", City: "Sydney", Address: "Pitt St Mall, Sydney NSW", Latitude: -33.8705, Longitude: 151.2089, Source: "seed", Tags: []string{"shopping centre", "westfield"}},
	{ID: "chemist-warehouse-townhall", Name: "Chemist Warehouse Town Hall", Category: "health", State: "NSW", City: "Sydney", Address: "Sydney CBD NSW", Latitude: -33.8735, Longitude: 151.2064, Source: "seed", Tags: []string{"pharmacy", "chemist"}},
	{ID: "state-library-nsw", Name: "State Library of NSW", Category: "community", State: "NSW", City: "Sydney", Address: "Macquarie St, Sydney NSW", Latitude: -33.8664, Longitude: 151.2123, Source: "seed", Tags: []string{"library", "study"}},
	{ID: "queen-victoria-market", Name: "Queen Victoria Market", Category: "groceries", State: "VIC", City: "Melbourne", Address: "Queen St, Melbourne VIC", Latitude: -37.8076, Longitude: 144.9568, Source: "seed", Tags: []string{"market", "groceries"}},
	{ID: "chadstone", Name: "Chadstone Shopping Centre", Category: "shopping", State: "VIC", City: "Melbourne", Address: "Chadstone VIC", Latitude: -37.8864, Longitude: 145.0829, Source: "seed", Tags: []string{"shopping centre"}},
	{ID: "south-bank-brisbane", Name: "South Bank Parklands", Category: "fun", State: "QLD", City: "Brisbane", Address: "South Brisbane QLD", Latitude: -27.4787, Longitude: 153.0222, Source: "seed", Tags: []string{"park", "free"}},
	{ID: "canberra-centre", Name: "Canberra Centre", Category: "shopping", State: "ACT", City: "Canberra", Address: "Canberra ACT", Latitude: -35.2798, Longitude: 149.1337, Source: "seed", Tags: []string{"shopping centre"}},
	{ID: "rundle-mall", Name: "Rundle Mall", Category: "shopping", State: "SA", City: "Adelaide", Address: "Adelaide SA", Latitude: -34.9227, Longitude: 138.6026, Source: "seed", Tags: []string{"shopping"}},
	{ID: "kings-park", Name: "Kings Park and Botanic Garden", Category: "fun", State: "WA", City: "Perth", Address: "Perth WA", Latitude: -31.9616, Longitude: 115.8327, Source: "seed", Tags: []string{"park", "free"}},
	{ID: "salomanca-market", Name: "Salamanca Market", Category: "fun", State: "TAS", City: "Hobart", Address: "Salamanca Pl, Hobart TAS", Latitude: -42.8864, Longitude: 147.3318, Source: "seed", Tags: []string{"market", "weekend"}},
	{ID: "casuarina-square", Name: "Casuarina Square", Category: "shopping", State: "NT", City: "Darwin", Address: "Casuarina NT", Latitude: -12.3749, Longitude: 130.8817, Source: "seed", Tags: []string{"shopping centre"}},
}
