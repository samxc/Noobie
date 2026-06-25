import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const NoobieApp());
}

const noobieApiBaseUrl = String.fromEnvironment(
  'NOOBIE_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8091/api/noobie',
);

class NoobieApp extends StatelessWidget {
  const NoobieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noobie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.inkBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.paper,
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      home: const NoobieHome(),
    );
  }
}

class NoobieHome extends StatefulWidget {
  const NoobieHome({super.key});

  @override
  State<NoobieHome> createState() => _NoobieHomeState();
}

class _NoobieHomeState extends State<NoobieHome> {
  final Set<String> saved = <String>{};
  final NoobieApi api = NoobieApi(baseUrl: noobieApiBaseUrl);
  var selectedIndex = 0;
  var city = 'Sydney';
  var maxRent = 420.0;
  var listings = sampleListings;
  var isImporting = false;
  String? importMessage;

  Future<void> importRooms() async {
    setState(() {
      isImporting = true;
      importMessage = null;
    });

    try {
      final imported = await api.searchRentals(
        suburb: city,
        maxWeeklyRent: maxRent.round(),
      );

      setState(() {
        listings = imported.isEmpty ? sampleListings : imported;
        importMessage = imported.isEmpty
            ? 'Connected, but no listings matched. Showing curated examples.'
            : 'Loaded ${imported.length} rentals from the backend.';
      });
    } catch (error) {
      setState(() {
        listings = sampleListings;
        importMessage =
            'Backend is offline or still starting. Showing realistic sample listings for now.';
      });
    } finally {
      setState(() => isImporting = false);
    }
  }

  void toggleSaved(String id) {
    setState(() {
      if (!saved.add(id)) {
        saved.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      OverviewPage(
        saved: saved,
        onToggleSaved: toggleSaved,
        listings: listings,
        importMessage: importMessage,
        city: city,
        maxRent: maxRent,
        isImporting: isImporting,
        onCityChanged: (value) => setState(() => city = value),
        onRentChanged: (value) => setState(() => maxRent = value),
        onImportRooms: importRooms,
      ),
      RoomsPage(
        saved: saved,
        onToggleSaved: toggleSaved,
        listings: listings,
        importMessage: importMessage,
        city: city,
        maxRent: maxRent,
        isImporting: isImporting,
        onCityChanged: (value) => setState(() => city = value),
        onRentChanged: (value) => setState(() => maxRent = value),
        onImportRooms: importRooms,
      ),
      PlacesPage(api: api, saved: saved, onToggleSaved: toggleSaved),
      GuidePage(api: api, saved: saved, onToggleSaved: toggleSaved),
      AssistantPage(api: api),
      SavedPage(saved: saved, onToggleSaved: toggleSaved, listings: listings),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final navItems = [
          const Destination(Icons.space_dashboard_outlined, 'Home'),
          const Destination(Icons.apartment_outlined, 'Rooms'),
          const Destination(Icons.map_outlined, 'Places'),
          const Destination(Icons.local_library_outlined, 'Guide'),
          const Destination(Icons.auto_awesome_outlined, 'Ask'),
          const Destination(Icons.bookmark_border, 'Saved'),
        ];

        return Scaffold(
          body: Row(
            children: [
              if (wide)
                SideNav(
                  selectedIndex: selectedIndex,
                  destinations: navItems,
                  onSelected: (value) => setState(() => selectedIndex = value),
                ),
              Expanded(child: pages[selectedIndex]),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() => selectedIndex = value);
                  },
                  destinations: [
                    for (final item in navItems)
                      NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<Destination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.coal,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.clay,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Noobie',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            for (var i = 0; i < destinations.length; i++)
              NavButton(
                icon: destinations[i].icon,
                label: destinations[i].label,
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
            const Spacer(),
            const Text(
              'Built for students arriving without a safety net.',
              style: TextStyle(color: AppColors.mist, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: selected ? Colors.white : AppColors.mist),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.mist,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.saved,
    required this.onToggleSaved,
    required this.listings,
    required this.importMessage,
    required this.city,
    required this.maxRent,
    required this.isImporting,
    required this.onCityChanged,
    required this.onRentChanged,
    required this.onImportRooms,
  });

  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;
  final List<RoomListing> listings;
  final String? importMessage;
  final String city;
  final double maxRent;
  final bool isImporting;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<double> onRentChanged;
  final VoidCallback onImportRooms;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const HeroPanel(),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final children = [
              Expanded(
                flex: wide ? 7 : 0,
                child: RoomImportPanel(
                  city: city,
                  maxRent: maxRent,
                  importMessage: importMessage,
                  isImporting: isImporting,
                  onCityChanged: onCityChanged,
                  onRentChanged: onRentChanged,
                  onImportRooms: onImportRooms,
                ),
              ),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              Expanded(
                flex: wide ? 5 : 0,
                child: const SettlementScore(),
              ),
            ];

            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children)
                : Column(
                    children: children.map((child) {
                    if (child is Expanded) {
                      return child.child;
                    }
                    return child;
                  }).toList());
          },
        ),
        SectionTitle(
          title: 'Rooms worth inspecting',
          action: Text('${listings.length} matches'),
        ),
        ListingStrip(
          listings: listings.take(3).toList(),
          saved: saved,
          onToggleSaved: onToggleSaved,
        ),
        const SectionTitle(title: 'Arrival playbook'),
        ActionGrid(
          items: guideItems.take(4).toList(),
          saved: saved,
          onToggleSaved: onToggleSaved,
        ),
      ],
    );
  }
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({
    super.key,
    required this.saved,
    required this.onToggleSaved,
    required this.listings,
    required this.importMessage,
    required this.city,
    required this.maxRent,
    required this.isImporting,
    required this.onCityChanged,
    required this.onRentChanged,
    required this.onImportRooms,
  });

  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;
  final List<RoomListing> listings;
  final String? importMessage;
  final String city;
  final double maxRent;
  final bool isImporting;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<double> onRentChanged;
  final VoidCallback onImportRooms;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        PageHeading(
          title: 'Room Search',
          subtitle:
              'Import rentals, compare the practical details and save inspections before paying a dollar.',
        ),
        RoomImportPanel(
          city: city,
          maxRent: maxRent,
          importMessage: importMessage,
          isImporting: isImporting,
          onCityChanged: onCityChanged,
          onRentChanged: onRentChanged,
          onImportRooms: onImportRooms,
        ),
        SectionTitle(title: 'Imported and curated rooms'),
        ListingGrid(
            listings: listings, saved: saved, onToggleSaved: onToggleSaved),
      ],
    );
  }
}

class PlacesPage extends StatefulWidget {
  const PlacesPage({
    super.key,
    required this.api,
    required this.saved,
    required this.onToggleSaved,
  });

