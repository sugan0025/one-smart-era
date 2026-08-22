import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/mock_data.dart';
import '../core/localization/app_translations.dart';
import '../core/services/auth_service.dart';
import '../core/services/weather_service.dart';
import '../models/user_model.dart';
import '../models/diagnosis_model.dart';

/// Global App State holding User Session, Language, Weather, and Alerts
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    _initPreferences();
  }

  // --- Localization ---
  String _lang = 'en';
  String get lang => _lang;
  bool get isTamil => _lang == 'ta';

  String t(String key) {
    return AppTranslations.dictionary[_lang]?[key] ??
        AppTranslations.dictionary['en']?[key] ??
        key;
  }

  void toggleLang() {
    _lang = _lang == 'en' ? 'ta' : 'en';
    _saveLanguagePref();
    notifyListeners();
  }

  void setLang(String newLang) {
    if (_lang != newLang) {
      _lang = newLang;
      _saveLanguagePref();
      notifyListeners();
    }
  }

  Future<void> _saveLanguagePref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keySelectedLanguage, _lang);
    } catch (_) {}
  }

  Future<void> _initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(AppConstants.keySelectedLanguage);
      if (savedLang != null) _lang = savedLang;

      // Auto restore session
      final user = await AuthService().loadSession();
      if (user != null) {
        login(user);
      }
    } catch (_) {}
  }

  // --- Active User Session ---
  AppUser? currentUser;
  bool get isLoggedIn => currentUser != null;

  // --- Navigation & Role Shell ---
  int navIndex = 0;
  void setNav(int index) {
    HapticFeedback.selectionClick();
    navIndex = index;
    notifyListeners();
  }

  // --- User Location & District ---
  LatLng userLocation = const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
  String detectedDistrict = AppConstants.defaultDistrict;
  LatLng? reportDraftLocation;
  String reportDraftAddress = '';

  Future<void> determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      userLocation = LatLng(pos.latitude, pos.longitude);
      _detectDistrict();
      fetchWeather();
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void updateLocation(LatLng loc) {
    userLocation = loc;
    _detectDistrict();
    notifyListeners();
  }

  void _detectDistrict() {
    // Determine closest known APMC Mandi district
    String closest = 'Erode';
    double minDistance = double.infinity;
    MockData.mandiData.forEach((district, data) {
      final lat = data['lat'] as double;
      final lng = data['lng'] as double;
      final dist = const Distance().as(LengthUnit.Kilometer, userLocation, LatLng(lat, lng));
      if (dist < minDistance) {
        minDistance = dist;
        closest = district;
      }
    });
    detectedDistrict = closest;
  }

  // --- Weather Data ---
  String weatherTemp = '31°C';
  String weatherDesc = 'Sunny & Warm';
  String weatherHumidity = '62%';
  IconData weatherIcon = Icons.wb_sunny_rounded;
  bool weatherLoading = false;

  Future<void> fetchWeather() async {
    weatherLoading = true;
    notifyListeners();
    try {
      final data = await WeatherService().fetchWeather(userLocation);
      weatherTemp = data.temperature;
      weatherDesc = data.condition;
      weatherHumidity = data.humidity;
      weatherIcon = data.icon;
    } catch (_) {}
    weatherLoading = false;
    notifyListeners();
  }

  // --- Agricultural Advisory Rotation ---
  int _advisoryIndex = 0;
  String get currentAdvisory =>
      MockData.advisories[_advisoryIndex % MockData.advisories.length];
  Timer? _advisoryTimer;

  void rotateAdvisory() {
    _advisoryIndex++;
    notifyListeners();
  }

  void startAdvisoryRotation() {
    _advisoryTimer?.cancel();
    _advisoryTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      _advisoryIndex++;
      notifyListeners();
    });
  }

  // --- SOS Emergency Broadcast ---
  bool sosActive = false;

  Future<void> triggerSOS() async {
    sosActive = true;
    HapticFeedback.vibrate();
    notifyListeners();
    // Simulate emergency broadcast
    await Future.delayed(const Duration(seconds: 4));
    sosActive = false;
    notifyListeners();
  }

  // --- Price Alerts ---
  final Map<String, bool> priceAlerts = {};

  void togglePriceAlert(String cropName) {
    priceAlerts[cropName] = !(priceAlerts[cropName] ?? false);
    notifyListeners();
  }

  // --- AI Diagnosis History ---
  final List<DiagnosisEntry> diagnosisHistory = [];

  void addDiagnosis(DiagnosisEntry entry) {
    diagnosisHistory.insert(0, entry);
    if (diagnosisHistory.length > 8) diagnosisHistory.removeLast();
    notifyListeners();
  }

  void clearDiagnosisHistory() {
    diagnosisHistory.clear();
    notifyListeners();
  }

  // --- Civic Points ---
  void addCivicPoints(int pts) {
    if (currentUser != null) {
      currentUser!.civicPoints += pts;
      notifyListeners();
    }
  }

  // --- Session Login / Logout ---
  void login(AppUser user) {
    currentUser = user;
    navIndex = 0;
    determinePosition();
    fetchWeather();
    startAdvisoryRotation();
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    navIndex = 0;
    _advisoryTimer?.cancel();
    diagnosisHistory.clear();
    priceAlerts.clear();
    AuthService().clearSession();
    notifyListeners();
  }

  @override
  void dispose() {
    _advisoryTimer?.cancel();
    super.dispose();
  }
}

final appState = AppState();
