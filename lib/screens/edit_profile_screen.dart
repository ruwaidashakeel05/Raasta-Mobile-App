import 'package:flutter/material.dart';
import '../services/api_service.dart';          // for ApiService.updateProfile()
import '../main.dart';                          // for kSea, kSeaLight etc
import '../services/language_provider.dart';   // for translations
import 'login_screen.dart';                    // for UserSession

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _saving = false;       // show spinner on save button

  @override
  void initState() {
    super.initState();
    // Pre-fill name from current session
    _nameController     = TextEditingController(text: UserSession.userName);
    _emailController    = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Validate name is not empty
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);   // show spinner

    try {
      // Call API to update profile
      await ApiService.updateProfile(
        userId:   UserSession.userId,
        name:     _nameController.text.trim(),
        email:    _emailController.text.isNotEmpty
                      ? _emailController.text.trim() : null,
        password: _passwordController.text.isNotEmpty
                      ? _passwordController.text : null,
      );

      // Update session with new name immediately
      UserSession.userName = _nameController.text.trim();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);         // go back to profile screen

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }

    setState(() => _saving = false);  // hide spinner
  }

  @override
  Widget build(BuildContext context) {
    final tr = LanguageProvider.tr;

    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text(tr('edit_profile')),
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
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: kSeaLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: kSea, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Update your profile information',
                      style: TextStyle(fontSize: 13, color: kTextDark)),
                ),
              ]),
            ),

            // Name field — pre-filled with current name from session
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr('full_name'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Email field — optional, leave blank to keep current
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: tr('email'),
                hintText: 'Leave blank to keep current',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Password field — optional, leave blank to keep current
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: tr('password'),
                hintText: 'Leave blank to keep current',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: kSea,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
