import 'package:flutter/material.dart';
import '../services/api_service.dart';          // for ApiService.updateNotifications()
import '../main.dart';                          // for kSea, kBorder etc
import '../services/language_provider.dart';   // for translations
import 'login_screen.dart';                    // for UserSession

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _delayAlerts   = true;     // delay alert toggle state
  bool _arrivalAlerts = true;     // arrival alert toggle state
  bool _saving        = false;    // show spinner while saving

  Future<void> _saveSettings(bool delayAlerts, bool arrivalAlerts) async {
    if (_saving) return;          // prevent double tap

    setState(() => _saving = true);
    try {
      // Call API to save notification preferences
      await ApiService.updateNotifications(
        userId:        UserSession.userId,
        delayAlerts:   delayAlerts,
        arrivalAlerts: arrivalAlerts,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final tr = LanguageProvider.tr;

    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text(tr('notif_settings')),
          backgroundColor: kSea,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: kSeaLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: kSea, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Manage your notification preferences',
                      style: TextStyle(fontSize: 13, color: kTextDark)),
                ),
              ]),
            ),

            // Delay alerts toggle
            _NotificationTile(
              title:    tr('delay_alerts'),
              subtitle: tr('delay_sub'),
              value:    _delayAlerts,
              onChanged: (value) {
                setState(() => _delayAlerts = value);   // update UI immediately
                _saveSettings(value, _arrivalAlerts);   // save to backend
              },
            ),
            const SizedBox(height: 12),

            // Arrival alerts toggle
            _NotificationTile(
              title:    tr('arrival_alerts'),
              subtitle: tr('arrival_sub'),
              value:    _arrivalAlerts,
              onChanged: (value) {
                setState(() => _arrivalAlerts = value); // update UI immediately
                _saveSettings(_delayAlerts, value);     // save to backend
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder, width: 0.5),
    ),
    child: Row(children: [
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600, color: kTextDark)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: kMuted)),
      ])),
      Switch(
        value: value,
        onChanged: onChanged,
        activeColor: kSea,        // use app color for active state
      ),
    ]),
  );
}