  final NoobieApi api;
  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  var selectedState = 'NSW';
  var selectedCity = 'Sydney';
  var selectedCategory = 'groceries';
  var query = '';
  var places = <AppPlace>[];
  var loading = true;
  String? message;

  @override
  void initState() {
    super.initState();
    loadPlaces();
  }

  Future<void> loadPlaces() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final results = await widget.api.searchPlaces(
        state: selectedState,
        city: selectedCity,
        category: selectedCategory,
        query: query,
      );
      setState(() {
        places = results;
        message = results.isEmpty
            ? 'No places matched yet. Try another category or city.'
            : null;
      });
    } catch (_) {
      setState(() {
        places = samplePlaces
            .where((place) =>
                place.state == selectedState &&
                place.city == selectedCity &&
                place.category == selectedCategory)
            .toList();
        message = 'Backend is offline. Showing built-in starter places.';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const PageHeading(
          title: 'Places',
          subtitle:
              'Find groceries, shopping, health, transport, community support and weekend spots with map links ready for your phone.',
        ),
        PlacesFilterPanel(
          selectedState: selectedState,
          selectedCity: selectedCity,
          selectedCategory: selectedCategory,
          query: query,
          loading: loading,
          onStateChanged: (value) => setState(() {
            selectedState = value;
            selectedCity = cityOptionsForState(value).first;
          }),
          onCityChanged: (value) => setState(() => selectedCity = value),
          onCategoryChanged: (value) =>
              setState(() => selectedCategory = value),
          onQueryChanged: (value) => query = value,
          onSearch: loadPlaces,
        ),
        if (message != null) StatusNote(text: message!),
        const SectionTitle(title: 'Nearby essentials'),
        PlacesGrid(
          places: places,
          saved: widget.saved,
          onToggleSaved: widget.onToggleSaved,
        ),
      ],
    );
  }
}

class GuidePage extends StatefulWidget {
  const GuidePage({
    super.key,
    required this.api,
    required this.saved,
    required this.onToggleSaved,
  });

  final NoobieApi api;
  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  var guides = guideItems;
  var query = '';
  var loading = true;
  String? message;

  @override
  void initState() {
    super.initState();
    loadGuides();
  }

  Future<void> loadGuides() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final results = await widget.api.searchGuides(query: query);
      setState(() {
        guides = results.map((guide) => guide.toGuideItem()).toList();
      });
    } catch (_) {
      setState(() {
        guides = guideItems;
        message = 'Backend is offline. Showing the starter guide set.';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const PageHeading(
          title: 'Settle In',
          subtitle:
              'Compact, practical guidance for housing, money, study support and everyday Australian culture.',
        ),
        Panel(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search guides',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => query = value,
                  onSubmitted: (_) => loadGuides(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: loading ? null : loadGuides,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
        ),
        if (message != null) StatusNote(text: message!),
        ActionGrid(
            items: guides,
            saved: widget.saved,
            onToggleSaved: widget.onToggleSaved),
      ],
    );
  }
}

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key, required this.api});

  final NoobieApi api;

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final controller = TextEditingController(
      text: 'What is a GP and when should I go to hospital?');
  var selectedState = 'NSW';
  AssistantReply? reply;
  var loading = false;
  String? message;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> ask() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final result = await widget.api
          .askAssistant(question: controller.text, state: selectedState);
      setState(() => reply = result);
    } catch (_) {
      setState(() {
        reply = AssistantReply(
          answer:
              'I can answer from Noobie guides once the backend is running. For emergencies call 000; for health uncertainty call healthdirect on 1800 022 222.',
          guides: const [],
          places: const [],
        );
        message = 'Backend is offline. Start it locally to use guide search.';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const PageHeading(
          title: 'Ask Noobie',
          subtitle:
              'A guide-first assistant for practical arrival questions. It answers from Noobie content first and keeps risky medical or legal topics cautious.',
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedState,
                decoration: const InputDecoration(
                    labelText: 'State', border: OutlineInputBorder()),
                items: stateOptions
                    .map((state) =>
                        DropdownMenuItem(value: state, child: Text(state)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedState = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText:
                      'Ask about GP, transport, rooms, scams, jobs, TFN, budget...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: loading ? null : ask,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(loading ? 'Thinking' : 'Ask'),
              ),
            ],
          ),
        ),
        if (message != null) StatusNote(text: message!),
        if (reply != null) ...[
          const SectionTitle(title: 'Answer'),
          Panel(
            child: Text(reply!.answer,
                style: const TextStyle(height: 1.45, fontSize: 16)),
          ),
          if (reply!.guides.isNotEmpty) ...[
            const SectionTitle(title: 'Source guides'),
            ActionGrid(
              items: reply!.guides.map((guide) => guide.toGuideItem()).toList(),
              saved: const {},
              onToggleSaved: (_) {},
            ),
          ],
          if (reply!.places.isNotEmpty) ...[
            const SectionTitle(title: 'Related places'),
            PlacesGrid(
              places: reply!.places,
              saved: const {},
              onToggleSaved: (_) {},
            ),
          ],
        ],
      ],
    );
  }
}

class SavedPage extends StatelessWidget {
  const SavedPage({
    super.key,
    required this.saved,
    required this.onToggleSaved,
    required this.listings,
  });

  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;
  final List<RoomListing> listings;

