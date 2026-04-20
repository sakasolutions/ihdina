import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/db/database_provider.dart';
import '../data/prayer/notification_service.dart';
import '../data/quran/models/surah_model.dart';
import '../data/quran/quran_repository.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'root_shell.dart';

/// Ensures prebuilt DB is ready, then navigates to the app. No drift/import.
class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  String _status = 'Vorbereiten…';
  bool _error = false;
  /// true = Asset im Bundle gefunden; false = Fehler oder noch nicht geprüft.
  bool _startImageInBundle = true;
  /// true = start.png ist dekodiert und kann sofort angezeigt werden (kein dunkler Rahmen zuerst).
  bool _imageReady = false;

  @override
  void initState() {
    super.initState();
    _checkStartImage();
    _precacheImage();
    _run();
  }

  Future<void> _checkStartImage() async {
    try {
      await rootBundle.load(_startImage);
      if (mounted) setState(() => _startImageInBundle = true);
    } catch (e, st) {
      if (mounted) setState(() {
        _startImageInBundle = false;
        _imageReady = true;
      });
      debugPrint('BootstrapScreen: start.png nicht im Asset-Bundle: $e');
      debugPrint('$st');
    }
  }

  Future<void> _precacheImage() async {
    try {
      await precacheImage(AssetImage(_startImage), context);
      if (mounted) setState(() => _imageReady = true);
    } catch (_) {
      if (mounted) setState(() => _imageReady = true);
    }
  }

  /// Mindestzeit, die start.png *sichtbar* angezeigt wird (Timer startet erst, wenn Bild bereit ist).
  static const Duration _minDisplayDuration = Duration(milliseconds: 1400);
  static const Duration _homeFadeDuration = Duration(milliseconds: 450);

  Future<void> _run() async {
    final stopwatch = Stopwatch()..start();
    try {
      await DatabaseProvider.instance.database;
      final results = await Future.wait<dynamic>([
        QuranRepository.instance.getAllSurahs(),
        NotificationService.instance.reschedulePrayerNotificationsOnAppStartup(),
      ]);
      final surahs = results[0] as List<SurahModel>;
      if (surahs.length >= 114 && mounted) {
        // Warten, bis start.png angezeigt wird (precache fertig), dann Mindestzeit laufen lassen.
        while (!_imageReady && mounted) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        if (!mounted) return;
        final elapsed = stopwatch.elapsed;
        if (elapsed < _minDisplayDuration) {
          await Future.delayed(_minDisplayDuration - elapsed);
        }
        if (mounted) _navigate();
        return;
      }
      if (mounted) {
        setState(() {
          _error = true;
          _status = 'Quran-Daten nicht geladen (${surahs.length} Suren).';
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = true;
          _status = 'Fehler: $e';
        });
      }
    }
  }

  void _navigate() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: _homeFadeDuration,
        reverseTransitionDuration: _homeFadeDuration,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: const RootShell(),
        ),
      ),
    );
  }

  /// Einziges Start-Bild (1242×2688), nichts darübergelegt.
  static const String _startImage = 'assets/img/start.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emeraldDark,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Immer zuerst Gradient (vermeidet dunklen ersten Frame)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.mainGradient,
              ),
            ),
            // start.png erst anzeigen, wenn gecacht → sofort sichtbar, kein Flackern
            if (_startImageInBundle && _imageReady)
              Image.asset(
                _startImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, Object error, __) {
                  debugPrint('BootstrapScreen: start.png Image.asset Fehler: $error');
                  return const SizedBox.expand();
                },
              ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  if (_error)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _status,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTokens.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
