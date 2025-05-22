import 'package:flutter/foundation.dart' show kIsWeb;

// Export crypto market manager for all platforms
export 'crypto_market_manager.dart';
export 'crypto_price_model.dart';

// Web-safe platform environment access
Map<String, String> getPlatformEnvironment() {
  if (kIsWeb) {
    return {}; // Return empty map on web
  } else {
    try {
      // Try to import dart:io on non-web - this will only work on native platforms
      // and be skipped on web due to the if-check above
      return _getPlatformEnvNative();
    } catch (e) {
      return {}; // Fallback to empty map if anything fails
    }
  }
}

// Safe platform check methods
bool get isIOS => kIsWeb ? false : _isIOSNative();
bool get isAndroid => kIsWeb ? false : _isAndroidNative();
bool get isWeb => kIsWeb;

// These methods will be replaced by the actual implementation in native platforms
// and will never be called on web due to the kIsWeb checks above
Map<String, String> _getPlatformEnvNative() => {};
bool _isIOSNative() => false;
bool _isAndroidNative() => false;
