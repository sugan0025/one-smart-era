/// Global Application Constants and Keys
class AppConstants {
  static const String appName = 'One Smart Era';
  static const String appTagline = 'Smart City Grievances & Farmer Assistance Platform';
  static const String appVersion = '1.2.0';

  // API Config (Override with env or local settings)
  static const String defaultOpenWeatherKey = 'OPEN_WEATHER_API_KEY_HERE';
  static const String defaultGroqApiKey = 'YOUR_GROQ_API_KEY_HERE';

  // Default Location (Sathyamangalam / Erode, Tamil Nadu)
  static const double defaultLatitude = 11.5034;
  static const double defaultLongitude = 77.2387;
  static const String defaultDistrict = 'Erode';

  // Civic Points System
  static const int pointsPerReportSubmission = 20;
  static const int pointsPerReportAccepted = 50;
  static const int pointsPerReportResolved = 100;
  static const int pointsPerUpvote = 2;

  // SLA Thresholds
  static const int slaBreachDays = 7;

  // Local Storage Keys
  static const String keyUserSession = 'one_smart_era_user_session';
  static const String keySelectedLanguage = 'one_smart_era_language';
  static const String keyOfflineReports = 'one_smart_era_offline_reports';
  static const String keyDiagnosisHistory = 'one_smart_era_diagnoses';
  static const String keyPriceAlerts = 'one_smart_era_price_alerts';
}
