import 'package:flutter/material.dart';
import '../main.dart';
import '../services/language_provider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageProvider.instance,
      // Fixed here: changed from (_, _) to (_, __)
      builder: (_, __) {
        final cur = LanguageProvider.instance.code;
        return Scaffold(
          appBar: AppBar(
            title: Text(LanguageProvider.tr('lang_title')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: kSeaLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.info_outline, color: kSea, size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        LanguageProvider.tr('applies_inst'),
                        style: const TextStyle(fontSize: 13, color: kTextDark))),
              ]),
            ),
            ...kLanguages.map((lang) {
              final sel = lang.code == cur;
              return GestureDetector(
                onTap: () {
                  LanguageProvider.instance.set(lang.code);
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel ? kSeaLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: sel ? kSea : kBorder,
                        width: sel ? 1.5 : 0.5),
                  ),
                  child: Row(children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(lang.nativeName,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? kSea : kTextDark)),
                          Text(lang.englishName,
                              style: const TextStyle(
                                  fontSize: 13, color: kMuted)),
                        ])),
                    AnimatedOpacity(
                      opacity: sel ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                              color: kSea, shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 15)),
                    ),
                  ]),
                ),
              );
            }),
          ]),
        );
      },
    );
  }
}