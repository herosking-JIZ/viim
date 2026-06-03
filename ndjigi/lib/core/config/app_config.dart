enum Flavor { dev, staging, prod }

class AppConfig {
  static late Flavor _flavor;
  static late AppConfig _instance;

  final String apiBaseUrl;
  final String socketUrl;
  final String tileServerUrl;
  final bool enableAnalytics;
  final bool enableCrashlytics;

  AppConfig._({
    required this.apiBaseUrl,
    required this.socketUrl,
    required this.tileServerUrl,
    required this.enableAnalytics,
    required this.enableCrashlytics,
  });

  static void setup({required Flavor flavor}) {
    _flavor = flavor;

    const String apiBaseUrlDev = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api',
    );
    const String socketUrlDev = String.fromEnvironment(
      'SOCKET_URL',
      defaultValue: 'http://localhost:3000',
    );
    const String tileServerUrlDev = String.fromEnvironment(
      'TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org',
    );

    String apiBaseUrl = apiBaseUrlDev;
    String socketUrl = socketUrlDev;
    String tileServerUrl = tileServerUrlDev;
    bool enableAnalytics = false;
    bool enableCrashlytics = false;

    switch (flavor) {
      case Flavor.dev:
        apiBaseUrl = apiBaseUrlDev;
        socketUrl = socketUrlDev;
        tileServerUrl = tileServerUrlDev;
        enableAnalytics = false;
        enableCrashlytics = false;
        break;

      case Flavor.staging:
        apiBaseUrl =
            const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://staging-api.ndjigi.app/api');
        socketUrl = const String.fromEnvironment('SOCKET_URL', defaultValue: 'https://staging-api.ndjigi.app');
        tileServerUrl = const String.fromEnvironment(
          'TILE_URL',
          defaultValue: 'https://tile.openstreetmap.org',
        );
        enableAnalytics = true;
        enableCrashlytics = true;
        break;

      case Flavor.prod:
        apiBaseUrl =
            const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ndjigi.app/api');
        socketUrl = const String.fromEnvironment('SOCKET_URL', defaultValue: 'https://api.ndjigi.app');
        tileServerUrl = const String.fromEnvironment(
          'TILE_URL',
          defaultValue: 'https://tile.openstreetmap.org',
        );
        enableAnalytics = true;
        enableCrashlytics = true;
        break;
    }

    _instance = AppConfig._(
      apiBaseUrl: apiBaseUrl,
      socketUrl: socketUrl,
      tileServerUrl: tileServerUrl,
      enableAnalytics: enableAnalytics,
      enableCrashlytics: enableCrashlytics,
    );
  }

  static AppConfig get instance {
    return _instance;
  }

  static Flavor get flavor {
    return _flavor;
  }

  static bool get isDebug => flavor == Flavor.dev;
  static bool get isStaging => flavor == Flavor.staging;
  static bool get isProd => flavor == Flavor.prod;
}
