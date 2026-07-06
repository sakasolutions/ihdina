import 'dart:async';

import 'package:flutter/material.dart';

import '../data/prayer/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_bottom_nav.dart';
import 'dua_themes_screen.dart';
import 'home_screen.dart';
import 'prayer_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';

/// Index des Home-Tabs in der Bottom-Navigation (Mitte).
const int kHomeTabIndex = 2;

/// Root mit Body + floating Premium Bottom Nav. Body wechselt per Index.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _currentIndex = kHomeTabIndex;

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
      canPop: _currentIndex == kHomeTabIndex,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _currentIndex != kHomeTabIndex) {
          setState(() => _currentIndex = kHomeTabIndex);
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
                  DuaThemesScreen(),
                  QuranScreen(),
                  HomeScreen(),
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
