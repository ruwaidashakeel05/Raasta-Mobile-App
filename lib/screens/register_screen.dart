import 'package:flutter/material.dart';
import '../main.dart';
import '../services/language_provider.dart';
import '../services/api_service.dart'; // import our API service
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Basic validation — make sure all fields are filled
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    // Show loading spinner and clear any previous error
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Call the real backend API instead of fake delay
      final result = await ApiService.register(
        name: _nameCtrl.text.trim(), // send name
        email: _emailCtrl.text.trim(), // send email
        password: _passCtrl.text, // send password (backend will hash it)
      );

      // Check if backend returned an error (e.g. email already registered)
      if (result.containsKey('detail')) {
        // Backend returned an error message
        setState(() {
          _error = result['detail']; // show the error to user
          _loading = false;
        });
        return;
      }

      // Success — save user session with real data from backend
      UserSession.userId = result['user_id']; // real UUID from database
      UserSession.userName = result['name']; // real name from database

      // Navigate to home screen and clear navigation stack
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      // Network error — backend not running or wrong IP
      setState(() {
        _error = 'Could not connect to server. Make sure backend is running.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = LanguageProvider.tr;
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, _inner) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              color: kSea,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 28,
                left: 24,
                right: 24,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('register_title'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('register_sub'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromRGBO(255, 255, 255, 0.8),
                    ),
                  ),
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
                    _Label(tr('full_name')),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'Your name'),
                    ),
                    const SizedBox(height: 16),
                    _Label(tr('email')),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'user@email.com',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Label(tr('password')),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        hintText: 'Create password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: kMuted,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(tr('create_account')),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            tr('have_account'),
                            style: const TextStyle(color: kMuted, fontSize: 12),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kSea,
                        side: const BorderSide(color: kSea),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        tr('login_instead'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: kMuted,
      letterSpacing: 0.5,
    ),
  );
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
      border: Border.all(color: kDanger.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: kDanger, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: kDanger, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
