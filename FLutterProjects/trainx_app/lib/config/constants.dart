import 'package:flutter/foundation.dart';

class AppConstants {
  // 1. Live Cloud Server URL (If deployed to Render/Railway/AWS/VPS):
  // Set this when your backend is hosted online, e.g. 'https://api.trainx.com/api/v1'
  static const String liveServerUrl = '';

  // 2. Local Development Settings (Host PC IP for Wi-Fi testing):
  static const String pcWifiIp = '192.168.0.109';
  static const String serverPort = '5000';

  // Automatically determine backend URL based on platform & mode:
  static String get baseUrl {
    if (liveServerUrl.isNotEmpty) {
      return liveServerUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:$serverPort/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // On real physical phone (Release APK), use PC Wi-Fi IP so it connects over LAN
        // On Android emulator (Debug), 10.0.2.2 routes to host PC
        if (kReleaseMode) {
          return 'http://$pcWifiIp:$serverPort/api/v1';
        }
        return 'http://10.0.2.2:$serverPort/api/v1';
      case TargetPlatform.iOS:
        return 'http://$pcWifiIp:$serverPort/api/v1';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:$serverPort/api/v1';
    }
  }

  static String get loginEndpoint => '$baseUrl/auth/login-password';
  static String get sendOtpEndpoint => '$baseUrl/auth/send-otp';
  static String get verifyOtpEndpoint => '$baseUrl/auth/verify-otp';
  static String get profileEndpoint => '$baseUrl/auth/me';
}
