import 'package:flutter/material.dart';
import '../services/api_service.dart'; // API service for backend calls
import '../main.dart';
import '../services/language_provider.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';
import 'subscriptions_screen.dart';
import 'notification_settings_screen.dart';
import 'edit_profile_screen.dart';

// CHANGED: StatelessWidget → StatefulWidget to load real subscriptions count
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  int _subsCount = 0; // real number of active subscriptions
  int _alertsCount = 0; // real number of alerts received

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCounts(); // load real counts when screen opens
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh counts when app comes back into focus
    if (state == AppLifecycleState.resumed) {
      _loadCounts();
    }
  }

  Future<void> _loadCounts() async {
    try {
      // Fetch real subscriptions for this user from backend
      final subs = await ApiService.getSubscriptions(UserSession.userId);
      // Fetch real alerts for this user from backend
      final alerts = await ApiService.getAlerts(UserSession.userId);
      setState(() {
        _subsCount = subs.length; // real subscription count
        _alertsCount = alerts.length; // real alerts count
      });
    } catch (e) {
      // If API fails, counts stay at 0 — not a critical error
      print('Could not load profile counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = LanguageProvider.tr;

    // Use real user name from session, fallback to Guest if empty
    final name = UserSession.userName.isNotEmpty
        ? UserSession.userName
        : 'Guest';

    // Build initials from first letters of first and last name
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, inner) => Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadCounts,
          child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              automaticallyImplyLeading: false,
              backgroundColor: kSea,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: kSea,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 10),
                      // Avatar with real initials
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.6),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Real user name from session
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Real user ID shown as reference
                      Text(
                        UserSession.userId.isNotEmpty
                            ? 'ID: ${UserSession.userId.substring(0, 8)}...'
                            : '',
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
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Show real subscription count in subtitle
                  _ProfileRow(
                    icon: Icons.format_list_bulleted_rounded,
                    title: tr('my_subs'),
                    subtitle: '$_subsCount active routes', // real count
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Show real alerts count in subtitle
                  _ProfileRow(
                    icon: Icons.notifications_outlined,
                    title: tr('alert_hist'),
                    subtitle: '$_alertsCount alerts received', // real count
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AlertsScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _ProfileRow(
                    icon: Icons.tune_rounded,
                    title: tr('notif_settings'),
                    subtitle: tr('manage_pref'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _ProfileRow(
                    icon: Icons.person_outline_rounded,
                    title: tr('edit_profile'),
                    subtitle: tr('name_email'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _ProfileRow(
                    icon: Icons.settings_outlined,
                    title: tr('settings'),
                    subtitle: 'Language, notifications, help',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout button — clears session and goes back to login
                  GestureDetector(
                    onTap: () {
                      // Clear real user session data
                      UserSession.userId = '';
                      UserSession.userName = '';
                      // Navigate back to login and clear all screens
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCEBEB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: kDanger,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            tr('logout'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kDanger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kSeaLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kSea, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kMuted, size: 20),
        ],
      ),
    ),
  );
}
