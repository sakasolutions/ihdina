import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat in-app purchases service. Initializes SDK and provides purchase logic.
/// Public API keys from RevenueCat Dashboard are safe in code; ensure they are not empty for production.
///
/// Bezahlstatus: ausschließlich **Pro** (Entitlement `pro` im RevenueCat-Dashboard).
///
/// [init] muss mit derselben [appUserId] wie das Backend-`installId` aufgerufen werden,
/// damit Webhooks den Nutzer zuordnen können (kein anonymer RC-User).
/// Ergebnis eines Kaufversuchs (für Analytics; [purchasePackage] bleibt bool).
enum PurchaseOutcome { success, cancelled, failed }

class RevenueCatService {
  /// Replace with your Apple App Store key from RevenueCat Dashboard for iOS release.
  static const String _appleApiKey = 'appl_KKEmUnPTUuePJsVPBrQWfbDAFtn';

  /// Google Play public key (RevenueCat) – set and valid for Android.
  static const String _googleApiKey = 'goog_OFwfNiVgXAnPOSUSkUjtwGvoQrQ';

  /// Entitlement state: updated by listener and [updateCustomerStatus].
  static bool isPro = false;

  /// Notifies listeners when Pro status changes.
  static final ValueNotifier<bool> isProNotifier = ValueNotifier<bool>(false);

  static Offerings? _cachedOfferings;

  static void _setEntitlementsFrom(CustomerInfo customerInfo) {
    final pro = customerInfo.entitlements.active.containsKey('pro');
    isPro = pro;
    isProNotifier.value = pro;
  }

  /// [appUserId] = persistentes Geräte-`installId` (muss vor dem Aufruf geladen sein).
  static Future<void> init({required String appUserId}) async {
    _cachedOfferings = null;
    final trimmed = appUserId.trim();
    if (trimmed.isEmpty) {
      throw StateError(
          'RevenueCatService.init requires a non-empty appUserId (installId).');
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

    final PurchasesConfiguration configuration;
    if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_appleApiKey)..appUserID = trimmed;
    } else if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey)
        ..appUserID = trimmed;
    } else {
      return; // Unsupported platform (Desktop etc.)
    }

    await Purchases.configure(configuration);

    Purchases.addCustomerInfoUpdateListener((CustomerInfo customerInfo) {
      _setEntitlementsFrom(customerInfo);
    });

    // Sicherstellen, dass nach ggf. SDK-internem Merge der Status passt.
    await updateCustomerStatus();
  }

  /// Fetches current customer info and updates [isPro].
  static Future<void> updateCustomerStatus() async {
    try {
      final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _setEntitlementsFrom(customerInfo);
    } catch (e) {
      // Handle error
    }
  }

  /// Fetches current offerings from RevenueCat. Returns null on error.
  static Future<Offerings?> getOfferings() async {
    if (_cachedOfferings != null) return _cachedOfferings;
    try {
      _cachedOfferings = await Purchases.getOfferings();
      return _cachedOfferings;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[RevenueCat] getOfferings failed: $e\n$st');
      }
      return null;
    }
  }

  static Future<List<Package>> getAvailablePackages() async {
    try {
      final offerings = await getOfferings();
      return offerings?.current?.availablePackages ?? [];
    } catch (e, st) {
      if (kDebugMode)
        debugPrint('[RevenueCat] getAvailablePackages failed: $e\n$st');
      return [];
    }
  }

  /// Purchases the given package with detailliertem Ergebnis.
  static Future<PurchaseOutcome> purchasePackageWithOutcome(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      await updateCustomerStatus();
      return PurchaseOutcome.success;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      if (kDebugMode) {
        debugPrint('[RevenueCat] purchase cancelled/failed: $code');
      }
      return PurchaseOutcome.failed;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[RevenueCat] purchasePackage failed: $e\n$st');
      }
      return PurchaseOutcome.failed;
    }
  }

  /// Purchases the given package. Returns true on success, false if user cancelled or error.
  static Future<bool> purchasePackage(Package package) async {
    final outcome = await purchasePackageWithOutcome(package);
    return outcome == PurchaseOutcome.success;
  }

  /// Restores purchases and updates entitlement flags. Returns true if the call succeeded.
  static Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _setEntitlementsFrom(info);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> presentOfferCodeRedemption() async {
    try {
      await Purchases.presentCodeRedemptionSheet();
    } catch (e) {
      if (kDebugMode)
        debugPrint('[RevenueCat] presentOfferCodeRedemption failed: $e');
    }
  }
}
