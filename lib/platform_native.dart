import 'dart:io' show Platform;

// Implementation of platform-specific functions for native platforms
// These will be used by platform_imports.dart

Map<String, String> _getPlatformEnvNative() => Platform.environment;
bool _isIOSNative() => Platform.isIOS;
bool _isAndroidNative() => Platform.isAndroid;
