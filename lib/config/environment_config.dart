import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;

/// Defines the environment (development, staging, production)
enum Environment { development, staging, production }

/// Configuration for API endpoints and environment settings
class EnvironmentConfig {
  /// Current environment
  static const Environment _environment = Environment.development;

  /// Backend host configuration for different platforms and environments
  /// For iOS Simulator: 10.0.2.2 (special IP to access the host machine)
  /// For Android Emulator: 10.0.2.2 (special IP to access the host machine)
  /// For real devices: Use the actual IP address of your development machine
  /// For web: localhost or 127.0.0.1
  ///
  /// To find your machine's IP on macOS:
  /// Run: ifconfig | grep "inet " | grep -v 127.0.0.1
  /// For local development, use the IP from en0 or en1 interface

  /// Backend port
  static const int backendPort = 8000;

  /// Singleton instance
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();

  /// Factory constructor
  factory EnvironmentConfig() {
    return _instance;
  }

  /// Private constructor
  EnvironmentConfig._internal();

  /// Get the API base URL based on platform and environment
  /// This resolves the iOS Simulator localhost issue by using platform-specific URLs
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.production:
        return _productionApiUrl;
      case Environment.staging:
        return _stagingApiUrl;
      case Environment.development:
        return _developmentApiUrl;
    }
  }

  /// Get development API URL based on platform
  static String get _developmentApiUrl {
    if (kIsWeb) {
      // Web: localhost or 127.0.0.1
      return 'http://localhost:$backendPort/api';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS Simulator and real device: Use special IP to access host's localhost
      // For iOS Simulator on Mac: 10.0.2.2 maps to the host machine
      return 'http://10.0.2.2:$backendPort/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator: Use special IP to access host machine's localhost
      return 'http://10.0.2.2:$backendPort/api';
    } else {
      // Desktop (Windows, Linux, macOS): localhost
      return 'http://localhost:$backendPort/api';
    }
  }

  /// Get staging API URL
  static String get _stagingApiUrl {
    return 'https://staging-api.reliefconnect.com/api';
  }

  /// Get production API URL
  static String get _productionApiUrl {
    return 'https://api.reliefconnect.com/api';
  }

  /// Get the current environment as a string
  static String get environmentName {
    return _environment.toString().split('.').last;
  }

  /// Check if running in development environment
  static bool get isDevelopment => _environment == Environment.development;

  /// Check if running in staging environment
  static bool get isStaging => _environment == Environment.staging;

  /// Check if running in production environment
  static bool get isProduction => _environment == Environment.production;

  /// Get the target platform as a string
  static String get platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  /// Print configuration info (useful for debugging)
  static void printConfig() {
    if (isDevelopment) {
      print('=== API Configuration ===');
      print('Environment: $environmentName');
      print('Platform: $platformName');
      print('API Base URL: $apiBaseUrl');
      print('Backend Port: $backendPort');
      print('==========================');
    }
  }
}
