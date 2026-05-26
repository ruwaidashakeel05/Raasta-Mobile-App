import 'package:flutter/material.dart';
import '../services/api_service.dart';          // API service for backend calls
import '../main.dart';
import '../services/language_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class UserSession {
  static String userId = '';
  static String userName = '';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose();
  }

  Future<void> _login() async {
    // Basic validation — make sure both fields are filled
    if (_emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    // Show loading spinner and clear previous error
    setState(() { _loading = true; _error = null; });

    try {
      // Call real backend API instead of fake delay
      final result = await ApiService.login(
        email: _emailCtrl.text.trim(),      // send email
        password: _passwordCtrl.text,       // send password (backend hashes and compares)
      );

      // Check if backend returned an error e.g. wrong password or user not found
      if (result.containsKey('detail')) {
        setState(() {
          _error = result['detail'];         // show backend error message to user
          _loading = false;
        });
        return;
      }

      // Success — save real user data from backend into session
      UserSession.userId   = result['user_id'];   // real UUID from database
      UserSession.userName = result['name'];       // real name from database

      // Navigate to home screen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));

    } catch (e) {
      // Network error — backend not running or wrong IP
      setState(() {
        _error = 'Could not connect to server. Make sure backend is running.';
        _loading = false;
      });
    }
  }

  void _showLangSheet() => showModalBottomSheet(
    context: context, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20))),
    builder: (_) => _LangSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final tr = LanguageProvider.tr;
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, _inner) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          Container(
            color: kSea,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 28,
              left: 24, right: 24, bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                  GestureDetector(
                    onTap: _showLangSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255,255,255,0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min,
                          children: [
                        const Icon(Icons.language,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          kLanguages.firstWhere((l) =>
                          l.code == LanguageProvider.instance.code)
                              .nativeName,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Color.fromRGBO(255,255,255,0.7),
                            size: 14),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(tr('welcome'),
                    style: const TextStyle(fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(tr('login_sub'),
                    style: const TextStyle(fontSize: 14,
                        color: Color.fromRGBO(255,255,255,0.8))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  if (_error != null) ...[
                    _ErrorBox(_error!),
                    const SizedBox(height: 12),
                  ],
                  Text(tr('email'),
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        hintText: 'user@email.com'),
                  ),
                  const SizedBox(height: 16),
                  Text(tr('password'),
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                            color: kMuted),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Text(tr('login')),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: Text(tr('or'),
                          style: const TextStyle(
                              color: kMuted, fontSize: 13)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kSea,
                      side: const BorderSide(color: kSea),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(tr('create_account'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(tr('forgot'),
                          style: const TextStyle(
                              color: kSea, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LangSheet extends StatefulWidget {
  @override State<_LangSheet> createState() => _LangSheetState();
}

class _LangSheetState extends State<_LangSheet> {
  @override
  Widget build(BuildContext context) {
    final cur = LanguageProvider.instance.code;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 18),
        Align(alignment: Alignment.centerLeft,
          child: Text(LanguageProvider.tr('select_lang'),
              style: const TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kTextDark)),
        ),
        const SizedBox(height: 14),
        ...kLanguages.map((lang) {
          final sel = lang.code == cur;
          return GestureDetector(
            onTap: () {
              LanguageProvider.instance.set(lang.code);
              setState(() {});
              Future.delayed(const Duration(milliseconds: 250),
                      () { if (mounted) Navigator.pop(context); });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? kSeaLight : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? kSea : kBorder,
                    width: sel ? 1.5 : 0.5),
              ),
              child: Row(children: [
                Text(lang.flag,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(lang.nativeName,
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: sel ? kSea : kTextDark)),
                  Text(lang.englishName,
                      style: const TextStyle(
                          fontSize: 12, color: kMuted)),
                ])),
                if (sel) const Icon(Icons.check_circle_rounded,
                    color: kSea, size: 20),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFCEBEB),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
          color: kDanger.withValues(alpha: 0.4)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: kDanger, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: const TextStyle(
              color: kDanger, fontSize: 13))),
    ]),
  );
}
