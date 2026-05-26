import 'package:flutter/material.dart';
import '../services/api_service.dart';          // for ApiService.getSubscriptions()
import '../main.dart';                          // for kSea, kSeaLight etc
import '../services/language_provider.dart';   // for translations
import 'login_screen.dart';                    // for UserSession
import 'route_detail_screen.dart';             // to navigate to route detail

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<dynamic> _subscriptions = [];   // real subscriptions from backend
  bool _loading = true;                // show spinner while loading
  String? _error;                      // show error if API fails

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();              // load when screen opens
  }

  Future<void> _loadSubscriptions() async {
    setState(() { _loading = true; _error = null; });

    try {
      // Fetch real subscriptions from backend
      final subs = await ApiService.getSubscriptions(UserSession.userId);
      setState(() {
        _subscriptions = subs;         // update UI with real data
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = 'Could not load subscriptions';
        _loading = false;
      });
    }
  }

  Future<void> _unsubscribe(String routeId) async {
    try {
      // Call API to unsubscribe from route
      await ApiService.unsubscribe(
        userId:  UserSession.userId,
        routeId: routeId,
      );
      // Reload list after unsubscribing
      _loadSubscriptions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unsubscribed from $routeId')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not unsubscribe')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text(LanguageProvider.tr('my_subs')),
          backgroundColor: kSea,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _loading
            // Show spinner while loading
            ? const Center(child: CircularProgressIndicator())
            // Show error if API failed
            : _error != null
                ? Center(child: Text(_error!,
                    style: const TextStyle(color: kDanger)))
                // Show empty state if no subscriptions
                : _subscriptions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48, color: kMuted),
                            SizedBox(height: 12),
                            Text('No subscriptions yet',
                                style: TextStyle(color: kMuted, fontSize: 15)),
                            SizedBox(height: 6),
                            Text('Subscribe to routes to get alerts',
                                style: TextStyle(color: kMuted, fontSize: 12)),
                          ],
                        ),
                      )
                    // Show real subscriptions list
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _subscriptions.length,
                        itemBuilder: (_, i) {
                          final sub = _subscriptions[i];
                          final routeId = sub['route_id'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder, width: 0.5),
                            ),
                            child: Row(children: [
                              // Route icon
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                    color: kSeaLight,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.directions_bus_rounded,
                                    color: kSea, size: 22),
                              ),
                              const SizedBox(width: 12),
                              // Route info
                              Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                // Show route ID from backend
                                Text('Route $routeId',
                                    style: const TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: kTextDark)),
                                const SizedBox(height: 2),
                                // Show when subscribed
                                Text(
                                  sub['created_at'] != null
                                      ? 'Since ${sub['created_at'].toString().substring(0, 10)}'
                                      : 'Active',
                                  style: const TextStyle(
                                      fontSize: 12, color: kMuted),
                                ),
                              ])),
                              // View route button
                              IconButton(
                                icon: const Icon(Icons.chevron_right,
                                    color: kMuted),
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        RouteDetailScreen(routeId: routeId))),
                              ),
                              // Unsubscribe button
                              IconButton(
                                icon: const Icon(Icons.notifications_off_outlined,
                                    color: kDanger, size: 20),
                                onPressed: () => _unsubscribe(routeId),
                                tooltip: 'Unsubscribe',
                              ),
                            ]),
                          );
                        },
                      ),
      ),
    );
  }
}
