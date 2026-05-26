import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/language_provider.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const RastaApp());
}

// ── Global colors used by every screen ───────────────────────
const kSea      = Color(0xFF1A9E8E);
const kSeaDark  = Color(0xFF0D7A6D);
const kSeaLight = Color(0xFFE0F5F2);
const kSeaMid   = Color(0xFFA8DDD7);
const kCard     = Color(0xFFF4FCFB);
const kBorder   = Color(0xFFC0E8E3);
const kTextDark = Color(0xFF1A2E2C);
const kMuted    = Color(0xFF5F8A85);
const kDanger   = Color(0xFFE24B4A);
const kAmber    = Color(0xFFEF9F27);
const kSuccess  = Color(0xFF3B6D11);

class RastaApp extends StatefulWidget {
  const RastaApp({super.key});
  @override State<RastaApp> createState() => _RastaAppState();
}

class _RastaAppState extends State<RastaApp> {
  @override
  void initState() {
    super.initState();
    LanguageProvider.instance.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: LanguageProvider.instance.isRtl
          ? TextDirection.rtl : TextDirection.ltr,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rasta',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kSea),
          scaffoldBackgroundColor: kCard,
          appBarTheme: const AppBarTheme(
            backgroundColor: kSea,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kSea,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kSeaLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kSea, width: 2)),
            hintStyle: const TextStyle(color: kMuted, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SPLASH SCREEN
// ════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, _inner) => Scaffold(
        backgroundColor: kSea,
        body: SafeArea(
          child: Stack(children: [
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 96, height: 96,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.directions_bus_rounded,
                          size: 52, color: kSea),
                    ),
                    const SizedBox(height: 24),
                    Text(LanguageProvider.tr('app_name'),
                        style: const TextStyle(fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 5)),
                    const SizedBox(height: 8),
                    Text(LanguageProvider.tr('tagline'),
                        style: const TextStyle(fontSize: 11,
                            letterSpacing: 2,
                            color: Color.fromRGBO(255,255,255,0.75),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 48),
                    Row(mainAxisSize: MainAxisSize.min,
                        children: List.generate(3,
                                (i) => _PulseDot(delay: i * 220))),
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: 28, left: 0, right: 0,
              child: _LangPicker(onChanged: () => setState(() {})),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LangPicker extends StatelessWidget {
  final VoidCallback onChanged;
  const _LangPicker({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cur = LanguageProvider.instance.code;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Language / زبان',
          style: TextStyle(
              color: Color.fromRGBO(255,255,255,0.6),
              fontSize: 11, letterSpacing: 1)),
      const SizedBox(height: 10),
      Wrap(
        alignment: WrapAlignment.center, spacing: 8, runSpacing: 8,
        children: kLanguages.map((lang) {
          final sel = lang.code == cur;
          return GestureDetector(
            onTap: () {
              LanguageProvider.instance.set(lang.code);
              onChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? Colors.white
                    : const Color.fromRGBO(255,255,255,0.18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: sel ? Colors.white
                        : const Color.fromRGBO(255,255,255,0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(lang.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(lang.nativeName, style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? kSea : Colors.white)),
              ]),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}

class _PulseDot extends StatefulWidget {
  final int delay;
  const _PulseDot({required this.delay});
  @override State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _a = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay),
            () { if (mounted) _c.repeat(reverse: true); });
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: FadeTransition(opacity: _a,
        child: Container(width: 8, height: 8,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle))),
  );
}