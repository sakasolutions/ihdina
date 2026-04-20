import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_keys.dart';
import 'data/prayer/notification_service.dart';
import 'debug/db_diagnostics.dart';
import 'services/install_id_service.dart';
import 'services/revenuecat_service.dart';
import 'theme/app_theme.dart';
import 'screens/bootstrap_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Security: never require API keys in release builds.
  // In debug we allow local dev configuration (e.g. via --dart-define or optional dotenv).
  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env is intentionally not bundled in production; ignore if missing in dev.
    }
  }
  final installId = await InstallIdService.instance.getOrCreate();
  try {
    await RevenueCatService.init(appUserId: installId);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('RevenueCatService.init failed: $e\n$st');
    }
  }
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  if (kDebugMode) {
    await runDbDiagnostics();
  }
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.sandBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const IhdinaApp());
}

class IhdinaApp extends StatelessWidget {
  const IhdinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Ihdina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
          surface: AppColors.sandBg,
          brightness: Brightness.light,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _AppPageTransitionsBuilder(),
            TargetPlatform.iOS: _AppPageTransitionsBuilder(),
            TargetPlatform.macOS: _AppPageTransitionsBuilder(),
            TargetPlatform.windows: _AppPageTransitionsBuilder(),
            TargetPlatform.linux: _AppPageTransitionsBuilder(),
            TargetPlatform.fuchsia: _AppPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      home: const BootstrapScreen(),
    );
  }
}

/// Einheitliche, dezente Screen-Transition (leichtes Slide + Fade) für alle Push/Pop-Routen.
class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == Navigator.defaultRouteName) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.96, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.025, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
