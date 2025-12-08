import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Lightweight wrapper around Google Mobile Ads initialization and IDs.
class AdService {
  Future<InitializationStatus> init() {
    return MobileAds.instance.initialize();
  }

  /// Default test banner ID per platform. Replace with your own live IDs
  /// when you are ready to publish.
  String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return null;
  }
}
