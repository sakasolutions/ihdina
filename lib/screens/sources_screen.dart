import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';

/// Quellen & Lizenzen: Arabischer Text, deutsche Übersetzung, KI/Tafsir – Deep Emerald Glassmorphism.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  static const Color _accentChampagneGold = Color(0xFFE5C07B);
  static const String _tanzilUrl = 'https://tanzil.net';
  static const String _quranEncUrl = 'https://quranenc.com';

  @override
  Widget build(BuildContext context) {
    final heroPhase = HeroPhase.day;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Quellen & Lizenzen',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    DynamicHeroTheme.backgroundAsset(heroPhase),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  children: [
                    _SourceCard(
                      icon: Icons.menu_book,
                      title: 'Arabischer Originaltext',
                      body: 'Der arabische Text des Korans wird vom Tanzil-Projekt (tanzil.net) bereitgestellt. Einem hochpräzisen, verifizierten und international anerkannten Standard für digitale Koran-Texte.',
                      linkText: 'tanzil.net',
                      linkUrl: _tanzilUrl,
                    ),
                    const SizedBox(height: 20),
                    _SourceCard(
                      icon: Icons.translate,
                      title: 'Deutsche Bedeutung',
                      body: 'Die deutsche Übersetzung stammt von Frank Bubenheim und Dr. Nadim Elias. Diese anerkannte Übersetzung wurde offiziell bereitgestellt von der Enzyklopädie des edlen Korans (QuranEnc.com).',
                      linkText: 'QuranEnc.com',
                      linkUrl: _quranEncUrl,
                    ),
                    const SizedBox(height: 20),
                    _SourceCard(
                      icon: Icons.auto_awesome,
                      title: 'KI-Erklärungen & Tafsir',
                      body: 'Die Erklärungen zu den Versen werden von einer künstlichen Intelligenz generiert. Die KI ist strikt angewiesen, sich ausschließlich auf klassische und authentische sunnitische Tafsir-Werke (wie Tafsir Ibn Kathir) zu stützen.\n\nHinweis: Da die Antworten maschinell zusammengefasst werden, können Fehler nicht zu 100 % ausgeschlossen werden. Für komplexe theologische Fragen (Fiqh) konsultiere bitte stets gelehrte Personen.',
                    ),
                    const SizedBox(height: 20),
                    _SourceCard(
                      icon: Icons.phonelink_ring,
                      title: 'Transliteration (Lautschrift)',
                      body: 'Die lateinische Transliteration basiert auf den frei verfügbaren Daten des Tanzil Projects (tanzil.net). Diese Daten sind unter den Bedingungen der Creative Commons Lizenz frei nutzbar.',
                      linkText: 'tanzil.net',
                      linkUrl: _tanzilUrl,
                    ),
                    const SizedBox(height: 20),
                    _SourceCard(
                      icon: Icons.volume_up_rounded,
                      title: 'Audio-Rezitationen',
                      body: 'Die Audio-Rezitationen (Mishary Rashid Alafasy) werden freundlicherweise über die offene API von EveryAyah.com bereitgestellt und live gestreamt.',
                      linkText: 'EveryAyah.com',
                      linkUrl: 'https://everyayah.com',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.body,
    this.linkText,
    this.linkUrl,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? linkText;
  final String? linkUrl;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: SourcesScreen._accentChampagneGold,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              body,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.5,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (linkText != null && linkUrl != null) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(linkUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Text(
                  linkText!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: SourcesScreen._accentChampagneGold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