  @override
  Widget build(BuildContext context) {
    final savedListings =
        listings.where((listing) => saved.contains(listing.id)).toList();
    final savedGuides =
        guideItems.where((item) => saved.contains(item.id)).toList();

    return AppPage(
      children: [
        PageHeading(
          title: 'Saved',
          subtitle: saved.isEmpty
              ? 'Start saving rooms and checklists to build a plan.'
              : '${saved.length} saved items for your move.',
        ),
        if (saved.isEmpty) const EmptyState(),
        if (savedListings.isNotEmpty)
          ListingGrid(
            listings: savedListings,
            saved: saved,
            onToggleSaved: onToggleSaved,
          ),
        if (savedGuides.isNotEmpty)
          ActionGrid(
              items: savedGuides, saved: saved, onToggleSaved: onToggleSaved),
      ],
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1800&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.coal),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.coal.withValues(alpha: 0.92),
                    AppColors.coal.withValues(alpha: 0.58),
                    AppColors.coal.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Pill(label: 'Australia arrival companion'),
                  const SizedBox(height: 24),
                  Text(
                    'Land safer, rent smarter, settle faster.',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Noobie turns the messy first months in Australia into a practical plan: live rental imports, suburb sense-checks, inspection notes and student-life guidance.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.mist,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 26),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      MetricChip(value: 'Domain', label: 'rental import ready'),
                      MetricChip(value: '000', label: 'emergency basics'),
                      MetricChip(value: '7 days', label: 'arrival checklist'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomImportPanel extends StatelessWidget {
  const RoomImportPanel({
    super.key,
    required this.city,
    required this.maxRent,
    required this.importMessage,
    required this.isImporting,
    required this.onCityChanged,
    required this.onRentChanged,
    required this.onImportRooms,
  });

  final String city;
  final double maxRent;
  final String? importMessage;
  final bool isImporting;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<double> onRentChanged;
  final VoidCallback onImportRooms;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt, color: AppColors.inkBlue),
              const SizedBox(width: 10),
              Text(
                'Rental Import',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Connect Domain API credentials to pull live rentals. Without a token, Noobie shows realistic sample listings so the product can still be reviewed.',
            style: TextStyle(color: AppColors.slate, height: 1.35),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  initialValue: city,
                  decoration: const InputDecoration(
                    labelText: 'Search area',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Sydney', child: Text('Sydney')),
                    DropdownMenuItem(
                        value: 'Melbourne', child: Text('Melbourne')),
                    DropdownMenuItem(
                        value: 'Brisbane', child: Text('Brisbane')),
                    DropdownMenuItem(
                        value: 'Adelaide', child: Text('Adelaide')),
                    DropdownMenuItem(value: 'Perth', child: Text('Perth')),
                  ],
                  onChanged: (value) {
                    if (value != null) onCityChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max weekly rent: \$${maxRent.round()}'),
                    Slider(
                      value: maxRent,
                      min: 250,
                      max: 800,
                      divisions: 22,
                      activeColor: AppColors.clay,
                      onChanged: onRentChanged,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: isImporting ? null : onImportRooms,
                icon: isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: Text(isImporting ? 'Importing' : 'Import rooms'),
              ),
            ],
          ),
          if (importMessage != null) ...[
            const SizedBox(height: 14),
            StatusNote(text: importMessage!),
          ],
        ],
      ),
    );
  }
}

class SettlementScore extends StatelessWidget {
  const SettlementScore({super.key});

  @override
  Widget build(BuildContext context) {
    const readiness = 0.62;

    return Panel(
      dark: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;
          final summary = Column(
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                'Move-readiness',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A quick sense-check for the first few weeks: room, money and support.',
                textAlign: TextAlign.start,
                style: TextStyle(color: AppColors.mist, height: 1.35),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ReadinessPill(label: 'Room checked', value: '72%'),
                  ReadinessPill(label: 'Budget clear', value: '58%'),
                  ReadinessPill(label: 'Support found', value: '44%'),
                ],
              ),
              const SizedBox(height: 18),
              const ReadinessAction(
                icon: Icons.home_work_outlined,
                text: 'Confirm bond, bills and lease type before paying.',
              ),
              const ReadinessAction(
                icon: Icons.account_balance_wallet_outlined,
                text: 'Keep two weeks of rent plus transport money aside.',
              ),
              const ReadinessAction(
                icon: Icons.groups_2_outlined,
                text: 'Save one campus, community or emergency contact.',
              ),
            ],
          );

          final gauge = const SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: CircularProgressIndicator(
                    value: readiness,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    color: AppColors.gold,
                    backgroundColor: Color(0x33454f4d),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '62%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'getting there',
                      style: TextStyle(
                        color: AppColors.mist,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                gauge,
                const SizedBox(height: 18),
                summary,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              gauge,
              const SizedBox(width: 22),
              Expanded(child: summary),
            ],
          );
        },
      ),
    );
  }
}

class ReadinessPill extends StatelessWidget {
  const ReadinessPill({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ReadinessAction extends StatelessWidget {
  const ReadinessAction({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.mist, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class PlacesFilterPanel extends StatelessWidget {
  const PlacesFilterPanel({
    super.key,
    required this.selectedState,
    required this.selectedCity,
    required this.selectedCategory,
    required this.query,
    required this.loading,
    required this.onStateChanged,
    required this.onCityChanged,
    required this.onCategoryChanged,
    required this.onQueryChanged,
    required this.onSearch,
  });

  final String selectedState;
  final String selectedCity;
  final String selectedCategory;
  final String query;
  final bool loading;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue: selectedState,
              decoration: const InputDecoration(
                  labelText: 'State', border: OutlineInputBorder()),
              items: stateOptions
                  .map((state) =>
                      DropdownMenuItem(value: state, child: Text(state)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onStateChanged(value);
              },
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: selectedCity,
              decoration: const InputDecoration(
                  labelText: 'City', border: OutlineInputBorder()),
              items: cityOptionsForState(selectedState)
                  .map((city) =>
                      DropdownMenuItem(value: city, child: Text(city)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onCityChanged(value);
              },
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: placeCategoryOptions.entries
                  .map((entry) => DropdownMenuItem(
                      value: entry.key, child: Text(entry.value)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onCategoryChanged(value);
              },
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search name or suburb',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: onQueryChanged,
              onSubmitted: (_) => onSearch(),
            ),
          ),
          FilledButton.icon(
            onPressed: loading ? null : onSearch,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.travel_explore),
            label: Text(loading ? 'Searching' : 'Find places'),
          ),
        ],
      ),
    );
  }
}

class PlacesGrid extends StatelessWidget {
  const PlacesGrid({
    super.key,
    required this.places,
    required this.saved,
    required this.onToggleSaved,
  });

  final List<AppPlace> places;
  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Panel(
        child: Text('No places to show yet.',
            style: TextStyle(color: AppColors.slate)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: places.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 282,
          ),
          itemBuilder: (context, index) {
            final place = places[index];
            return PlaceCard(
              place: place,
              saved: saved.contains(place.id),
              onToggleSaved: onToggleSaved,
            );
          },
        );
      },
    );
  }
}

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.saved,
    required this.onToggleSaved,
  });

  final AppPlace place;
  final bool saved;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(categoryIcon(place.category), color: AppColors.inkBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  place.categoryLabel.isEmpty
                      ? place.category
                      : place.categoryLabel,
                  style: const TextStyle(
                      color: AppColors.slate, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: saved ? 'Remove saved place' : 'Save place',
                onPressed: () => onToggleSaved(place.id),
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            place.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.slate, height: 1.35),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => openExternal(place.mapLinks.google),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Google'),
              ),
              OutlinedButton.icon(
                onPressed: () => openExternal(place.mapLinks.apple),
                icon: const Icon(Icons.near_me_outlined),
                label: const Text('Apple'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ListingStrip extends StatelessWidget {
  const ListingStrip({
    super.key,
    required this.listings,
    required this.saved,
    required this.onToggleSaved,
  });

  final List<RoomListing> listings;
  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final cards = listings
            .map(
              (listing) => Expanded(
                child: RoomCard(
                  listing: listing,
                  saved: saved.contains(listing.id),
                  onToggleSaved: onToggleSaved,
                ),
              ),
            )
            .toList();

        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: interleave(cards, 12))
            : Column(
                children: listings
                    .map(
                      (listing) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RoomCard(
                          listing: listing,
                          saved: saved.contains(listing.id),
                          onToggleSaved: onToggleSaved,
                        ),
                      ),
                    )
                    .toList(),
              );
      },
    );
  }
}

