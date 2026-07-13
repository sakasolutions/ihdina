import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/prayer/notification_service.dart';
import '../data/settings/settings_repository.dart';
import '../theme/app_theme.dart';
import 'root_shell.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Erststart: Willkommen → Standort → Erinnerungen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Duration _transitionDuration = Duration(milliseconds: 450);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _complete();
  }

  Future<void> _requestLocationAndContinue() async {
    await Geolocator.requestPermission();
    if (!mounted) return;
    _nextPage();
  }

  Future<void> _requestNotificationsAndComplete() async {
    await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    await _complete();
  }

  Future<void> _complete() async {
    await SettingsRepository.instance.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: _transitionDuration,
        reverseTransitionDuration: _transitionDuration,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: [
                    _WelcomePage(onContinue: _nextPage),
                    _LocationPage(
                      onAllow: _requestLocationAndContinue,
                      onSkip: _nextPage,
                    ),
                    _NotificationsPage(
                      onEnable: _requestNotificationsAndComplete,
                      onSkip: _complete,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PageDots(currentIndex: _currentPage, count: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.currentIndex, required this.count});

  final int currentIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color:
                active ? _accentChampagneGold : Colors.white.withOpacity(0.28),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageLayout extends StatelessWidget {
  const _OnboardingPageLayout({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final Widget icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          icon,
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const Spacer(flex: 3),
          _OnboardingPrimaryButton(label: primaryLabel, onPressed: onPrimary),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 12),
            _OnboardingTextButton(
                label: secondaryLabel!, onPressed: onSecondary!),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      icon: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/img/app_icon.png',
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
      title: 'Ihdina',
      body:
          'Jeden Tag zeigt dir Ihdina einen Koranvers — mit deutscher Übersetzung und einer KI-Erklärung, die Kontext und Bedeutung verständlich macht.',
      primaryLabel: 'Weiter',
      onPrimary: onContinue,
    );
  }
}

class _LocationPage extends StatelessWidget {
  const _LocationPage({
    required this.onAllow,
    required this.onSkip,
  });

  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      icon: Icon(
        Icons.location_on_outlined,
        size: 64,
        color: _accentChampagneGold,
      ),
      title: 'Gebetszeiten für deinen Ort',
      body:
          'Damit deine Gebetszeiten exakt stimmen, brauchen wir deinen Standort. Du kannst das jederzeit in den Einstellungen ändern.',
      primaryLabel: 'Standort erlauben',
      onPrimary: onAllow,
      secondaryLabel: 'Später',
      onSecondary: onSkip,
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({
    required this.onEnable,
    required this.onSkip,
  });

  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      icon: Icon(
        Icons.notifications_outlined,
        size: 64,
        color: _accentChampagneGold,
      ),
      title: 'Erinnerungen',
      body:
          'Ihdina kann dich an Gebetszeiten und deinen Tagesvers erinnern. Du entscheidest, ob und wann.',
      primaryLabel: 'Erinnerungen aktivieren',
      onPrimary: onEnable,
      secondaryLabel: 'Später',
      onSecondary: onSkip,
    );
  }
}

class _OnboardingPrimaryButton extends StatelessWidget {
  const _OnboardingPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _accentChampagneGold,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.emeraldDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingTextButton extends StatelessWidget {
  const _OnboardingTextButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.55),
        ),
      ),
    );
  }
}
