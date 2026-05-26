import 'package:flutter/material.dart';
import '../main.dart';
import '../services/language_provider.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'q': 'How does live tracking work?',
      'a': 'Bus locations update every 5 seconds via GPS. Subscribe to a route to see real-time positions.'
    },
    {
      'q': 'How do I subscribe to a route?',
      'a': 'Open any route, scroll down and tap "Subscribe". You\'ll then get delay and arrival alerts.'
    },
    {
      'q': 'Why is my bus showing a delay?',
      'a': 'Delays happen due to traffic. The app shows the delay in minutes on the route card.'
    },
    {
      'q': 'How do I change the language?',
      'a': 'Go to Profile → Settings → Language and pick English, Urdu, Punjabi, or Pashto.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      // Fixed here: changed from (_, _) to (_, __)
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text(LanguageProvider.tr('help')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const _Sec('FAQ'),
          ..._faqs.map((f) => _FaqTile(q: f['q']!, a: f['a']!)),
          const SizedBox(height: 16),
          const _Sec('Contact'),
          const _ContactRow(
              icon: Icons.email_outlined,
              title: 'Email Support',
              sub: 'support@rasta.pk'),
          const SizedBox(height: 8),
          const _ContactRow(
              icon: Icons.phone_outlined,
              title: 'Phone',
              sub: '+92-51-1234567  (9am–5pm)'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _feedback(context),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Send Feedback'),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  void _feedback(BuildContext context) {
    final c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Send Feedback',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kTextDark)),
          const SizedBox(height: 12),
          TextField(
              controller: c,
              maxLines: 4,
              decoration: InputDecoration(
                  hintText: 'Tell us what\'s on your mind…',
                  hintStyle: const TextStyle(color: kMuted),
                  filled: true,
                  fillColor: kSeaLight,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBorder)))),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: kSea));
            },
            child: const Text('Submit'),
          ),
        ]),
      ),
    );
  }
}

class _Sec extends StatelessWidget {
  final String t;
  const _Sec(this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kMuted,
                letterSpacing: 1)),
      );
}

class _FaqTile extends StatefulWidget {
  final String q, a;
  const _FaqTile({required this.q, required this.a});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(
                  BorderSide(color: kBorder, width: 0.5))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Expanded(
                    child: Text(widget.q,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kTextDark))),
                Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: kMuted),
              ]),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(widget.a,
                    style: const TextStyle(
                        fontSize: 13, color: kMuted, height: 1.5)),
              ),
          ]),
        ),
      );
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const _ContactRow(
      {required this.icon, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(
                BorderSide(color: kBorder, width: 0.5))),
        child: Row(children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: kSeaLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: kSea, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextDark)),
            Text(sub, style: const TextStyle(fontSize: 12, color: kMuted)),
          ]),
        ]),
      );
}