class ListingGrid extends StatelessWidget {
  const ListingGrid({
    super.key,
    required this.listings,
    required this.saved,
    required this.onToggleSaved,
  });

  final List<RoomListing> listings;
  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listings.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 438,
          ),
          itemBuilder: (context, index) {
            final listing = listings[index];
            return RoomCard(
              listing: listing,
              saved: saved.contains(listing.id),
              onToggleSaved: onToggleSaved,
            );
          },
        );
      },
    );
  }
}

class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.listing,
    required this.saved,
    required this.onToggleSaved,
  });

  final RoomListing listing;
  final bool saved;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  listing.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.mist),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Pill(label: listing.source, compact: true),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    tooltip: saved ? 'Remove saved room' : 'Save room',
                    onPressed: () => onToggleSaved(listing.id),
                    icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  listing.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.slate, height: 1.3),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    RoomFeature(
                        icon: Icons.bed_outlined, label: '${listing.beds} bed'),
                    RoomFeature(
                        icon: Icons.bathtub_outlined,
                        label: '${listing.baths} bath'),
                    RoomFeature(
                        icon: Icons.train_outlined, label: listing.commute),
                  ],
                ),
                const SizedBox(height: 14),
                SafetyBand(label: listing.safetyNote),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionGrid extends StatelessWidget {
  const ActionGrid({
    super.key,
    required this.items,
    required this.saved,
    required this.onToggleSaved,
  });

  final List<GuideItem> items;
  final Set<String> saved;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 680
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 300,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return GuideCard(
              item: item,
              saved: saved.contains(item.id),
              onToggleSaved: onToggleSaved,
            );
          },
        );
      },
    );
  }
}

class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.item,
    required this.saved,
    required this.onToggleSaved,
  });

  final GuideItem item;
  final bool saved;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showGuideDetail(context, item),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, color: AppColors.clay),
                const Spacer(),
                IconButton(
                  tooltip: saved ? 'Remove saved guide' : 'Save guide',
                  onPressed: () => onToggleSaved(item.id),
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: const TextStyle(color: AppColors.slate, height: 1.35),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      color: AppColors.inkBlue,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const Icon(Icons.open_in_full,
                    color: AppColors.slate, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showGuideDetail(BuildContext context, GuideItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (_) => GuideDetailSheet(item: item),
  );
}

class GuideDetailSheet extends StatefulWidget {
  const GuideDetailSheet({super.key, required this.item});

  final GuideItem item;

  @override
  State<GuideDetailSheet> createState() => _GuideDetailSheetState();
}

class _GuideDetailSheetState extends State<GuideDetailSheet> {
  final FlutterTts tts = FlutterTts();
  var speaking = false;

  GuideDetailContent get detail => guideDetailFor(widget.item);

  @override
  void initState() {
    super.initState();
    tts.setCompletionHandler(() {
      if (mounted) setState(() => speaking = false);
    });
    tts.setCancelHandler(() {
      if (mounted) setState(() => speaking = false);
    });
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> toggleSpeech() async {
    if (speaking) {
      await tts.stop();
      setState(() => speaking = false);
      return;
    }
    await tts.setLanguage('en-AU');
    await tts.setSpeechRate(0.45);
    await tts.speak(detail.speechText(widget.item));
    setState(() => speaking = true);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.97,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            Row(
              children: [
                Icon(item.icon, color: AppColors.clay),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      color: AppColors.inkBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close guide',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.coal,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              style: const TextStyle(
                  color: AppColors.slate, height: 1.45, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: toggleSpeech,
                  icon: Icon(speaking ? Icons.stop : Icons.volume_up_outlined),
                  label: Text(speaking ? 'Stop listening' : 'Listen'),
                ),
                if (item.officialUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openExternal(item.officialUrl),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Official source'),
                  ),
              ],
            ),
            if (item.body.isNotEmpty) ...[
              const SectionTitle(title: 'What this means'),
              DetailBlock(text: item.body),
            ],
            if (detail.images.isNotEmpty) ...[
              const SectionTitle(title: 'What it looks like'),
              DetailImageStrip(images: detail.images),
            ],
            for (final section in detail.sections) ...[
              SectionTitle(title: section.title),
              DetailBlock(text: section.body),
            ],
            if (detail.warnings.isNotEmpty) ...[
              const SectionTitle(title: 'Common mistakes'),
              for (final warning in detail.warnings)
                DetailBullet(icon: Icons.warning_amber_outlined, text: warning),
            ],
            if (detail.checklist.isNotEmpty) ...[
              const SectionTitle(title: 'Do this'),
              for (final step in detail.checklist)
                DetailBullet(icon: Icons.check_circle_outline, text: step),
            ],
            if (detail.links.isNotEmpty) ...[
              const SectionTitle(title: 'Useful links'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final link in detail.links)
                    OutlinedButton.icon(
                      onPressed: () => openExternal(link.url),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(link.label),
                    ),
                ],
              ),
            ],
            if (detail.attribution.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                detail.attribution,
                style: const TextStyle(
                    color: AppColors.slate, fontSize: 12, height: 1.35),
              ),
            ],
          ],
        );
      },
    );
  }
}

class DetailBlock extends StatelessWidget {
  const DetailBlock({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Text(
        text,
        style:
            const TextStyle(color: AppColors.coal, height: 1.5, fontSize: 15),
      ),
    );
  }
}

class DetailImageStrip extends StatelessWidget {
  const DetailImageStrip({super.key, required this.images});

  final List<GuideImage> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final image = images[index];
          return SizedBox(
            width: 330,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    image.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.mist),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: AppColors.coal.withValues(alpha: 0.74),
                      child: Text(
                        image.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DetailBullet extends StatelessWidget {
  const DetailBullet({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.clay, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.4, color: AppColors.coal),
            ),
          ),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: dark ? AppColors.coal : Colors.white,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.coal,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.slate,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.coal,
                ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class MetricChip extends StatelessWidget {
  const MetricChip({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.mist)),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.clay,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 12 : 13,
        ),
      ),
    );
  }
}

class StatusNote extends StatelessWidget {
  const StatusNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inkBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.inkBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text, style: const TextStyle(color: AppColors.coal))),
        ],
      ),
    );
  }
}

