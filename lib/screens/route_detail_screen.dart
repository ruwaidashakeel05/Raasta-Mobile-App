import 'package:flutter/material.dart';
import '../services/api_service.dart'; // API service for backend calls
import '../main.dart';
import 'login_screen.dart'; // for UserSession
import 'live_map_screen.dart';

// CHANGED: StatelessWidget → StatefulWidget to load real route data
class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});
  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  // Real data from backend (replaces hardcoded _routeData map)
  Map<String, dynamic> _route = {}; // route info from backend
  List<dynamic> _stops = []; // stops list from backend
  bool _loading = true; // show spinner while loading
  String? _error; // show error if API fails
  bool _subscribed = false; // whether user is subscribed
  bool _subLoading = false; // show spinner on subscribe button

  @override
  void initState() {
    super.initState();
    _loadData(); // load real route, stops and subscription status
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch route, stops and subscriptions all at once
      final results = await Future.wait([
        ApiService.getRoute(widget.routeId),
        ApiService.getStops(widget.routeId),
        ApiService.getSubscriptions(UserSession.userId),
      ]);
      final subs = results[2] as List<dynamic>;
      // Check if this specific route is in user's subscriptions
      final isSubscribed = subs.any(
        (s) => s['route_id'].toString() == widget.routeId,
      );
      setState(() {
        _route = results[0] as Map<String, dynamic>;
        _stops = results[1] as List<dynamic>;
        _subscribed =
            isSubscribed; // true = show Unsubscribe, false = show Subscribe
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load route data.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleSubscribe() async {
    setState(() => _subLoading = true); // show spinner on button
    try {
      if (_subscribed) {
        // Already subscribed — unsubscribe
        await ApiService.unsubscribe(
          userId: UserSession.userId,
          routeId: widget.routeId,
        );
        setState(() => _subscribed = false);
      } else {
        // Not subscribed — subscribe
        await ApiService.subscribe(
          userId: UserSession.userId,
          routeId: widget.routeId,
        );
        setState(() => _subscribed = true);
      }
    } catch (e) {
      // Show error snackbar if subscribe fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to server.')),
      );
    }
    setState(() => _subLoading = false); // hide spinner
  }

  @override
  Widget build(BuildContext context) {
    // Read real values from backend response
    final name = _route['name'] ?? widget.routeId;
    final from = _route['start_point'] ?? '';
    final to = _route['end_point'] ?? '';
    final delay = _route['delay_minutes'] ?? 0;
    final onTime = delay == 0;
    final total = _route['total_stops'] ?? _stops.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: kSea,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: kSea,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 56,
                  left: 20,
                  right: 20,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Routes',
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.75),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Real route name from backend
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Real start and end points from backend
                    Text(
                      '$from → $to',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromRGBO(255, 255, 255, 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Show spinner while loading
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          // Show error if API failed
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Text(_error!, style: const TextStyle(color: kDanger)),
              ),
            )
          // Show real data
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Info boxes with real data from backend
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _InfoBox(
                        label: 'STATUS',
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: onTime ? kSuccess : kAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              onTime ? 'ON TIME' : 'DELAYED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: onTime ? kSuccess : kAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Real total stops from backend
                      _InfoBox(
                        label: 'TOTAL STOPS',
                        child: Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: kSea,
                          ),
                        ),
                      ),
                      // ETA calculated from stops count
                      _InfoBox(
                        label: 'ETA TO END',
                        child: Text(
                          '${_stops.length * 4} min',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kSea,
                          ),
                        ),
                      ),
                      // Real delay from backend
                      _InfoBox(
                        label: 'DELAY',
                        child: Text(
                          '$delay min',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: delay > 0 ? kAmber : kSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Stop Sequence',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Real stops from backend
                  ..._stops.asMap().entries.map((e) {
                    final stop = e.value;
                    final index = e.key;
                    final isLast = index == _stops.length - 1;
                    return _StopRow(
                      name: stop['name'] ?? '',
                      seq: stop['sequence'] ?? index + 1,
                      isLast: isLast,
                    );
                  }),

                  const SizedBox(height: 20),

                  // Track on map button
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveMapScreen(routeId: widget.routeId),
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text('Track on Map — ${widget.routeId}'),
                  ),
                  const SizedBox(height: 10),

                  // Subscribe / Unsubscribe button with real API call
                  OutlinedButton.icon(
                    onPressed: _subLoading ? null : _toggleSubscribe,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _subscribed ? kDanger : kSea,
                      side: BorderSide(color: _subscribed ? kDanger : kSea),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _subLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _subscribed
                                ? Icons.notifications_off_outlined
                                : Icons.notifications_outlined,
                            size: 18,
                          ),
                    label: Text(
                      _subscribed
                          ? 'Unsubscribe from ${widget.routeId}'
                          : 'Subscribe to ${widget.routeId}',
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoBox({required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: const Border.fromBorderSide(
        BorderSide(color: kBorder, width: 0.5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: kMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}

class _StopRow extends StatelessWidget {
  final String name;
  final int seq;
  final bool isLast;
  const _StopRow({required this.name, required this.seq, required this.isLast});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // Stop dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: kSea, width: 2),
              ),
            ),
            // Connector line between stops
            if (!isLast) Container(width: 2, height: 28, color: kBorder),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                // Real stop name from backend
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
                const Spacer(),
                // Show stop sequence number
                Text(
                  'Stop $seq',
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
