import 'dart:async';

import 'package:flutter/material.dart';

import '../data/prayer/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_bottom_nav.dart';
import 'home_screen.dart';
import 'prayer_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';

/// Root mit Body + floating Premium Bottom Nav. Body wechselt per Index.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(
        NotificationService.instance.maybeReschedulePrayerNotificationsOnAppResume(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: const [
                  HomeScreen(),
                  QuranScreen(),
                  PrayerScreen(),
                  SettingsScreen(rootTabMode: true),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: PremiumBottomNav(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    enableHaptics: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
