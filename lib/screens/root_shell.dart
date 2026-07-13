import 'dart:async';

import 'package:flutter/material.dart';

import '../services/analytics/analytics_constants.dart';
import '../services/analytics/analytics_service.dart';
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

  static const _tabScreens = <String>[
    AnalyticsScreens.dua,
    AnalyticsScreens.quran,
    AnalyticsScreens.home,
    AnalyticsScreens.prayer,
    AnalyticsScreens.settings,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        AnalyticsService.instance.trackScreenViewed(
          screen: _tabScreens[_currentIndex],
        ),
      );
    });
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
      AnalyticsService.instance.onAppResumed();
      unawaited(
        NotificationService.instance
            .maybeReschedulePrayerNotificationsOnAppResume(),
      );
    } else if (state == AppLifecycleState.paused) {
      AnalyticsService.instance.onAppPaused();
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
                    onTap: (index) {
                      if (index == _currentIndex) return;
                      final prev = _tabScreens[_currentIndex];
                      setState(() => _currentIndex = index);
                      unawaited(
                        AnalyticsService.instance.trackScreenViewed(
                          screen: _tabScreens[index],
                          previousScreen: prev,
                        ),
                      );
                    },
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
