import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../services/language_provider.dart';
import 'login_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'route_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, inner) {
        final tabs = [
          _HomeTab(
            key: homeTabKey,
            onTabChange: (i) => setState(() => _tab = i),
          ),
          const _RoutesListTab(),
          AlertsScreen(key: alertsTabKey),
          const ProfileScreen(),
        ];
        return Scaffold(
          body: IndexedStack(index: _tab, children: tabs),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorder, width: 0.5)),
            ),
            child: BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) {
                setState(() => _tab = i);
                if (i == 0) homeTabKey.currentState?._loadRoutes();
                if (i == 2) alertsTabKey.currentState?.loadAlerts();
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: kSea,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map_rounded),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_outlined),
                  activeIcon: Icon(Icons.notifications_rounded),
                  label: 'Alerts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outlined),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// GlobalKey lets HomeScreen call reload on _HomeTab from outside
final homeTabKey = GlobalKey<_HomeTabState>();
final alertsTabKey = GlobalKey<AlertsScreenState>();

class _HomeTab extends StatefulWidget {
  final ValueChanged<int> onTabChange;
  const _HomeTab({super.key, required this.onTabChange});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<dynamic> _subscribedRoutes = [];
  List<dynamic> _allRoutes = [];
  List<dynamic> _filteredRoutes = []; // filtered by search
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController(); // search input
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    // Listen to search input — filter routes as user types
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
        _filteredRoutes = _allRoutes.where((r) {
          final name = (r['name'] ?? '').toLowerCase();
          final area = (r['area'] ?? '').toLowerCase();
          final from = (r['start_point'] ?? '').toLowerCase();
          final to = (r['end_point'] ?? '').toLowerCase();
          return name.contains(_searchQuery) ||
              area.contains(_searchQuery) ||
              from.contains(_searchQuery) ||
              to.contains(_searchQuery);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allRoutes = await ApiService.getRoutes();
      List<dynamic> subscribedRoutes = [];
      if (UserSession.userId.isNotEmpty) {
        try {
          final subs = await ApiService.getSubscriptions(UserSession.userId);
          if (subs.isNotEmpty) {
            final subscribedIds = subs
                .map((s) => s['route_id'].toString())
                .toSet();
            subscribedRoutes = allRoutes
                .where((r) => subscribedIds.contains(r['id'].toString()))
                .toList();
          }
        } catch (_) {}
      }
      setState(() {
        _allRoutes = allRoutes;
        _filteredRoutes = allRoutes; // initially show all
        _subscribedRoutes = subscribedRoutes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = LanguageProvider.tr;
    // Decide which list to show in the "all routes" section
    final displayRoutes = _searchQuery.isEmpty ? _allRoutes : _filteredRoutes;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 150,
          backgroundColor: kSea,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: kSea,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('good_morning'),
                            style: const TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.8),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            UserSession.userName.isNotEmpty
                                ? UserSession.userName
                                : 'Commuter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      // FIX → Alert icon now navigates to Alerts tab
                      GestureDetector(
                        onTap: () => widget.onTabChange(2), // 2 = Alerts tab
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // FIX → Real search bar that filters routes as you type
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Color.fromRGBO(255, 255, 255, 0.7),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: tr('search_hint'),
                              hintStyle: const TextStyle(
                                color: Color.fromRGBO(255, 255, 255, 0.75),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        // Clear button — shows only when typing
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _QuickBtn(
                    icon: Icons.directions_bus_rounded,
                    label: tr('live_bus'),
                    onTap: () => widget.onTabChange(1),
                  ),
                  _QuickBtn(
                    icon: Icons.format_list_bulleted_rounded,
                    label: tr('all_routes'),
                    onTap: () => widget.onTabChange(1),
                  ),
                  _QuickBtn(
                    icon: Icons.schedule_rounded,
                    label: tr('schedule'),
                    onTap: () {},
                  ),
                  _QuickBtn(
                    icon: Icons.location_on_outlined,
                    label: tr('nearby'),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Show search results header when searching
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Search Results (${_filteredRoutes.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                ),
              // Show My Subscribed Routes section only when not searching
              if (_searchQuery.isEmpty) ...[
                Text(
                  tr('my_routes'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 10),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: kDanger),
                    ),
                  ),
                if (!_loading &&
                    _error == null &&
                    _subscribedRoutes.isEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kSeaLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          color: kSea,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            LanguageProvider.tr('no_subs_msg'),
                            style: TextStyle(
                              fontSize: 13,
                              color: kTextDark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      LanguageProvider.tr('all_routes_label'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  ..._allRoutes.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RouteCard(
                        route: r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RouteDetailScreen(routeId: r['id'] as String),
                          ),
                        ).then((_) => _loadRoutes()),
                      ),
                    ),
                  ),
                ],
                if (!_loading && _error == null && _subscribedRoutes.isNotEmpty)
                  ..._subscribedRoutes.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RouteCard(
                        route: r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RouteDetailScreen(routeId: r['id'] as String),
                          ),
                        ).then((_) => _loadRoutes()),
                      ),
                    ),
                  ),
              ],
              // Show search results when searching
              if (_searchQuery.isNotEmpty) ...[
                if (_filteredRoutes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No routes found',
                        style: TextStyle(color: kMuted),
                      ),
                    ),
                  ),
                ...displayRoutes.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RouteCard(
                      route: r,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RouteDetailScreen(routeId: r['id'] as String),
                        ),
                      ).then((_) => _loadRoutes()),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: kBorder, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kSeaLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kSea, size: 17),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextDark,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RouteCard extends StatelessWidget {
  final Map route;
  final VoidCallback onTap;
  const _RouteCard({required this.route, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final delay = route['delay_minutes'] ?? 0;
    final onTime = delay == 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
            BorderSide(color: kBorder, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    route['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: onTime
                        ? const Color(0xFFEAF3DE)
                        : const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    onTime ? LanguageProvider.tr('on_time') : '+$delay min',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onTime ? kSuccess : const Color(0xFF854F0B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${route['start_point'] ?? ''} → ${route['end_point'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: kMuted),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: kSea,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${route['total_stops'] ?? 0} stops  ·  ${route['area'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: kSea,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── ROUTES LIST TAB ──
class _RoutesListTab extends StatefulWidget {
  const _RoutesListTab();
  @override
  State<_RoutesListTab> createState() => _RoutesListTabState();
}

class _RoutesListTabState extends State<_RoutesListTab> {
  List<dynamic> _routes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allRoutes = await ApiService.getRoutes();
      setState(() {
        _routes = allRoutes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('All Routes')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Text(_error!, style: const TextStyle(color: kDanger)),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _routes.length,
            itemBuilder: (_, i) {
              final r = _routes[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RouteDetailScreen(routeId: r['id']),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border.fromBorderSide(
                      BorderSide(color: kBorder, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kSeaLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: kSea,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                            Text(
                              '${r['start_point'] ?? ''} → ${r['end_point'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: kMuted),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