class RoomFeature extends StatelessWidget {
  const RoomFeature({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.inkBlue),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class SafetyBand extends StatelessWidget {
  const SafetyBand({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 18, color: AppColors.coal),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          Icon(Icons.bookmark_add_outlined, color: AppColors.clay, size: 42),
          const SizedBox(height: 12),
          Text(
            'Save rooms and guide cards to create your arrival plan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class NoobieApi {
  NoobieApi({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  final String baseUrl;
  final http.Client client;

  Future<List<RoomListing>> searchRentals({
    required String suburb,
    required int maxWeeklyRent,
  }) async {
    final response = await client.post(
      _uri('/rentals/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'suburb': suburb,
        'max_weekly_rent': maxWeeklyRent,
      }),
    );
    final items = _items(response);
    return items.map(RoomListing.fromJson).whereType<RoomListing>().toList();
  }

  Future<List<AppPlace>> searchPlaces({
    required String state,
    required String city,
    required String category,
    required String query,
  }) async {
    final response = await client.get(_uri('/places/search', {
      'state': state,
      'city': city,
      'category': category,
      if (query.trim().isNotEmpty) 'q': query.trim(),
      'limit': '60',
    }));
    final items = _items(response);
    return items.map(AppPlace.fromJson).whereType<AppPlace>().toList();
  }

  Future<List<AppGuide>> searchGuides({required String query}) async {
    final response = await client.get(_uri('/guides/search', {
      if (query.trim().isNotEmpty) 'q': query.trim(),
      'limit': '60',
    }));
    final items = _items(response);
    return items.map(AppGuide.fromJson).whereType<AppGuide>().toList();
  }

  Future<AssistantReply> askAssistant({
    required String question,
    required String state,
  }) async {
    final response = await client.post(
      _uri('/assistant/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'state': state}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Noobie assistant failed with ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Unexpected assistant response.');
    }
    return AssistantReply.fromJson(decoded);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  List<dynamic> _items(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Noobie API failed with ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      return decoded['items'] as List;
    }
    return const [];
  }
}

class RoomListing {
  const RoomListing({
    required this.id,
    required this.price,
    required this.address,
    required this.beds,
    required this.baths,
    required this.commute,
    required this.safetyNote,
    required this.imageUrl,
    required this.source,
  });

  final String id;
  final String price;
  final String address;
  final int beds;
  final int baths;
  final String commute;
  final String safetyNote;
  final String imageUrl;
  final String source;

  static RoomListing? fromJson(dynamic item) {
    if (item is! Map<String, dynamic>) return null;

    return RoomListing(
      id: '${item['id'] ?? item.hashCode}',
      price: '${item['price'] ?? 'Contact agent'}',
      address: '${item['address'] ?? 'Address available on request'}',
      beds: asInt(item['beds']),
      baths: asInt(item['baths']),
      commute: '${item['commute'] ?? 'Check commute'}',
      safetyNote:
          '${item['safety_note'] ?? 'Inspect lighting, locks and transport before applying'}',
      imageUrl: '${item['image_url'] ?? fallbackRoomImage}',
      source: '${item['source'] ?? 'Backend'}',
    );
  }
}

class AppPlace {
  const AppPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.state,
    required this.city,
    required this.address,
    required this.mapLinks,
  });

  final String id;
  final String name;
  final String category;
  final String categoryLabel;
  final String state;
  final String city;
  final String address;
  final PlaceMapLinks mapLinks;

  static AppPlace? fromJson(dynamic item) {
    if (item is! Map<String, dynamic>) return null;
    return AppPlace(
      id: '${item['id'] ?? item.hashCode}',
      name: '${item['name'] ?? 'Unnamed place'}',
      category: '${item['category'] ?? ''}',
      categoryLabel: '${item['category_label'] ?? ''}',
      state: '${item['state'] ?? ''}',
      city: '${item['city'] ?? ''}',
      address: '${item['address'] ?? ''}',
      mapLinks: PlaceMapLinks.fromJson(item['map_links']),
    );
  }
}

class PlaceMapLinks {
  const PlaceMapLinks(
      {required this.google, required this.apple, required this.geo});

  final String google;
  final String apple;
  final String geo;

  static PlaceMapLinks fromJson(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return const PlaceMapLinks(google: '', apple: '', geo: '');
    }
    return PlaceMapLinks(
      google: '${item['google'] ?? ''}',
      apple: '${item['apple'] ?? ''}',
      geo: '${item['geo'] ?? ''}',
    );
  }
}

class AppGuide {
  const AppGuide({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    required this.categoryLabel,
    required this.officialUrl,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final String category;
  final String categoryLabel;
  final String officialUrl;

  GuideItem toGuideItem() {
    return GuideItem(
      id: id,
      title: title,
      description: summary,
      body: body,
      category: categoryLabel.isEmpty
          ? category.toUpperCase()
          : categoryLabel.toUpperCase(),
      rawCategory: category,
      officialUrl: officialUrl,
      icon: categoryIcon(category),
    );
  }

  static AppGuide? fromJson(dynamic item) {
    if (item is! Map<String, dynamic>) return null;
    return AppGuide(
      id: '${item['id'] ?? item.hashCode}',
      title: '${item['title'] ?? 'Guide'}',
      summary: '${item['summary'] ?? ''}',
      body: '${item['body'] ?? ''}',
      category: '${item['category'] ?? ''}',
      categoryLabel: '${item['category_label'] ?? ''}',
      officialUrl: '${item['official_url'] ?? ''}',
    );
  }
}

class AssistantReply {
  const AssistantReply({
    required this.answer,
    required this.guides,
    required this.places,
  });

  final String answer;
  final List<AppGuide> guides;
  final List<AppPlace> places;

  static AssistantReply fromJson(Map<String, dynamic> item) {
    final rawGuides =
        item['guides'] is List ? item['guides'] as List : const [];
    final rawPlaces =
        item['places'] is List ? item['places'] as List : const [];
    return AssistantReply(
      answer: '${item['answer'] ?? ''}',
      guides: rawGuides.map(AppGuide.fromJson).whereType<AppGuide>().toList(),
      places: rawPlaces.map(AppPlace.fromJson).whereType<AppPlace>().toList(),
    );
  }
}

class GuideDetailContent {
  const GuideDetailContent({
    required this.sections,
    this.images = const [],
    this.warnings = const [],
    this.checklist = const [],
    this.links = const [],
    this.attribution = '',
  });

  final List<GuideSection> sections;
  final List<GuideImage> images;
  final List<String> warnings;
  final List<String> checklist;
  final List<GuideLink> links;
  final String attribution;

  String speechText(GuideItem item) {
    return [
      item.title,
      item.description,
      if (item.body.isNotEmpty) item.body,
      for (final section in sections) '${section.title}. ${section.body}',
      if (warnings.isNotEmpty) 'Common mistakes. ${warnings.join(". ")}',
      if (checklist.isNotEmpty) 'Do this. ${checklist.join(". ")}',
    ].join('. ');
  }
}

class GuideSection {
  const GuideSection({required this.title, required this.body});

  final String title;
  final String body;
}

class GuideImage {
  const GuideImage({required this.url, required this.caption});

  final String url;
  final String caption;
}

class GuideLink {
  const GuideLink({required this.label, required this.url});

  final String label;
  final String url;
}

GuideDetailContent guideDetailFor(GuideItem item) {
  final key = item.rawCategory.isNotEmpty
      ? item.rawCategory.toLowerCase()
      : item.category.toLowerCase();
  final title = item.title.toLowerCase();
  if (key.contains('transport') ||
      title.contains('transport') ||
      title.contains('airport')) {
    return transportGuideDetail;
  }
  if (key.contains('health') ||
      title.contains('gp') ||
      title.contains('oshc')) {
    return healthGuideDetail;
  }
  if (key.contains('housing') ||
      title.contains('bond') ||
      title.contains('room') ||
      title.contains('suburb')) {
    return housingGuideDetail;
  }
  if (key.contains('work') || key.contains('resume') || title.contains('job')) {
    return workGuideDetail;
  }
  if (key.contains('money') ||
      title.contains('budget') ||
      title.contains('bank')) {
    return moneyGuideDetail;
  }
  if (key.contains('study') || title.contains('usi')) {
    return studyGuideDetail;
  }
  if (key.contains('safety') ||
      title.contains('scam') ||
      title.contains('emergency')) {
    return safetyGuideDetail;
  }
  return dailyLifeGuideDetail;
}

const transportGuideDetail = GuideDetailContent(
  images: [
    GuideImage(
      url:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Central_Railway_Station_Platforms_16_%26_17_Sydney_P1350337.jpg/960px-Central_Railway_Station_Platforms_16_%26_17_Sydney_P1350337.jpg',
      caption: 'Sydney Trains platforms at Central station.',
    ),
    GuideImage(
      url:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Transport_NSW_liveried_%282589_ST%29%2C_operated_by_Sydney_Buses%2C_Bustech_VST_bodied_Scania_K280UB_on_Loftus_Street_in_Circular_Quay.jpg/960px-Transport_NSW_liveried_%282589_ST%29%2C_operated_by_Sydney_Buses%2C_Bustech_VST_bodied_Scania_K280UB_on_Loftus_Street_in_Circular_Quay.jpg',
      caption: 'A Transport NSW bus near Circular Quay.',
    ),
    GuideImage(
      url:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Sydney_Harbour_Bridge_from_Circular_Quay.jpg/960px-Sydney_Harbour_Bridge_from_Circular_Quay.jpg',
      caption: 'Circular Quay is the main city ferry interchange.',
    ),
  ],
  sections: [
    GuideSection(
      title: 'Cards and payment',
      body:
          'In NSW you can use an Opal card or many contactless American Express, Mastercard and Visa cards/devices. Use the same card, phone or watch to tap on and tap off. Do not tap on with your phone and tap off with the physical card, because the system treats them as different payment methods.',
    ),
    GuideSection(
      title: 'How routes work',
      body:
          'Trains run by line and platform. Buses run by route number and direction, and some stops serve several routes. Ferries run by wharf and destination. Always check the destination board before boarding, because the same platform, bus stop or wharf can serve multiple services. Use the Trip Planner or live departures when you are new.',
    ),
    GuideSection(
      title: 'Ferries and Circular Quay',
      body:
          'Circular Quay is the easiest starting point for Sydney ferries. Look for the wharf number and destination on the screens. Popular beginner ferry trips include Manly, Taronga Zoo, Parramatta River services and short harbour trips. Ferries can be crowded on weekends, events and sunset times, so arrive early and have a train or light rail backup.',
    ),
    GuideSection(
      title: 'Fines and inspectors',
      body:
          'Transport officers can check whether you have a valid tap-on or ticket. If you forgot to tap on, used the wrong card, had a flat phone battery, or tapped with a concession you are not eligible for, you may be fined. If the reader was faulty or this was a genuine first mistake, keep evidence and use the official NSW fine review process.',
    ),
  ],
  warnings: [
    'Card clash: keeping several cards together can tap the wrong one.',
    'Flat phone battery: if your phone dies, you may not be able to prove the same payment method.',
    'Concession confusion: international students are not automatically eligible for every concession.',
    'Open train gates do not mean the trip is free. You still need a valid tap-on.',
  ],
  checklist: [
    'Save Trip Planner, Opal/contactless info and your campus address before your first commute.',
    'Practice one simple trip in daylight before relying on public transport late at night.',
    'Tap on and tap off with the same card/device every time.',
    'At ferry wharves, check both the wharf number and destination screen before boarding.',
  ],
  links: [
    GuideLink(
        label: 'Contactless payments',
        url: 'https://transportnsw.info/tickets-fares/contactless-payments'),
    GuideLink(
        label: 'Ferry routes',
        url: 'https://transportnsw.info/travel-info/ways-to-get-around/ferry'),
    GuideLink(
        label: 'Routes and timetables',
        url: 'https://transportnsw.info/routes/ferry'),
    GuideLink(
        label: 'Fine review guide',
        url:
            'https://www.nsw.gov.au/money-and-taxes/fines-and-fees/fines/request-a-review/review-assist-guide/public-transport-offences'),
  ],
  attribution:
      'Images: Wikimedia Commons transport/Circular Quay files. Official transport guidance links open Transport for NSW and NSW Government pages.',
);

const healthGuideDetail = GuideDetailContent(
  images: [
    GuideImage(
      url:
          'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=1200&q=80',
      caption: 'GP clinics are usually the first step for non-emergency care.',
    ),
  ],
  sections: [
    GuideSection(
      title: 'GP first, emergency for danger',
      body:
          'A GP handles ordinary illness, prescriptions, referrals, test results and ongoing health issues. Emergency departments are for serious or life-threatening symptoms like chest pain, severe breathing trouble, stroke signs, major injury or heavy bleeding.',
    ),
    GuideSection(
      title: 'OSHC and gap payments',
      body:
          'OSHC may cover part of the cost, but some clinics charge a gap. Before booking, ask if they accept your OSHC provider, whether you pay upfront, and how claims work.',
    ),
  ],
  warnings: [
    'Do not wait with severe symptoms because you are worried about cost. Call 000 for emergencies.',
    'Do not assume every clinic bulk bills international students.',
  ],
  checklist: [
    'Save 000 and healthdirect 1800 022 222.',
    'Find a nearby GP and pharmacy before you get sick.',
    'Keep your OSHC card/policy number on your phone.',
  ],
  links: [
    GuideLink(label: 'healthdirect', url: 'https://www.healthdirect.gov.au/'),
    GuideLink(
        label: 'OSHC info',
        url:
            'https://www.studyaustralia.gov.au/en/plan-your-move/overseas-student-health-cover-oshc'),
  ],
);

const housingGuideDetail = GuideDetailContent(
  images: [
    GuideImage(
      url:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
      caption: 'Inspect rooms carefully before paying rent or bond.',
    ),
  ],
  sections: [
    GuideSection(
      title: 'Inspect before paying',
      body:
          'Check locks, windows, mould, heating/cooling, internet, kitchen space, laundry, noise and the walk to transport. If you cannot inspect in person, ask for a live video call and written terms.',
    ),
    GuideSection(
      title: 'Bond, bills and house rules',
      body:
          'Ask whether bond is lodged properly, what bills are included, how much notice is required, whether guests are allowed, and who else lives there. Keep receipts and screenshots.',
    ),
  ],
  warnings: [
    'Scammers often pressure you to pay fast before inspection.',
    'A cheap room can become expensive if transport is unsafe or far away.',
  ],
  checklist: [
    'Inspect or live-video the room.',
    'Get rent, bond, bills and notice period in writing.',
    'Photograph room condition on move-in day.',
  ],
);

const workGuideDetail = GuideDetailContent(
  sections: [
    GuideSection(
      title: 'Starter jobs',
      body:
          'Common first jobs include hospitality, retail, supermarket, warehouse, cleaning, tutoring, campus jobs, call centre and admin. Choose jobs that fit your timetable and commute.',
    ),
    GuideSection(
      title: 'Resume and rights',
      body:
          'Use a short Australian-style resume with availability, suburb, skills and experience. Keep records of hours, payslips and messages. Cash work is not an excuse for unsafe or underpaid work.',
    ),
  ],
  warnings: [
    'Do not hand over passport details casually to unknown employers.',
    'Be careful with unpaid trial shifts that are actually normal work.',
  ],
  checklist: [
    'Prepare a one-page resume.',
    'Apply for a TFN through official channels.',
    'Check minimum pay and keep payslips.',
  ],
  links: [
    GuideLink(
        label: 'Fair Work students',
        url:
            'https://www.fairwork.gov.au/tools-and-resources/fact-sheets/rights-and-obligations/international-students'),
  ],
);

const moneyGuideDetail = GuideDetailContent(
  sections: [
    GuideSection(
      title: 'First-month budget',
      body:
          'Plan rent, bond, bills, groceries, phone, transport, OSHC/medical gaps, course materials and emergency savings. Track spending for the first month because small Australian costs add up fast.',
    ),
    GuideSection(
      title: 'Banking and scams',
      body:
          'Use a reputable bank, keep one-time codes private and never move money for someone else. Government agencies and banks do not demand gift cards or crypto.',
    ),
  ],
  warnings: [
    'Do not share internet banking passwords or one-time codes.',
    'Avoid “easy money” transfer jobs. They can be money mule scams.',
  ],
  checklist: [
    'Open a bank account.',
    'Set a weekly rent/grocery/transport budget.',
    'Keep a small emergency buffer.',
  ],
);

const studyGuideDetail = GuideDetailContent(
  sections: [
    GuideSection(
      title: 'Study admin',
      body:
          'Save your timetable, census date, CoE, student card, learning portal, library login and support contacts. Ask student services early when something is confusing.',
    ),
    GuideSection(
      title: 'Academic integrity',
      body:
          'Learn referencing, group-work rules and AI policy. Buying assignments or copying text can risk your enrolment and visa plans.',
    ),
  ],
  warnings: [
    'Do not leave academic help until the night before a deadline.',
    'Do not assume AI use is allowed just because a tool is available.',
  ],
  checklist: [
    'Create/check your USI if required.',
    'Find library and academic skills support.',
    'Save census and assessment dates.',
  ],
);

const safetyGuideDetail = GuideDetailContent(
  sections: [
    GuideSection(
      title: 'Emergency basics',
      body:
          'Call 000 for police, fire or ambulance emergencies. For crisis support call Lifeline. For domestic or family violence support call 1800RESPECT.',
    ),
    GuideSection(
      title: 'Personal and online safety',
      body:
          'Save trusted contacts, avoid isolated late-night routes when possible, and be suspicious of fake landlords, fake employers, bank impersonators and visa threats.',
    ),
  ],
  warnings: [
    'Government agencies do not demand payment by gift cards or crypto.',
    'Do not share passport scans unless you know exactly who needs them and why.',
  ],
  checklist: [
    'Save 000, campus security and one trusted local contact.',
    'Plan the route home before late shifts or events.',
    'Screenshot suspicious rental or job messages before reporting.',
  ],
);

const dailyLifeGuideDetail = GuideDetailContent(
  sections: [
    GuideSection(
      title: 'Everyday systems',
      body:
          'Australia has many small systems that locals assume everyone knows: GP appointments, Opal/myki/go cards, rental inspections, payslips, super, TFN, unit pricing, bin days and campus support teams.',
    ),
    GuideSection(
      title: 'Shopping and groceries',
      body:
          'Compare supermarkets, local markets and cultural grocery stores. Kmart, Big W, Target, IKEA, Reject Shop and Officeworks are common places for first-room essentials.',
    ),
  ],
  warnings: [
    'Do not buy every household item before seeing what your room already has.',
    'Compare unit price, not just package price.',
  ],
  checklist: [
    'Find your nearest supermarket, pharmacy, library and train/bus stop.',
    'Join one campus or community group.',
    'Keep a notes list of confusing Australian terms as you learn them.',
  ],
);

class GuideItem {
  const GuideItem({
    required this.id,
    required this.title,
    required this.description,
    this.body = '',
    required this.category,
    this.rawCategory = '',
    this.officialUrl = '',
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String body;
  final String category;
  final String rawCategory;
  final String officialUrl;
  final IconData icon;
}

class Destination {
  const Destination(this.icon, this.label);

  final IconData icon;
  final String label;
}

List<Widget> interleave(List<Widget> widgets, double gap) {
  final result = <Widget>[];
  for (var i = 0; i < widgets.length; i++) {
    if (i > 0) result.add(SizedBox(width: gap));
    result.add(widgets[i]);
  }
  return result;
}

int asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Future<void> openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

IconData categoryIcon(String category) {
  return switch (category) {
    'groceries' => Icons.shopping_basket_outlined,
    'shopping' => Icons.storefront_outlined,
    'health' => Icons.local_hospital_outlined,
    'transport' => Icons.train_outlined,
    'fun' => Icons.park_outlined,
    'community' => Icons.groups_outlined,
    'housing' => Icons.apartment_outlined,
    'work' => Icons.work_outline,
    'money' => Icons.savings_outlined,
    'study' => Icons.school_outlined,
    'safety' => Icons.shield_outlined,
    'resume' => Icons.description_outlined,
    _ => Icons.place_outlined,
  };
}

List<String> cityOptionsForState(String state) {
  return citiesByState[state] ?? const ['Sydney'];
}

const stateOptions = ['NSW', 'VIC', 'QLD', 'ACT', 'SA', 'WA', 'TAS', 'NT'];

const citiesByState = {
  'NSW': ['Sydney', 'Parramatta'],
  'VIC': ['Melbourne'],
  'QLD': ['Brisbane'],
  'ACT': ['Canberra'],
  'SA': ['Adelaide'],
  'WA': ['Perth'],
  'TAS': ['Hobart'],
  'NT': ['Darwin'],
};

const placeCategoryOptions = {
  'groceries': 'Groceries',
  'shopping': 'Shopping',
  'health': 'Health',
  'transport': 'Transport',
  'fun': 'Fun & Travel',
  'community': 'Community',
};

const fallbackRoomImage =
    'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80';

const samplePlaces = [
  AppPlace(
    id: 'sample-woolworths-townhall',
    name: 'Woolworths Town Hall',
    category: 'groceries',
    categoryLabel: 'Groceries',
    state: 'NSW',
    city: 'Sydney',
    address: 'George St, Sydney NSW',
    mapLinks: PlaceMapLinks(
      google:
          'https://www.google.com/maps/search/?api=1&query=-33.873100,151.206100',
      apple:
          'https://maps.apple.com/?q=Woolworths+Town+Hall&ll=-33.873100,151.206100',
      geo:
          'geo:-33.873100,151.206100?q=-33.873100,151.206100(Woolworths+Town+Hall)',
    ),
  ),
  AppPlace(
    id: 'sample-westfield-sydney',
    name: 'Westfield Sydney',
    category: 'shopping',
    categoryLabel: 'Shopping',
    state: 'NSW',
    city: 'Sydney',
    address: 'Pitt St Mall, Sydney NSW',
    mapLinks: PlaceMapLinks(
      google:
          'https://www.google.com/maps/search/?api=1&query=-33.870500,151.208900',
      apple:
          'https://maps.apple.com/?q=Westfield+Sydney&ll=-33.870500,151.208900',
      geo:
          'geo:-33.870500,151.208900?q=-33.870500,151.208900(Westfield+Sydney)',
    ),
  ),
  AppPlace(
    id: 'sample-chemist-townhall',
    name: 'Chemist Warehouse Town Hall',
    category: 'health',
    categoryLabel: 'Health',
    state: 'NSW',
    city: 'Sydney',
    address: 'Sydney CBD NSW',
    mapLinks: PlaceMapLinks(
      google:
          'https://www.google.com/maps/search/?api=1&query=-33.873500,151.206400',
      apple:
          'https://maps.apple.com/?q=Chemist+Warehouse+Town+Hall&ll=-33.873500,151.206400',
      geo:
          'geo:-33.873500,151.206400?q=-33.873500,151.206400(Chemist+Warehouse+Town+Hall)',
    ),
  ),
];

const sampleListings = [
  RoomListing(
    id: 'room-glebe',
    price: '\$360/wk',
    address: 'Bright room near university links, Glebe NSW',
    beds: 1,
    baths: 1,
    commute: '18m campus',
    safetyNote: 'Good transport, inspect street lighting',
    imageUrl:
        'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80',
    source: 'Sample',
  ),
  RoomListing(
    id: 'room-brunswick',
    price: '\$330/wk',
    address: 'Sharehouse room close to tram, Brunswick VIC',
    beds: 1,
    baths: 2,
    commute: '12m tram',
    safetyNote: 'Ask about bills and quiet hours',
    imageUrl:
        'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?auto=format&fit=crop&w=1200&q=80',
    source: 'Sample',
  ),
  RoomListing(
    id: 'room-westend',
    price: '\$310/wk',
    address: 'Student-friendly unit room, West End QLD',
    beds: 1,
    baths: 1,
    commute: '22m bus',
    safetyNote: 'Verify bond lodging before payment',
    imageUrl:
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
    source: 'Sample',
  ),
  RoomListing(
    id: 'room-northbridge',
    price: '\$295/wk',
    address: 'Central room with study desk, Northbridge WA',
    beds: 1,
    baths: 1,
    commute: '10m train',
    safetyNote: 'Check noise and late-night route',
    imageUrl:
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
    source: 'Sample',
  ),
  RoomListing(
    id: 'room-adelaide',
    price: '\$285/wk',
    address: 'Quiet room near city campus, Adelaide SA',
    beds: 1,
    baths: 1,
    commute: '15m walk',
    safetyNote: 'Confirm lease terms in writing',
    imageUrl:
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
    source: 'Sample',
  ),
  RoomListing(
    id: 'room-parramatta',
    price: '\$340/wk',
    address: 'Room near station and shops, Parramatta NSW',
    beds: 1,
    baths: 2,
    commute: '7m station',
    safetyNote: 'Inspect locks, mould and kitchen storage',
    imageUrl:
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
    source: 'Sample',
  ),
];

const guideItems = [
  GuideItem(
    id: 'bond',
    title: 'Before paying bond',
    description:
        'Inspect in person or by live video, ask for written terms, and use the state bond authority process.',
    category: 'HOUSING',
    icon: Icons.receipt_long_outlined,
  ),
  GuideItem(
    id: 'suburb',
    title: 'Suburb safety check',
    description:
        'Compare transport, lighting, late-night routes, shops, campus distance and total weekly cost.',
    category: 'SAFETY',
    icon: Icons.shield_outlined,
  ),
  GuideItem(
    id: 'work',
    title: 'Work rights basics',
    description:
        'Know minimum wage, payslips, super, TFN basics and when a cash job is taking advantage of you.',
    category: 'MONEY',
    icon: Icons.work_outline,
  ),
  GuideItem(
    id: 'support',
    title: 'When you feel alone',
    description:
        'Map campus wellbeing, mentors, community groups, libraries, crisis lines and trusted classmates.',
    category: 'SUPPORT',
    icon: Icons.volunteer_activism_outlined,
  ),
  GuideItem(
    id: 'aussie',
    title: 'Everyday Aussie',
    description:
        'Learn greetings, queue etiquette, rental language, public transport habits and service expectations.',
    category: 'CULTURE',
    icon: Icons.forum_outlined,
  ),
  GuideItem(
    id: 'budget',
    title: 'Weekly budget',
    description:
        'Plan rent, groceries, transport, phone, health, course costs and emergency savings before you move.',
    category: 'BUDGET',
    icon: Icons.savings_outlined,
  ),
];

class AppColors {
  static const coal = Color(0xff182022);
  static const inkBlue = Color(0xff315c73);
  static const clay = Color(0xffb85c44);
  static const gold = Color(0xffd6a84f);
  static const paper = Color(0xfff4f0e8);
  static const mist = Color(0xffdbe3df);
  static const slate = Color(0xff65706f);
}
