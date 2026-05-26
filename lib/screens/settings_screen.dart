import 'package:flutter/material.dart';
import '../main.dart';
import '../services/language_provider.dart';
import 'language_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _delayAlerts = true, _arrivalAlerts = true;

  @override
  Widget build(BuildContext context) {
    final tr = LanguageProvider.tr;
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, inner) => Scaffold(
        appBar: AppBar(
          title: Text(tr('settings')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          _Section('Language'),
          _Tile(
            icon: Icons.language_rounded, title: tr('language'),
            subtitle: kLanguages.firstWhere(
                    (l) => l.code == LanguageProvider.instance.code)
                .nativeName,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(kLanguages.firstWhere(
                      (l) => l.code == LanguageProvider.instance.code)
                  .flag,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: kMuted, size: 20),
            ]),
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const LanguageScreen())),
          ),
          const SizedBox(height: 16),
          _Section(tr('notifications')),
          _Tile(
            icon: Icons.notifications_active_outlined,
            title: tr('delay_alerts'), subtitle: tr('delay_sub'),
            trailing: Switch.adaptive(
              value: _delayAlerts,
              onChanged: (v) => setState(() => _delayAlerts = v),
              thumbColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                      ? kSea : Colors.white),
              trackColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                      ? kSeaMid : Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.location_on_outlined,
            title: tr('arrival_alerts'), subtitle: tr('arrival_sub'),
            trailing: Switch.adaptive(
              value: _arrivalAlerts,
              onChanged: (v) => setState(() => _arrivalAlerts = v),
              thumbColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                      ? kSea : Colors.white),
              trackColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                      ? kSeaMid : Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 16),
          _Section('Support'),
          _Tile(
            icon: Icons.help_outline_rounded,
            iconBg: const Color(0xFFFAEEDA),
            iconColor: const Color(0xFF854F0B),
            title: tr('help'), subtitle: 'FAQ & contact options',
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const HelpScreen())),
          ),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.logout_rounded,
            iconBg: const Color(0xFFFCEBEB), iconColor: kDanger,
            title: tr('logout'), titleColor: kDanger,
            onTap: () {
              UserSession.userId = '';
              UserSession.userName = '';
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                      (_) => false);
            },
          ),
          const SizedBox(height: 32),
          Center(child: Text('Rasta v1.0.0',
              style: TextStyle(fontSize: 12,
                  color: Colors.grey.shade400))),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title.toUpperCase(), style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: kMuted, letterSpacing: 1)),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor, iconBg;
  final Color? titleColor;
  const _Tile({required this.icon, required this.title,
    this.subtitle, this.trailing, this.onTap,
    this.iconColor = kSea, this.iconBg = kSeaLight,
    this.titleColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
            BorderSide(color: kBorder, width: 0.5)),
      ),
      child: Row(children: [
        Container(width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor ?? kTextDark)),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(
                fontSize: 12, color: kMuted)),
        ])),
        trailing ?? (onTap != null
            ? const Icon(Icons.chevron_right,
            color: kMuted, size: 20)
            : const SizedBox()),
      ]),
    ),
  );
}