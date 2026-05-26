import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../services/language_provider.dart';
import 'login_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => AlertsScreenState();
}

class AlertsScreenState extends State<AlertsScreen>
    with WidgetsBindingObserver {
  // <-- ADDED
  List<dynamic> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // <-- ADDED
    _loadAlerts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // <-- ADDED
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAlerts();
    }
  }

  void loadAlerts() => _loadAlerts();

  Future<void> _loadAlerts() async {
    if (!mounted) return; // <-- ADDED
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final alerts = await ApiService.getAlerts(UserSession.userId);
      if (!mounted) return; // <-- ADDED
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return; // <-- ADDED
      setState(() {
        _error = 'Could not connect to server.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, inner) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: kSea,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  const Text(
                    'Alerts',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Text(
                        _alerts.length.toString(),
                        style: const TextStyle(
                          color: kSea,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Text(_error!, style: const TextStyle(color: kDanger)),
                ),
              )
            else if (_alerts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No alerts yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _AlertCard(alert: _alerts[i]),
                    childCount: _alerts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map alert;
  const _AlertCard({required this.alert});

  Color get dotColor {
    final msg = (alert['message'] ?? '').toString().toLowerCase();
    if (msg.contains('delayed') || msg.contains('delay')) return kDanger;
    if (msg.contains('arrived') || msg.contains('arrival')) return kSuccess;
    return kAmber;
  }

  @override
  Widget build(BuildContext context) => Container(
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route ${alert['route_id'] ?? ''} — Alert',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                alert['message'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: kMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                alert['sent_at'] ?? '',
                style: const TextStyle(fontSize: 11, color: kMuted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
