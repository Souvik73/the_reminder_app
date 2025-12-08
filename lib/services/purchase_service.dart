import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:the_reminder_app/config/subscription_keys.dart';

/// RevenueCat wrapper that exposes entitlement and purchase helpers.
class PurchaseService {
  PurchaseService();

  final _premiumController = StreamController<bool>.broadcast();
  CustomerInfo? _latestCustomerInfo;
  bool _initialized = false;
  bool _hasApiKey = false;
  bool _isPremium = false;
  String? _lastError;

  Stream<bool> get premiumStream => _premiumController.stream;
  bool get isPremium => _isPremium;
  bool get isInitialized => _initialized;
  bool get hasApiKey => _hasApiKey;
  bool get isSupportedPlatform => Platform.isAndroid || Platform.isIOS;
  String? get lastError => _lastError;

  /// Configure the SDK using platform-specific public keys.
  Future<void> init() async {
    if (_initialized || !isSupportedPlatform) return;

    final apiKey = Platform.isAndroid
        ? SubscriptionKeys.androidApiKey
        : SubscriptionKeys.iosApiKey;

    _hasApiKey = apiKey.isNotEmpty;
    if (!_hasApiKey) {
      _lastError = 'Missing RevenueCat public SDK key for this platform.';
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));

      final info = await Purchases.getCustomerInfo();
      _updatePremiumState(info);
      Purchases.addCustomerInfoUpdateListener(_updatePremiumState);

      _initialized = true;
      _lastError = null;
    } catch (err, stack) {
      _lastError = err.toString();
      debugPrint('PurchaseService init failed: $err\n$stack');
    }
  }

  Future<List<Package>> loadPackages() async {
    if (!_ready) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? <Package>[];
    } catch (err, stack) {
      _lastError = err.toString();
      debugPrint('Failed to load packages: $err\n$stack');
      return [];
    }
  }

  Future<CustomerInfo?> purchase(Package package) async {
    if (!_ready) return null;
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(package));
      _updatePremiumState(result.customerInfo);
      return result.customerInfo;
    } catch (err, stack) {
      _lastError = err.toString();
      debugPrint('Purchase failed: $err\n$stack');
      rethrow;
    }
  }

  Future<CustomerInfo?> restore() async {
    if (!_ready) return null;
    try {
      final info = await Purchases.restorePurchases();
      _updatePremiumState(info);
      return info;
    } catch (err, stack) {
      _lastError = err.toString();
      debugPrint('Restore failed: $err\n$stack');
      rethrow;
    }
  }

  Future<CustomerInfo?> refreshCustomerInfo() async {
    if (!_ready) return null;
    try {
      final info = await Purchases.getCustomerInfo();
      _updatePremiumState(info);
      return info;
    } catch (err, stack) {
      _lastError = err.toString();
      debugPrint('Refresh failed: $err\n$stack');
      return null;
    }
  }

  void dispose() {
    _premiumController.close();
  }

  bool get _ready => _initialized && _hasApiKey && isSupportedPlatform;

  void _updatePremiumState(CustomerInfo info) {
    _latestCustomerInfo = info;
    final entitlement = info.entitlements.active[SubscriptionKeys.removeAdsEntitlementId];
    final nextIsPremium = entitlement != null;
    if (_isPremium != nextIsPremium) {
      _isPremium = nextIsPremium;
      _premiumController.add(_isPremium);
    } else {
      _isPremium = nextIsPremium;
    }
  }
}
