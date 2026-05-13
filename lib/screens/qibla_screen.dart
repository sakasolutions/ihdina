import 'dart:io' show Platform;
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Full-screen Qibla compass: mosque background, glass circle, gold needle, N marker.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  bool _loading = true;
  /// Systemweite Ortungsdienste aus (nicht App-Berechtigung).
  bool _locationServicesOff = false;
  bool _permissionGranted = false;
  bool _supported = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareQiblah();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Singleton-Stream von flutter_qiblah: sonst zweiter Besuch / nach Fehler oft „leer“ oder Single-Listen-Fehler.
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _prepareQiblah();
    }
  }

  Future<void> _prepareQiblah() async {
    if ((!_permissionGranted || _locationServicesOff) && mounted) {
      setState(() => _loading = true);
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() {
        _loading = false;
        _locationServicesOff = true;
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionGranted = false;
        _locationServicesOff = false;
        _loading = false;
      });
      return;
    }

    // Nur auf Android relevant; auf iOS liefert die Methode typischerweise nicht true.
    final bool sensorOk = Platform.isAndroid
        ? await FlutterQiblah.androidDeviceSensorSupport() == true
        : true;
    if (!mounted) return;
    if (!sensorOk) {
      setState(() {
        _locationServicesOff = false;
        _permissionGranted = true;
        _supported = false;
        _loading = false;
      });
      return;
    }

    // Gleiche APIs wie flutter_qiblah intern – und alten Stream verwerfen (z. B. nach erstem Fehler / Einstellungen).
    FlutterQiblah().dispose();
    if (!mounted) return;
    setState(() {
      _locationServicesOff = false;
      _permissionGranted = true;
      _supported = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const heroPhase = HeroPhase.day;

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
          'Qibla',
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
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentChampagneGold),
      );
    }
    if (_locationServicesOff) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bitte systemweite Ortungsdienste aktivieren.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Geolocator.openLocationSettings(),
                style: TextButton.styleFrom(
                  foregroundColor: _accentChampagneGold,
                ),
                child: Text(
                  'Ortungsdienste öffnen',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_permissionGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bitte Standort-Berechtigung erteilen',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                style: TextButton.styleFrom(
                  foregroundColor: _accentChampagneGold,
                ),
                child: Text(
                  'Einstellungen öffnen',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_supported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Dein Gerät unterstützt keinen Kompass',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _accentChampagneGold),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Bitte Standort aktivieren',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
          );
        }
        final qiblahDirection = snapshot.data;
        if (qiblahDirection == null) {
          return const Center(
            child: CircularProgressIndicator(color: _accentChampagneGold),
          );
        }
        return _CompassContent(direction: qiblahDirection);
      },
    );
  }
}

class _CompassContent extends StatelessWidget {
  const _CompassContent({required this.direction});

  final QiblahDirection direction;

  @override
  Widget build(BuildContext context) {
    final directionRad = -direction.direction * (pi / 180);
    final qiblahRad = -direction.qiblah * (pi / 180);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: directionRad,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 140),
                      child: Text(
                        'N',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: qiblahRad,
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: _QiblaNeedlePainter(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Richte dein Telefon flach aus.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _QiblaNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 120.0;

    final needlePaint = Paint()
      ..color = _accentChampagneGold
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - 12, center.dy + 16);
    path.lineTo(center.dx, center.dy + 8);
    path.lineTo(center.dx + 12, center.dy + 16);
    path.close();
    canvas.drawPath(path, needlePaint);

    final outlinePaint = Paint()
      ..color = _accentChampagneGold.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
