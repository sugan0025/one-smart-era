import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

// ==========================================
// API KEYS & CONFIGURATION
// ==========================================
const String openWeatherApiKey = 'OPEN_WEATHER_API_KEY_HERE';
const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
const String adminMasterCode = 'SUGAN@0025';

// ==========================================
// MOCK MANDI DATA (District → Mandi)
// ==========================================
const Map<String, Map<String, dynamic>> _mandiData = {
  'Erode': {'name': 'Erode APMC Mandi', 'lat': 11.3410, 'lng': 77.7172},
  'Sathyamangalam': {'name': 'Sathy Farmers Market', 'lat': 11.5034, 'lng': 77.2387},
  'Gobichettipalayam': {'name': 'Gobi APMC Mandi', 'lat': 11.4520, 'lng': 77.4350},
  'Coimbatore': {'name': 'Coimbatore APMC Mandi', 'lat': 11.0168, 'lng': 76.9558},
  'Salem': {'name': 'Salem APMC Mandi', 'lat': 11.6643, 'lng': 78.1460},
  'Default': {'name': 'Nearest Mandi (Demo)', 'lat': 11.5034, 'lng': 77.3000},
};

// Agmarknet-style real crop price snapshot data by district
const Map<String, List<Map<String, dynamic>>> _agmarknetData = {
  'Erode': [
    {'name': 'Tomato', 'price': 38.0, 'predicted': 41.0, 'demand': 'High'},
    {'name': 'Onion', 'price': 28.0, 'predicted': 25.0, 'demand': 'Medium'},
    {'name': 'Banana', 'price': 22.0, 'predicted': 24.0, 'demand': 'High'},
    {'name': 'Turmeric', 'price': 95.0, 'predicted': 102.0, 'demand': 'High'},
    {'name': 'Coconut', 'price': 18.0, 'predicted': 17.0, 'demand': 'Medium'},
  ],
  'Sathyamangalam': [
    {'name': 'Tomato', 'price': 34.0, 'predicted': 37.0, 'demand': 'High'},
    {'name': 'Brinjal', 'price': 24.0, 'predicted': 27.0, 'demand': 'High'},
    {'name': 'Banana', 'price': 20.0, 'predicted': 22.0, 'demand': 'Medium'},
    {'name': 'Onion', 'price': 26.0, 'predicted': 23.0, 'demand': 'Medium'},
    {'name': 'Coconut', 'price': 16.0, 'predicted': 18.0, 'demand': 'High'},
  ],
  'Gobichettipalayam': [
    {'name': 'Sugarcane', 'price': 3.2, 'predicted': 3.5, 'demand': 'High'},
    {'name': 'Tomato', 'price': 36.0, 'predicted': 39.0, 'demand': 'High'},
    {'name': 'Potato', 'price': 32.0, 'predicted': 30.0, 'demand': 'Medium'},
    {'name': 'Banana', 'price': 21.0, 'predicted': 23.0, 'demand': 'High'},
    {'name': 'Onion', 'price': 27.0, 'predicted': 24.0, 'demand': 'Medium'},
  ],
  'Coimbatore': [
    {'name': 'Tomato', 'price': 32.0, 'predicted': 35.0, 'demand': 'Medium'},
    {'name': 'Potato', 'price': 33.0, 'predicted': 31.0, 'demand': 'High'},
    {'name': 'Brinjal', 'price': 22.0, 'predicted': 26.0, 'demand': 'High'},
    {'name': 'Cauliflower', 'price': 28.0, 'predicted': 30.0, 'demand': 'Medium'},
    {'name': 'Beans', 'price': 45.0, 'predicted': 48.0, 'demand': 'High'},
  ],
};

// Mock warehouse data
const List<Map<String, dynamic>> _warehouseData = [
  {'id': 'wh1', 'name': 'Sathyamangalam Cold Storage', 'location': 'Market Road, Sathy', 'lat': 11.5034, 'lng': 77.2387, 'capacity': 500, 'used': 320, 'crops': ['Tomato', 'Onion', 'Banana']},
  {'id': 'wh2', 'name': 'Erode APMC Warehouse', 'location': 'NH-544, Erode', 'lat': 11.3410, 'lng': 77.7172, 'capacity': 800, 'used': 450, 'crops': ['Turmeric', 'Onion', 'Coconut']},
  {'id': 'wh3', 'name': 'Gobi Farmers Aggregation Center', 'location': 'Bhavani Road, Gobichettipalayam', 'lat': 11.4520, 'lng': 77.4350, 'capacity': 350, 'used': 180, 'crops': ['Sugarcane', 'Tomato', 'Potato']},
];

// Mock ward data for Sathyamangalam region
const List<Map<String, dynamic>> _wardData = [
  {'id': 'w1', 'name': 'Market Road Area', 'ward': 'Ward 1', 'center_lat': 11.5034, 'center_lng': 77.2387, 'radius': 0.015},
  {'id': 'w2', 'name': 'Bus Stand Colony', 'ward': 'Ward 2', 'center_lat': 11.5090, 'center_lng': 77.2410, 'radius': 0.012},
  {'id': 'w3', 'name': 'Bannari Road Junction', 'ward': 'Ward 3', 'center_lat': 11.4970, 'center_lng': 77.2320, 'radius': 0.018},
  {'id': 'w4', 'name': 'Thalamalai Colony', 'ward': 'Ward 4', 'center_lat': 11.5120, 'center_lng': 77.2280, 'radius': 0.014},
  {'id': 'w5', 'name': 'Sathy Town Panchayat', 'ward': 'Ward 5', 'center_lat': 11.5010, 'center_lng': 77.2450, 'radius': 0.020},
  {'id': 'w6', 'name': 'Karattur Village', 'ward': 'Ward 6', 'center_lat': 11.4890, 'center_lng': 77.2510, 'radius': 0.016},
];

const List<String> _departments = ['Roads', 'Water', 'Sanitation', 'Electricity', 'Transport', 'Public Works'];

const List<String> _cropOptions = ['Tomato', 'Onion', 'Potato', 'Brinjal', 'Banana', 'Sugarcane', 'Turmeric', 'Coconut', 'Cauliflower', 'Beans', 'Other'];

const Map<String, String> _cropOptionsTamil = {
  'Tomato': 'தக்காளி',
  'Onion': 'வெங்காயம்',
  'Potato': 'உருளைக்கிழங்கு',
  'Brinjal': 'கத்தரிக்காய்',
  'Banana': 'வாழைப்பழம்',
  'Sugarcane': 'கரும்பு',
  'Turmeric': 'மஞ்சள்',
  'Coconut': 'தேங்காய்',
  'Cauliflower': 'காலிஃபிளவர்',
  'Beans': 'பீன்ஸ்',
  'Other': 'மற்றவை',
};

// ==========================================
// INTERNATIONALIZATION (i18n)
// ==========================================
const Map<String, Map<String, String>> i18n = {
  'en': {
    'app_name': 'One Smart Era',
    'subtitle': 'Connecting Citizens, Farmers & Governance',
    'role_public': 'Public Citizen',
    'role_farmer': 'Farmer',
    'role_admin': 'Administrator',
    'login': 'Login',
    'phone': 'Phone Number',
    'otp': 'OTP / Admin Code',
    'home': 'Home',
    'map': 'Map',
    'report': 'Report',
    'profile': 'Profile',
    'market': 'Market',
    'doctor': 'Crop Doctor',
    'demand': 'Demand',
    'update': 'Update Price',
    'dashboard': 'Dashboard',
    'assign': 'Assign',
    'analytics': 'Analytics',
    'users': 'Citizens',
    'warehouse': 'Warehouse',
    'civic_points': 'Civic Points',
    'hospitals': 'Hospitals',
    'schemes': 'Govt Schemes',
    'rti': 'RTI Portal',
    'cm_cell': 'CM Cell',
    'transport': 'Transport',
    'submit': 'Submit Report',
    'logout': 'Secure Logout',
    'verify': 'Verify / Suggest',
    'surplus': 'Add Surplus',
    'welcome': 'Welcome,',
    'essential_services': 'Essential Services',
    'report_issue': 'Report Issue Here?',
    'using_gps': 'Using Current GPS',
    'start_report': 'Start Report',
    'new_report': 'New Report',
    'issue_category': 'Issue Category',
    'report_details': 'Report Details',
    'short_title': 'Short Title (e.g., Deep Pothole)',
    'provide_context': 'Provide more context...',
    'tap_scan': 'Tap to Scan Leaf',
    'analyze_crop': 'Analyze with AI',
    'diagnosis_treatment': 'Diagnosis & Treatment',
    'snap_leaf': 'Snap a Leaf',
    'logistics': 'Logistics',
    'micro_market': 'Transport Logistics',
    'connect_citizens': 'Book a government-subsidized truck to transport your harvest to the market directly.',
    'command_center': 'Command Center',
    'total': 'Total',
    'pending': 'Pending',
    'resolved': 'Resolved',
    'resolution_ratio': 'Resolution Ratio',
    'live_issues': 'Live Issues',
    'awaiting_action': 'Awaiting Action',
    'reject': 'Reject',
    'resolve': 'Resolve',
    'city_heatmap': 'City Heatmap',
    'high_density': 'High density areas indicate severe infrastructure failure.',
    'citizens_directory': 'Citizens Directory',
    'edit': 'Edit',
    'save': 'Save Changes',
    'password': 'Password',
    'local_market': 'Local Market',
    'no_internet': 'No internet connection. Please try again.',
    'fill_all_fields': 'Please fill in all required fields.',
    'invalid_phone': 'Please enter a valid 10-digit phone number.',
    'invalid_credentials': 'Invalid phone number or password.',
    'user_not_found': 'Phone number not found. Please register.',
    'error_generic': 'Something went wrong. Please try again.',
    'photo_optional': 'Photo (Optional)',
    'location': 'Location',
    'submitting': 'Submitting...',
    'loading': 'Loading...',
    'analyzing': 'Analyzing...',
    'booking_transport': 'Book Transport',
    'load_weight': 'Estimated Load Weight (kg)',
    'truck_assigned': 'Transport request submitted! Status: Requested.',
    'confirm_booking': 'Confirm Booking',
    'retrieve_password': 'Retrieve Password',
    'get_password': 'Get Password',
    'forgot_password': 'Forgot Password?',
    'already_account': 'Already have an account? Login',
    'new_citizen': 'New citizen? Register Profile',
    'register': 'Register',
    'registration_success': 'Registration Successful! +100 Points',
    'full_name': 'Full Name',
    'city_village': 'City/Village Address',
    'email_optional': 'Email (Optional)',
    'delete_citizen': 'Delete Citizen?',
    'delete_confirm': 'This will permanently remove the user from the database.',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'delete_success': 'User deleted successfully.',
    'all_resolved': 'All tasks resolved! 🎉',
    'zero_issues': 'Zero Issues Reported',
    'zero_desc': 'Waiting for citizens to submit new reports.',
    'edit_profile': 'Edit Profile',
    'name': 'Name',
    'no_firebase': 'Firebase required for live User Directory.',
    'add_title': 'Please add a title for the report.',
    'report_submitted': 'Report Submitted! Awaiting admin review.',
    'location_unavailable': 'Location service unavailable.',
    'my_reports': 'My Reports',
    'no_reports': 'No reports submitted yet.',
    'price_alert': 'Price Alert',
    'alert_on': 'Alert set! You\'ll be notified when price rises.',
    'alert_off': 'Alert removed.',
    'set_alert': 'Set Alert',
    'crop_history': 'Diagnosis History',
    'clear_history': 'Clear History',
    'nearest_mandi': 'Nearest Mandi',
    'agmarknet_source': 'Source: Agmarknet (Prototype Snapshot)',
    'local_prices': 'Prices for your area',
    'notifications': 'Notifications',
    'no_notifications': 'No notifications yet.',
    'mark_read': 'Mark all read',
    'department': 'Department',
    'assign_dept': 'Assign Department',
    'assigned_to': 'Assigned to',
    'status_pending': 'Pending',
    'status_assigned': 'Assigned',
    'status_inprogress': 'In Progress',
    'status_resolved': 'Resolved',
    'status_rejected': 'Rejected',
    'ward': 'Ward',
    'ward_intelligence': 'Ward Intelligence',
    'all_wards': 'All Wards',
    'transport_status': 'Transport Status',
    'status_requested': 'Requested',
    'status_confirmed': 'Confirmed',
    'status_scheduled': 'Scheduled',
    'status_pickedup': 'Picked Up',
    'pickup_location': 'Pickup Location',
    'select_crop': 'Select Crop',
    'my_logistics': 'My Logistics',
    'no_logistics': 'No logistics requests yet.',
    'warehouse_mgmt': 'Warehouse Management',
    'capacity': 'Capacity',
    'accept': 'Accept',
    'schedule_pickup': 'Schedule Pickup',
    'pickup_scheduled': 'Pickup scheduled successfully!',
    'logistics_accepted': 'Logistics request accepted!',
  },
  'ta': {
    'app_name': 'ஒன் ஸ்மார்ட் எரா',
    'subtitle': 'குடிமக்கள், விவசாயிகள் மற்றும் நிர்வாகம்',
    'role_public': 'பொது மக்கள்',
    'role_farmer': 'விவசாயி',
    'role_admin': 'நிர்வாகி',
    'login': 'உள்நுழைய',
    'phone': 'தொலைபேசி எண்',
    'otp': 'OTP / குறியீடு',
    'home': 'முகப்பு',
    'map': 'வரைபடம்',
    'report': 'புகார்',
    'profile': 'சுயவிவரம்',
    'market': 'சந்தை',
    'doctor': 'பயிர் மருத்துவர்',
    'demand': 'தேவை',
    'update': 'விலை மாற்றம்',
    'dashboard': 'கட்டுப்பாட்டகம்',
    'assign': 'ஒதுக்கு',
    'analytics': 'பகுப்பாய்வு',
    'users': 'பயனர்கள்',
    'warehouse': 'கிடங்கு',
    'civic_points': 'குடிமக்கள் புள்ளிகள்',
    'hospitals': 'மருத்துவமனைகள்',
    'schemes': 'அரசு திட்டங்கள்',
    'rti': 'ஆர்டிஐ',
    'cm_cell': 'முதல்வர் தனிப்பிரிவு',
    'transport': 'போக்குவரத்து',
    'submit': 'புகார் சமர்ப்பி',
    'logout': 'வெளியேறு',
    'verify': 'சரிபார்',
    'surplus': 'உபரி சேர்',
    'welcome': 'நல்வரவு,',
    'essential_services': 'அத்தியாவசிய சேவைகள்',
    'report_issue': 'இங்கே புகார் செய்யவா?',
    'using_gps': 'தற்போதைய GPS',
    'start_report': 'புகார் தொடங்கு',
    'new_report': 'புதிய புகார்',
    'issue_category': 'புகார் வகை',
    'report_details': 'புகார் விவரங்கள்',
    'short_title': 'சிறு தலைப்பு',
    'provide_context': 'கூடுதல் விவரங்கள்...',
    'tap_scan': 'ஸ்கேன் செய்ய தொடவும்',
    'analyze_crop': 'பகுப்பாய்வு செய்',
    'diagnosis_treatment': 'நோயறிதல் மற்றும் சிகிச்சை',
    'snap_leaf': 'இலையை புகைப்படம் எடு',
    'logistics': 'தளவாடங்கள்',
    'micro_market': 'போக்குவரத்து தளவாடங்கள்',
    'connect_citizens': 'உங்கள் அறுவடையை சந்தைக்கு கொண்டு செல்ல அரசு மானிய டிரக்கை பதிவு செய்யவும்.',
    'command_center': 'கட்டுப்பாட்டு மையம்',
    'total': 'மொத்தம்',
    'pending': 'நிலுவையில்',
    'resolved': 'தீர்க்கப்பட்டது',
    'resolution_ratio': 'தீர்வு விகிதம்',
    'live_issues': 'நேரலை சிக்கல்கள்',
    'awaiting_action': 'காத்திருக்கிறது',
    'reject': 'நிராகரி',
    'resolve': 'தீர்க்க',
    'city_heatmap': 'நகர வெப்ப வரைபடம்',
    'high_density': 'அதிக அடர்த்தி பகுதிகள் உள்கட்டமைப்பு தோல்வியைக் குறிக்கின்றன.',
    'citizens_directory': 'குடிமக்கள் பட்டியல்',
    'edit': 'திருத்து',
    'save': 'மாற்றங்களைச் சேமி',
    'password': 'கடவுச்சொல்',
    'local_market': 'உள்ளூர் சந்தை',
    'no_internet': 'இணைய இணைப்பு இல்லை.',
    'fill_all_fields': 'தேவையான அனைத்து தகவல்களையும் நிரப்பவும்.',
    'invalid_phone': 'சரியான 10 இலக்க தொலைபேசி எண்ணை உள்ளிடவும்.',
    'invalid_credentials': 'தவறான தொலைபேசி எண் அல்லது கடவுச்சொல்.',
    'user_not_found': 'தொலைபேசி எண் கண்டுபிடிக்கப்படவில்லை.',
    'error_generic': 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.',
    'photo_optional': 'புகைப்படம் (விரும்பினால்)',
    'location': 'இடம்',
    'submitting': 'சமர்ப்பிக்கிறது...',
    'loading': 'ஏற்றுகிறது...',
    'analyzing': 'பகுப்பாய்வு செய்கிறது...',
    'booking_transport': 'போக்குவரத்து பதிவு செய்',
    'load_weight': 'மதிப்பிடப்பட்ட சுமை எடை (கிலோ)',
    'truck_assigned': 'போக்குவரத்து கோரிக்கை சமர்ப்பிக்கப்பட்டது!',
    'confirm_booking': 'பதிவை உறுதிப்படுத்து',
    'retrieve_password': 'கடவுச்சொல் மீட்டெடு',
    'get_password': 'கடவுச்சொல் பெறு',
    'forgot_password': 'கடவுச்சொல் மறந்துவிட்டதா?',
    'already_account': 'ஏற்கனவே கணக்கு இருக்கா? உள்நுழைய',
    'new_citizen': 'புதிய குடிமகன்? சுயவிவரம் பதிவு செய்',
    'register': 'பதிவு செய்',
    'registration_success': 'பதிவு வெற்றிகரமானது! +100 புள்ளிகள்',
    'full_name': 'முழு பெயர்',
    'city_village': 'நகர/கிராம முகவரி',
    'email_optional': 'மின்னஞ்சல் (விரும்பினால்)',
    'delete_citizen': 'குடிமகனை நீக்கவா?',
    'delete_confirm': 'இது பயனரை தரவுத்தளத்திலிருந்து நிரந்தரமாக அகற்றும்.',
    'cancel': 'ரத்து செய்',
    'delete': 'நீக்கு',
    'delete_success': 'பயனர் வெற்றிகரமாக நீக்கப்பட்டார்.',
    'all_resolved': 'அனைத்தும் தீர்க்கப்பட்டது! 🎉',
    'zero_issues': 'புகார்கள் எதுவும் இல்லை',
    'zero_desc': 'குடிமக்கள் புதிய புகார்களை சமர்ப்பிக்கும் வரை காத்திருக்கிறோம்.',
    'edit_profile': 'சுயவிவரம் திருத்து',
    'name': 'பெயர்',
    'no_firebase': 'நேரடி பயனர் பட்டியலுக்கு Firebase தேவை.',
    'add_title': 'புகாருக்கு ஒரு தலைப்பு சேர்க்கவும்.',
    'report_submitted': 'புகார் சமர்ப்பிக்கப்பட்டது! நிர்வாகி ஆய்வுக்காக காத்திருக்கிறது.',
    'location_unavailable': 'இருப்பிட சேவை கிடைக்கவில்லை.',
    'my_reports': 'என் புகார்கள்',
    'no_reports': 'இன்னும் புகார்கள் சமர்ப்பிக்கப்படவில்லை.',
    'price_alert': 'விலை எச்சரிக்கை',
    'alert_on': 'எச்சரிக்கை அமைக்கப்பட்டது!',
    'alert_off': 'எச்சரிக்கை அகற்றப்பட்டது.',
    'set_alert': 'எச்சரிக்கை அமை',
    'crop_history': 'நோயறிதல் வரலாறு',
    'clear_history': 'வரலாறை அழி',
    'nearest_mandi': 'அருகிலுள்ள மண்டி',
    'agmarknet_source': 'மூலம்: Agmarknet (முன்மாதிரி தரவு)',
    'local_prices': 'உங்கள் பகுதியில் விலைகள்',
    'notifications': 'அறிவிப்புகள்',
    'no_notifications': 'அறிவிப்புகள் இல்லை.',
    'mark_read': 'அனைத்தும் படிக்கப்பட்டதாக குறி',
    'department': 'துறை',
    'assign_dept': 'துறையை ஒதுக்கு',
    'assigned_to': 'ஒதுக்கப்பட்டது',
    'status_pending': 'நிலுவையில்',
    'status_assigned': 'ஒதுக்கப்பட்டது',
    'status_inprogress': 'செயல்பாட்டில்',
    'status_resolved': 'தீர்க்கப்பட்டது',
    'status_rejected': 'நிராகரிக்கப்பட்டது',
    'ward': 'வார்டு',
    'ward_intelligence': 'வார்டு நுண்ணறிவு',
    'all_wards': 'அனைத்து வார்டுகள்',
    'transport_status': 'போக்குவரத்து நிலை',
    'status_requested': 'கோரப்பட்டது',
    'status_confirmed': 'உறுதிப்படுத்தப்பட்டது',
    'status_scheduled': 'திட்டமிடப்பட்டது',
    'status_pickedup': 'எடுக்கப்பட்டது',
    'pickup_location': 'எடுக்கும் இடம்',
    'select_crop': 'பயிரைத் தேர்ந்தெடு',
    'my_logistics': 'என் போக்குவரத்து',
    'no_logistics': 'போக்குவரத்து கோரிக்கைகள் இல்லை.',
    'warehouse_mgmt': 'கிடங்கு மேலாண்மை',
    'capacity': 'கொள்ளளவு',
    'accept': 'ஏற்கு',
    'schedule_pickup': 'எடுக்கும் நேரம் நிர்ணயி',
    'pickup_scheduled': 'எடுக்கும் நேரம் நிர்ணயிக்கப்பட்டது!',
    'logistics_accepted': 'போக்குவரத்து கோரிக்கை ஏற்கப்பட்டது!',
  }
};

// ==========================================
// MODELS
// ==========================================
class AppUser {
  final String uid;
  final String role;
  String name;
  String phone;
  String address;
  String email;
  String password;
  int civicPoints;

  AppUser({
    required this.uid, required this.role, required this.name, required this.phone,
    required this.address, required this.email, required this.password, this.civicPoints = 0,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid, 'role': role, 'name': name, 'phone': phone,
    'address': address, 'email': email, 'password': password, 'civicPoints': civicPoints,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] ?? '', role: map['role'] ?? 'Public', name: map['name'] ?? 'Citizen',
    phone: map['phone'] ?? '', address: map['address'] ?? '', email: map['email'] ?? '',
    password: map['password'] ?? '', civicPoints: map['civicPoints'] ?? 0,
  );
}

class CivicReport {
  final String id;
  final String userId;
  final String title;
  final String desc;
  final String category;
  final LatLng loc;
  final String? address;
  final String? imagePath;
  String status; // Pending → Assigned → In Progress → Resolved | Rejected
  String? department;
  String? wardId;
  String? wardName;
  DateTime? assignedAt;

  CivicReport({
    required this.id, required this.userId, required this.title, required this.desc,
    required this.category, required this.loc, this.address, this.imagePath,
    this.status = 'Pending', this.department, this.wardId, this.wardName, this.assignedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'title': title, 'desc': desc, 'category': category,
    'lat': loc.latitude, 'lng': loc.longitude, 'address': address, 'status': status,
    'department': department, 'wardId': wardId, 'wardName': wardName,
    'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
  };
}

class CropItem {
  final String name;
  final double currentPrice;
  final double predictedPrice;
  final String demand;
  CropItem(this.name, this.currentPrice, this.predictedPrice, this.demand);
}

class DiagnosisEntry {
  final String imagePath;
  final String diagnosis;
  final DateTime timestamp;
  DiagnosisEntry({required this.imagePath, required this.diagnosis, required this.timestamp});
}

// Firestore schema: logistics_requests/{id}
class LogisticsRequest {
  final String id;
  final String farmerId;
  final String farmerName;
  final String crop;
  final double weightKg;
  final String pickupAddress;
  final LatLng pickupLoc;
  final String? warehouseId;
  String status; // Requested → Confirmed → Scheduled → Picked Up
  String? scheduledTime;

  LogisticsRequest({
    required this.id, required this.farmerId, required this.farmerName,
    required this.crop, required this.weightKg, required this.pickupAddress,
    required this.pickupLoc, this.warehouseId,
    this.status = 'Requested', this.scheduledTime,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'farmerId': farmerId, 'farmerName': farmerName, 'crop': crop,
    'weightKg': weightKg, 'pickupAddress': pickupAddress,
    'pickupLat': pickupLoc.latitude, 'pickupLng': pickupLoc.longitude,
    'warehouseId': warehouseId, 'status': status, 'scheduledTime': scheduledTime,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory LogisticsRequest.fromMap(Map<String, dynamic> map) => LogisticsRequest(
    id: map['id'] ?? '', farmerId: map['farmerId'] ?? '', farmerName: map['farmerName'] ?? '',
    crop: map['crop'] ?? '', weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
    pickupAddress: map['pickupAddress'] ?? '', 
    pickupLoc: LatLng((map['pickupLat'] as num?)?.toDouble() ?? 0, (map['pickupLng'] as num?)?.toDouble() ?? 0),
    warehouseId: map['warehouseId'], status: map['status'] ?? 'Requested', scheduledTime: map['scheduledTime'],
  );
}

// In-app notification (Firestore: notifications/{id})
class AppNotification {
  final String id;
  final String targetUid; // 'admin' or specific uid
  final String title;
  final String body;
  final String type; // report_accepted, report_resolved, logistics_confirmed, etc.
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id, required this.targetUid, required this.title,
    required this.body, required this.type, this.isRead = false, required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'targetUid': targetUid, 'title': title, 'body': body,
    'type': type, 'isRead': isRead, 'createdAt': Timestamp.fromDate(createdAt),
  };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] ?? '', targetUid: map['targetUid'] ?? '', title: map['title'] ?? '',
    body: map['body'] ?? '', type: map['type'] ?? '', isRead: map['isRead'] ?? false,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

// ==========================================
// STATE MANAGEMENT
// ==========================================
class AppState extends ChangeNotifier {
  String lang = 'en';
  String t(String k) => i18n[lang]?[k] ?? i18n['en']?[k] ?? k;
  void toggleLang() { lang = lang == 'en' ? 'ta' : 'en'; notifyListeners(); }

  AppUser? currentUser;
  int navIndex = 0;
  LatLng userLocation = const LatLng(11.5034, 77.2387);
  LatLng? reportDraftLocation;
  String reportDraftAddress = '';

  String weatherTemp = '--°C';
  String weatherDesc = 'Loading...';
  IconData weatherIcon = Icons.cloud;
  bool weatherLoading = false;

  final List<DiagnosisEntry> diagnosisHistory = [];
  final Map<String, bool> priceAlerts = {};
  String detectedDistrict = 'Default';

  // In-app notifications (local list, synced with Firestore)
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  StreamSubscription<QuerySnapshot>? _notifStream;

  void login(AppUser user) {
    currentUser = user;
    navIndex = 0;
    _fetchWeather();
    _detectDistrict();
    _listenToNotifications();
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    navIndex = 0;
    reportDraftLocation = null;
    reportDraftAddress = '';
    diagnosisHistory.clear();
    priceAlerts.clear();
    _notifications.clear();
    _notifStream?.cancel();
    notifyListeners();
  }

  void setNav(int i) {
    HapticFeedback.selectionClick();
    navIndex = i;
    notifyListeners();
  }

  void addPoints(int p) {
    if (currentUser != null) {
      currentUser!.civicPoints += p;
      notifyListeners();
      _syncPointsToFirestore();
    }
  }

  void _syncPointsToFirestore() {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance.collection('users').doc(currentUser!.uid)
            .update({'civicPoints': currentUser!.civicPoints});
      }
    } catch (e) { debugPrint('Points sync failed: $e'); }
  }

  void updateLocation(LatLng l) { userLocation = l; notifyListeners(); }
  void togglePriceAlert(String cropName) {
    priceAlerts[cropName] = !(priceAlerts[cropName] ?? false);
    notifyListeners();
  }

  void addDiagnosis(DiagnosisEntry entry) {
    diagnosisHistory.insert(0, entry);
    if (diagnosisHistory.length > 3) diagnosisHistory.removeLast();
    notifyListeners();
  }

  void clearDiagnosisHistory() { diagnosisHistory.clear(); notifyListeners(); }

  void markAllNotificationsRead() {
    for (final n in _notifications) { n.isRead = true; }
    notifyListeners();
    if (Firebase.apps.isNotEmpty && currentUser != null) {
      for (final n in _notifications) {
        try {
          FirebaseFirestore.instance.collection('notifications').doc(n.id)
              .update({'isRead': true});
        } catch (_) {}
      }
    }
  }

  void _listenToNotifications() {
    if (currentUser == null) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        final uid = currentUser!.uid;
        final role = currentUser!.role;
        final targetUids = [uid];
        if (role == 'Admin') targetUids.add('admin');
        _notifStream?.cancel();
        _notifStream = FirebaseFirestore.instance.collection('notifications')
            .where('targetUid', whereIn: targetUids)
            .orderBy('createdAt', descending: true)
            .limit(30)
            .snapshots()
            .listen((snap) {
          _notifications.clear();
          for (final doc in snap.docs) {
            try {
              _notifications.add(AppNotification.fromMap(doc.data()));
            } catch (_) {}
          }
          notifyListeners();
        });
      }
    } catch (e) { debugPrint('Notifications listener error: $e'); }
  }

  Future<void> _detectDistrict() async {
    try {
      final placemarks = await placemarkFromCoordinates(
        userLocation.latitude, userLocation.longitude,
      ).timeout(const Duration(seconds: 6));
      if (placemarks.isNotEmpty) {
        final subAdmin = placemarks.first.subAdministrativeArea ?? '';
        final locality = placemarks.first.locality ?? '';
        final candidate = subAdmin.isNotEmpty ? subAdmin : locality;
        if (_agmarknetData.containsKey(candidate)) {
          detectedDistrict = candidate;
        } else if (_mandiData.containsKey(candidate)) {
          detectedDistrict = candidate;
        }
      }
    } catch (_) { detectedDistrict = 'Default'; }
    notifyListeners();
  }

  Future<void> prepareReportAt(LatLng loc) async {
    reportDraftLocation = loc;
    reportDraftAddress = t('loading');
    notifyListeners();
    try {
      final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude)
          .timeout(const Duration(seconds: 8));
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [place.street, place.subLocality, place.locality]
            .where((s) => s != null && s.isNotEmpty).toList();
        reportDraftAddress = parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
      } else { reportDraftAddress = 'Unknown Location'; }
    } on TimeoutException { reportDraftAddress = 'Address unavailable (GPS only)';
    } catch (_) { reportDraftAddress = 'Address unavailable (GPS only)'; }
    notifyListeners();
  }

  Future<void> _fetchWeather() async {
    if (openWeatherApiKey.isEmpty || openWeatherApiKey == 'YOUR_OPENWEATHER_API_KEY') {
      weatherTemp = '32°C'; weatherDesc = 'Clear Sky'; weatherIcon = Icons.wb_sunny_rounded;
      notifyListeners(); return;
    }
    weatherLoading = true; notifyListeners();
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=${userLocation.latitude}&lon=${userLocation.longitude}&units=metric&appid=$openWeatherApiKey';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        weatherTemp = '${(data['main']['temp'] as num).round()}°C';
        weatherDesc = data['weather'][0]['main'] as String;
        weatherIcon = _weatherIcon(weatherDesc);
      } else { weatherTemp = '--°C'; weatherDesc = 'Unavailable'; weatherIcon = Icons.cloud_off_rounded; }
    } on TimeoutException { weatherTemp = '--°C'; weatherDesc = 'Timeout'; weatherIcon = Icons.cloud_off_rounded;
    } catch (_) { weatherTemp = '--°C'; weatherDesc = 'Error'; weatherIcon = Icons.cloud_off_rounded;
    } finally { weatherLoading = false; notifyListeners(); }
  }

  IconData _weatherIcon(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('clear')) return Icons.wb_sunny_rounded;
    if (d.contains('rain') || d.contains('drizzle')) return Icons.grain_rounded;
    if (d.contains('thunder')) return Icons.bolt_rounded;
    if (d.contains('snow')) return Icons.ac_unit_rounded;
    return Icons.cloud_rounded;
  }

  Map<String, dynamic> get reputationBadge {
    final pts = currentUser?.civicPoints ?? 0;
    if (pts > 500) return {'label': 'Gold', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFFFD700)};
    if (pts >= 200) return {'label': 'Silver', 'icon': Icons.military_tech_rounded, 'color': const Color(0xFFC0C0C0)};
    return {'label': 'Bronze', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFFCD7F32)};
  }
}

final appState = AppState();

/// Helper: send in-app notification
Future<void> sendNotification({
  required String targetUid, required String title, required String body, required String type,
}) async {
  try {
    if (Firebase.apps.isNotEmpty) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final notif = AppNotification(id: id, targetUid: targetUid, title: title, body: body, type: type, createdAt: DateTime.now());
      await FirebaseFirestore.instance.collection('notifications').doc(id).set(notif.toMap());
    }
  } catch (e) { debugPrint('Notification send error: $e'); }
}

/// Assign report to nearest mock ward based on location
String? _findNearestWard(LatLng loc) {
  String? nearestId;
  double minDist = double.infinity;
  for (final ward in _wardData) {
    final dLat = loc.latitude - (ward['center_lat'] as double);
    final dLng = loc.longitude - (ward['center_lng'] as double);
    final dist = math.sqrt(dLat * dLat + dLng * dLng);
    if (dist < minDist) { minDist = dist; nearestId = ward['id'] as String; }
  }
  return nearestId;
}

String? _wardNameFromId(String? id) {
  if (id == null) return null;
  try { return _wardData.firstWhere((w) => w['id'] == id)['name'] as String; } catch (_) { return null; }
}

class DataRepository extends ChangeNotifier {
  final List<CivicReport> _reports = [];
  final List<LogisticsRequest> _logistics = [];
  List<CropItem> crops = [
    CropItem('Tomato', 35.0, 38.0, 'High'),
    CropItem('Onion', 25.0, 22.0, 'Medium'),
    CropItem('Potato', 30.0, 32.0, 'High'),
    CropItem('Brinjal', 20.0, 24.0, 'High'),
    CropItem('Banana', 18.0, 17.0, 'Medium'),
  ];

  List<CivicReport> get reports => List.unmodifiable(_reports);
  List<LogisticsRequest> get logistics => List.unmodifiable(_logistics);



  DataRepository() { _listenToFirebaseReports(); _listenToLogistics(); }

  void _listenToFirebaseReports() {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance.collection('reports').snapshots().listen((snap) {
          _reports.clear();
          for (final doc in snap.docs) {
            final data = doc.data();
            try {
              final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
              final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
              _reports.add(CivicReport(
                id: data['id'] as String? ?? doc.id, userId: data['userId'] as String? ?? '',
                title: data['title'] as String? ?? 'Untitled', desc: data['desc'] as String? ?? '',
                category: data['category'] as String? ?? 'Other', loc: LatLng(lat, lng),
                address: data['address'] as String?, imagePath: data['imageUrl'] as String?,
                status: data['status'] as String? ?? 'Pending',
                department: data['department'] as String?,
                wardId: data['wardId'] as String?,
                wardName: data['wardName'] as String?,
                assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
              ));
            } catch (e) { debugPrint('Error parsing report ${doc.id}: $e'); }
          }
          notifyListeners();
        }, onError: (e) { debugPrint('Firestore listen error: $e'); });
      }
    } catch (e) { debugPrint('Firestore listener setup error: $e'); }
  }

  void _listenToLogistics() {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance.collection('logistics_requests')
            .orderBy('createdAt', descending: true).snapshots().listen((snap) {
          _logistics.clear();
          for (final doc in snap.docs) {
            try { _logistics.add(LogisticsRequest.fromMap(doc.data())); } catch (_) {}
          }
          notifyListeners();
        }, onError: (e) { debugPrint('Logistics listen error: $e'); });
      }
    } catch (e) { debugPrint('Logistics listener error: $e'); }
  }

  Future<bool> saveReport(CivicReport r, XFile? image) async {
    // Assign to nearest ward
    final wardId = _findNearestWard(r.loc);
    r.wardId = wardId;
    r.wardName = _wardNameFromId(wardId);
    _reports.add(r); notifyListeners();
    try {
      if (Firebase.apps.isNotEmpty) {
        String? imgUrl;
        if (image != null) imgUrl = await _uploadImage(r.id, image);
        await FirebaseFirestore.instance.collection('reports').doc(r.id)
            .set({...r.toMap(), 'imageUrl': imgUrl, 'createdAt': FieldValue.serverTimestamp()});
        // Notify admin of new report
        await sendNotification(
          targetUid: 'admin', title: 'New Issue Reported',
          body: '${r.category}: ${r.title}', type: 'new_report',
        );
      }
      return true;
    } catch (e) { debugPrint('Firebase Save Failed: $e'); return false; }
  }

  Future<String?> _uploadImage(String reportId, XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref('reports/$reportId.jpg');
      if (kIsWeb) { await ref.putData(await image.readAsBytes()); }
      else { await ref.putFile(io.File(image.path)); }
      return await ref.getDownloadURL();
    } catch (e) { debugPrint('Image Upload Failed: $e'); return null; }
  }

  /// Accept report → assign department → award citizen points → send notifications
  Future<void> acceptAndAssignReport(String id, String department) async {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = 'Assigned';
      _reports[index].department = department;
      _reports[index].assignedAt = DateTime.now();
      notifyListeners();
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance.collection('reports').doc(id).update({
            'status': 'Assigned', 'department': department,
            'assignedAt': FieldValue.serverTimestamp(),
          });
          // Award 50 points to citizen and notify
          final report = _reports[index];
          await FirebaseFirestore.instance.collection('users').doc(report.userId)
              .update({'civicPoints': FieldValue.increment(50)});
          await sendNotification(
            targetUid: report.userId,
            title: 'Report Accepted! +50 Points',
            body: 'Your report "${report.title}" has been accepted and assigned to $department.',
            type: 'report_accepted',
          );
        }
      } catch (e) { debugPrint('Accept report error: $e'); }
    }
  }

  Future<void> updateReportStatus(String id, String status) async {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = status; notifyListeners();
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance.collection('reports').doc(id).update({'status': status});
          if (status == 'Resolved') {
            final report = _reports[index];
            await sendNotification(
              targetUid: report.userId,
              title: 'Issue Resolved!',
              body: 'Your report "${report.title}" has been resolved.',
              type: 'report_resolved',
            );
          }
        }
      } catch (e) { debugPrint('Status update sync failed: $e'); }
    }
  }

  Future<bool> submitLogisticsRequest(LogisticsRequest req) async {
    _logistics.insert(0, req); notifyListeners();
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('logistics_requests').doc(req.id).set(req.toMap());
        await sendNotification(
          targetUid: 'admin', title: 'New Logistics Request',
          body: '${req.farmerName} requests pickup of ${req.weightKg}kg ${req.crop}',
          type: 'new_logistics',
        );
      }
      return true;
    } catch (e) { debugPrint('Logistics save error: $e'); return false; }
  }

  Future<void> updateLogisticsStatus(String id, String status, {String? scheduledTime}) async {
    final index = _logistics.indexWhere((l) => l.id == id);
    if (index != -1) {
      _logistics[index].status = status;
      if (scheduledTime != null) _logistics[index].scheduledTime = scheduledTime;
      notifyListeners();
      try {
        if (Firebase.apps.isNotEmpty) {
          final updates = <String, dynamic>{'status': status};
          if (scheduledTime != null) updates['scheduledTime'] = scheduledTime;
          await FirebaseFirestore.instance.collection('logistics_requests').doc(id).update(updates);
          final req = _logistics[index];
          String notifTitle = '', notifBody = '';
          if (status == 'Confirmed') {
            notifTitle = 'Logistics Confirmed!';
            notifBody = 'Your pickup for ${req.crop} has been confirmed.';
          } else if (status == 'Scheduled') {
            notifTitle = 'Pickup Scheduled!';
            notifBody = 'Pickup for ${req.crop} scheduled at ${scheduledTime ?? ''}';
          } else if (status == 'Picked Up') {
            notifTitle = 'Crop Picked Up!';
            notifBody = 'Your ${req.crop} has been picked up successfully.';
          }
          if (notifTitle.isNotEmpty) {
            await sendNotification(targetUid: req.farmerId, title: notifTitle, body: notifBody, type: 'logistics_update');
          }
        }
      } catch (e) { debugPrint('Logistics status update error: $e'); }
    }
  }

  void loadLocalCropData(String district) {
    final localData = _agmarknetData[district];
    if (localData != null && localData.isNotEmpty) {
      crops = localData.map((d) => CropItem(
        d['name'] as String, (d['price'] as num).toDouble(),
        (d['predicted'] as num).toDouble(), d['demand'] as String,
      )).toList();
      notifyListeners();
    }
  }
}

final repo = DataRepository();

// ==========================================
// APP ENTRY POINT
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('🔥 Firebase Connected Successfully!');
  } catch (e) { debugPrint('Firebase connection failed. Offline mode. Error: $e'); }
  runApp(const OneNationApp());
}

class OneNationApp extends StatelessWidget {
  const OneNationApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        return MaterialApp(
          title: 'One Smart Era',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true, colorSchemeSeed: const Color(0xFF2A9D8F),
            scaffoldBackgroundColor: Colors.transparent, fontFamily: 'Roboto',
            inputDecorationTheme: InputDecorationTheme(
              filled: true, fillColor: Colors.white.withValues(alpha: 0.8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          home: const Scaffold(body: Stack(children: [AnimatedMeshBackground(), RoleSelectionScreen()])),
        );
      },
    );
  }
}

// ==========================================
// ANIMATED BACKGROUND
// ==========================================
class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({super.key});
  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}
class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            stops: [0.0, 0.5 + (_controller.value * 0.2), 1.0],
            colors: [
              const Color(0xFFE9C46A).withValues(alpha: 0.3),
              const Color(0xFF2A9D8F).withValues(alpha: 0.2),
              const Color(0xFFF4A261).withValues(alpha: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SHARED WIDGETS
// ==========================================
class DeepGlassCard extends StatelessWidget {
  final Widget child; final double padding; final double borderRadius;
  final Color? color; final BoxBorder? border;
  const DeepGlassCard({super.key, required this.child, this.padding = 24.0,
      this.borderRadius = 24.0, this.color, this.border});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: child,
        ),
      ),
    );
  }
}

class TappableGlassCard extends StatefulWidget {
  final Widget child; final VoidCallback? onTap; final double padding; final double borderRadius;
  final Color? color; final BoxBorder? border;
  const TappableGlassCard({super.key, required this.child, this.onTap, this.padding = 24.0,
      this.borderRadius = 24.0, this.color, this.border});
  @override
  State<TappableGlassCard> createState() => _TappableGlassCardState();
}
class _TappableGlassCardState extends State<TappableGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: DeepGlassCard(padding: widget.padding, borderRadius: widget.borderRadius,
            color: widget.color, border: widget.border, child: widget.child),
      ),
    );
  }
}

void showMessage(BuildContext context, String message, {bool isError = false}) {
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: isError ? const Color(0xFFE76F51) : const Color(0xFF264653),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.all(20), elevation: 10,
    duration: const Duration(seconds: 3),
    content: Row(children: [
      Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
      const SizedBox(width: 12),
      Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
    ]),
  ));
}

class AnimatedCounterText extends StatefulWidget {
  final int value; final TextStyle style;
  const AnimatedCounterText({super.key, required this.value, required this.style});
  @override
  State<AnimatedCounterText> createState() => _AnimatedCounterTextState();
}
class _AnimatedCounterTextState extends State<AnimatedCounterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }
  @override
  void didUpdateWidget(AnimatedCounterText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = IntTween(begin: old.value, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _anim, builder: (_, __) => Text(_anim.value.toString(), style: widget.style));
  }
}

class ShimmerBox extends StatefulWidget {
  final double width; final double height; final double borderRadius;
  const ShimmerBox({super.key, this.width = double.infinity, this.height = 20, this.borderRadius = 8});
  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}
class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0), end: Alignment(_anim.value + 1, 0),
            colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.2)],
          ),
        ),
      ),
    );
  }
}

class StaggeredEntrance extends StatefulWidget {
  final Widget child; final int index; final int delayMs;
  const StaggeredEntrance({super.key, required this.child, required this.index, this.delayMs = 80});
  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}
class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity, _slide;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: Offset(0, _slide.value), child: child),
      ),
      child: widget.child,
    );
  }
}

class RevealCard extends StatefulWidget {
  final Widget child;
  const RevealCard({super.key, required this.child});
  @override
  State<RevealCard> createState() => _RevealCardState();
}
class _RevealCardState extends State<RevealCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
  }
}

// ==========================================
// AUTH CHARACTER
// ==========================================
class _AuthCharacter extends StatefulWidget {
  final bool isTyping; final bool isPasswordVisible; final bool isLoading;
  const _AuthCharacter({required this.isTyping, required this.isPasswordVisible, required this.isLoading});
  @override
  State<_AuthCharacter> createState() => _AuthCharacterState();
}
class _AuthCharacterState extends State<_AuthCharacter> with TickerProviderStateMixin {
  late AnimationController _wobble, _blink, _bounce;
  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat(reverse: true);
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }
  @override
  void didUpdateWidget(_AuthCharacter old) {
    super.didUpdateWidget(old);
    if (widget.isPasswordVisible && !old.isPasswordVisible) {
      _blink.forward(from: 0).then((_) => _blink.reverse());
    }
  }
  @override
  void dispose() { _wobble.dispose(); _blink.dispose(); _bounce.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_wobble, _blink, _bounce]),
      builder: (_, __) {
        final wobbleVal = widget.isLoading ? math.sin(_wobble.value * math.pi) * 6 : 0.0;
        final bounceVal = widget.isTyping ? math.sin(_bounce.value * math.pi) * 4 : 0.0;
        return Transform.translate(
          offset: Offset(wobbleVal, bounceVal),
          child: SizedBox(
            height: 90,
            child: Stack(alignment: Alignment.center, children: [
              Container(width: 70, height: 70,
                decoration: BoxDecoration(color: const Color(0xFF2A9D8F), shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF2A9D8F).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))])),
              Positioned(top: 18, child: Row(mainAxisSize: MainAxisSize.min, children: [
                _Eye(covered: !widget.isPasswordVisible && !widget.isTyping, blinking: _blink.value > 0.3),
                const SizedBox(width: 14),
                _Eye(covered: !widget.isPasswordVisible && !widget.isTyping, blinking: _blink.value > 0.3),
              ])),
              Positioned(bottom: 16, child: widget.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Container(width: 24, height: 10, decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 3)),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))))),
              if (widget.isTyping) ..._buildOrbitDots(),
            ]),
          ),
        );
      },
    );
  }
  List<Widget> _buildOrbitDots() => List.generate(3, (i) => Positioned(
    top: 5 + (i * 15.0), right: 2.0,
    child: Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFFE9C46A).withValues(alpha: 0.8 - i * 0.2), shape: BoxShape.circle)),
  ));
}

class _Eye extends StatelessWidget {
  final bool covered; final bool blinking;
  const _Eye({required this.covered, required this.blinking});
  @override
  Widget build(BuildContext context) {
    if (covered) return Container(width: 14, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)));
    if (blinking) return Container(width: 10, height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)));
    return Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF264653), shape: BoxShape.circle))));
  }
}

// ==========================================
// AUTHENTICATION FLOW
// ==========================================
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}
class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _selectRole(BuildContext context, String role) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      body: Stack(children: [const AnimatedMeshBackground(), AuthScreen(role: role)]),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide,
      child: Stack(children: [
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(padding: const EdgeInsets.all(24.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.hub_rounded, size: 100, color: Color(0xFF264653)),
              const SizedBox(height: 16),
              AnimatedBuilder(animation: appState, builder: (context, _) => Column(children: [
                Text(appState.t('app_name'), textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF264653), letterSpacing: -1)),
                Text(appState.t('subtitle'), textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
              ])),
              const SizedBox(height: 60),
              AnimatedBuilder(animation: appState, builder: (context, _) => Column(children: [
                StaggeredEntrance(index: 0, child: _RoleBtn(icon: Icons.person_rounded, label: appState.t('role_public'), onTap: () => _selectRole(context, 'Public'))),
                const SizedBox(height: 20),
                StaggeredEntrance(index: 1, child: _RoleBtn(icon: Icons.agriculture_rounded, label: appState.t('role_farmer'), onTap: () => _selectRole(context, 'Farmer'))),
                const SizedBox(height: 20),
                StaggeredEntrance(index: 2, child: _RoleBtn(icon: Icons.admin_panel_settings_rounded, label: appState.t('role_admin'), onTap: () => _selectRole(context, 'Admin'))),
              ])),
            ]),
          ),
        )),
        Positioned(top: 16, right: 16, child: AnimatedBuilder(animation: appState, builder: (context, _) => ActionChip(
          elevation: 5, shadowColor: Colors.black.withValues(alpha: 0.2),
          backgroundColor: Colors.white.withValues(alpha: 0.9), side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          avatar: const Icon(Icons.language_rounded, color: Color(0xFF2A9D8F), size: 20),
          label: Text(appState.lang == 'en' ? 'தமிழ்' : 'English',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF264653))),
          onPressed: () { HapticFeedback.mediumImpact(); appState.toggleLang(); },
        ))),
      ]),
    )));
  }
}

class _RoleBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _RoleBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return TappableGlassCard(padding: 16, onTap: onTap,
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: const Color(0xFF264653), size: 28)),
        const SizedBox(width: 20),
        Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.black54),
      ]),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  bool _isRegistering = false;
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isPasswordVisible = false;
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() => setState(() => _isTyping = _phoneCtrl.text.isNotEmpty));
  }
  @override
  void dispose() {
    _phoneCtrl.dispose(); _passCtrl.dispose(); _nameCtrl.dispose(); _addressCtrl.dispose(); _emailCtrl.dispose(); super.dispose();
  }

  bool _isValidPhone(String phone) => RegExp(r'^\d{10}$').hasMatch(phone.trim());

  bool _validateInputs() {
    if (widget.role == 'Admin') {
      if (_passCtrl.text.trim().isEmpty) { showMessage(context, appState.t('fill_all_fields'), isError: true); return false; }
      return true;
    }
    if (!_isValidPhone(_phoneCtrl.text)) { showMessage(context, appState.t('invalid_phone'), isError: true); return false; }
    if (_passCtrl.text.trim().isEmpty) { showMessage(context, appState.t('fill_all_fields'), isError: true); return false; }
    if (_isRegistering && (_nameCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty)) {
      showMessage(context, appState.t('fill_all_fields'), isError: true); return false;
    }
    return true;
  }

  void _authenticate() async {
    if (!_validateInputs()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    if (widget.role == 'Admin') {
      if (_passCtrl.text.trim() == adminMasterCode) {
        appState.login(AppUser(uid: 'admin_1', role: 'Admin', name: 'Master Admin', phone: '000', address: 'HQ', email: 'admin@gov.in', password: adminMasterCode));
        if (!mounted) return;
        _navigateHome();
      } else {
        if (!mounted) return;
        showMessage(context, 'Access Denied. Invalid Admin Code.', isError: true);
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        final db = FirebaseFirestore.instance;
        final docRef = db.collection('users').doc(_phoneCtrl.text.trim());
        if (_isRegistering) {
          final existing = await docRef.get();
          if (existing.exists && mounted) {
            showMessage(context, 'Phone number already registered. Please login.', isError: true);
            setState(() => _isLoading = false); return;
          }
          final userMap = {
            'uid': _phoneCtrl.text.trim(), 'role': widget.role, 'name': _nameCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(), 'address': _addressCtrl.text.trim(),
            'email': _emailCtrl.text.trim(), 'password': _passCtrl.text.trim(),
            'civicPoints': 100, 'createdAt': FieldValue.serverTimestamp(),
          };
          await docRef.set(userMap);
          final newDoc = await docRef.get();
          final loginMap = newDoc.data() ?? userMap;
          appState.login(AppUser.fromMap({...userMap, ...loginMap}));
          if (!mounted) return;
          showMessage(context, appState.t('registration_success'));
          _navigateHome();
        } else {
          final docSnap = await docRef.get();
          if (!docSnap.exists) {
            if (!mounted) return;
            showMessage(context, appState.t('user_not_found'), isError: true);
            setState(() => _isLoading = false); return;
          }
          final data = docSnap.data()!;
          final passwordMatch = (data['password'] as String? ?? '') == _passCtrl.text.trim() || _passCtrl.text.trim() == adminMasterCode;
          final roleMatch = (data['role'] as String? ?? '') == widget.role;
          if (passwordMatch && roleMatch) {
            appState.login(AppUser.fromMap(data));
            if (!mounted) return;
            showMessage(context, '${appState.t('welcome')} ${appState.currentUser!.name}');
            _navigateHome();
          } else {
            if (!mounted) return;
            showMessage(context, appState.t('invalid_credentials'), isError: true);
            setState(() => _isLoading = false);
          }
        }
      } else {
        appState.login(AppUser(uid: 'mock_${DateTime.now().millisecondsSinceEpoch}', role: widget.role,
            name: _isRegistering ? _nameCtrl.text.trim() : 'Demo User', phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passCtrl.text.trim(), civicPoints: 500));
        if (!mounted) return;
        _navigateHome();
      }
    } catch (e) {
      debugPrint('Auth error: $e');
      if (!mounted) return;
      showMessage(context, appState.t('error_generic'), isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    HapticFeedback.lightImpact();
    final recCtrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.transparent, contentPadding: EdgeInsets.zero,
      content: RevealCard(child: DeepGlassCard(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.lock_reset_rounded, size: 40, color: Color(0xFF2A9D8F)),
        const SizedBox(height: 16),
        Text(appState.t('retrieve_password'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF264653)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextField(controller: recCtrl, keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: appState.t('phone'), prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF2A9D8F)))),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF264653), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            final phone = recCtrl.text.trim();
            if (phone.isEmpty) return;
            if (Firebase.apps.isNotEmpty) {
              try {
                final doc = await FirebaseFirestore.instance.collection('users').doc(phone).get();
                if (!context.mounted) return;
                Navigator.pop(context);
                if (doc.exists) { showMessage(context, 'Your Password is: ${doc.data()?['password']}'); }
                else { showMessage(context, appState.t('user_not_found'), isError: true); }
              } catch (e) { if (!context.mounted) return; Navigator.pop(context); showMessage(context, appState.t('error_generic'), isError: true); }
            } else { Navigator.pop(context); showMessage(context, 'Firebase not available in demo mode.', isError: true); }
          },
          child: Text(appState.t('get_password')),
        )
      ]))),
    ));
  }

  void _navigateHome() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Scaffold(
      body: Stack(children: [AnimatedMeshBackground(), MainNavigationShell()]),
    )), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'Admin';
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(padding: const EdgeInsets.all(32),
          child: Column(children: [
            _AuthCharacter(isTyping: _isTyping, isPasswordVisible: _isPasswordVisible, isLoading: _isLoading),
            const SizedBox(height: 16),
            DeepGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Icon(isAdmin ? Icons.admin_panel_settings_rounded : (_isRegistering ? Icons.person_add_rounded : Icons.login_rounded), size: 48, color: const Color(0xFF2A9D8F)),
              const SizedBox(height: 12),
              Text(isAdmin ? appState.t('command_center') : (_isRegistering ? 'Create Profile' : appState.t('login')),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF264653)), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              if (!isAdmin && _isRegistering) ...[
                _AuthField(controller: _nameCtrl, label: appState.t('full_name'), icon: Icons.badge_rounded),
                _AuthField(controller: _addressCtrl, label: appState.t('city_village'), icon: Icons.home_rounded),
                _AuthField(controller: _emailCtrl, label: appState.t('email_optional'), icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
              ],
              if (!isAdmin) _AuthField(controller: _phoneCtrl, label: appState.t('phone'), icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
              _AuthField(controller: _passCtrl, label: isAdmin ? appState.t('otp') : appState.t('password'),
                  icon: Icons.lock_rounded, isObscure: true, onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
              const SizedBox(height: 28),
              SizedBox(height: 60, child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF264653), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5),
                onPressed: _isLoading ? null : _authenticate,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(isAdmin ? appState.t('login') : (_isRegistering ? appState.t('register') : appState.t('login')),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              )),
              if (!isAdmin) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: () { HapticFeedback.selectionClick(); setState(() => _isRegistering = !_isRegistering); },
                    child: Text(_isRegistering ? appState.t('already_account') : appState.t('new_citizen'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A9D8F), fontSize: 15))),
                if (!_isRegistering) TextButton(onPressed: _showForgotPassword,
                    child: Text(appState.t('forgot_password'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
              ]
            ])),
          ]),
        ),
      )),
    );
  }
}

class _AuthField extends StatefulWidget {
  final TextEditingController controller; final String label; final IconData icon;
  final bool isObscure; final TextInputType keyboardType; final VoidCallback? onVisibilityToggle;
  const _AuthField({required this.controller, required this.label, required this.icon,
      this.isObscure = false, this.keyboardType = TextInputType.text, this.onVisibilityToggle});
  @override
  State<_AuthField> createState() => _AuthFieldState();
}
class _AuthFieldState extends State<_AuthField> {
  bool _obscured = true;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: widget.controller, obscureText: widget.isObscure && _obscured,
        keyboardType: widget.keyboardType, style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: widget.label, prefixIcon: Icon(widget.icon, color: const Color(0xFF2A9D8F)),
          suffixIcon: widget.isObscure ? IconButton(
            icon: Icon(_obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.black45),
            onPressed: () { setState(() => _obscured = !_obscured); widget.onVisibilityToggle?.call(); },
          ) : null,
        ),
      ),
    );
  }
}

// ==========================================
// MAIN NAVIGATION SHELL
// ==========================================
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final role = appState.currentUser?.role ?? 'Public';
        List<Widget> pages = []; List<IconData> icons = [];

        if (role == 'Public') {
          pages = [const PublicHomeScreen(), const PublicMapScreen(), const PublicReportScreen(), const MyReportsScreen(), const ProfileScreen()];
          icons = [Icons.home_rounded, Icons.map_rounded, Icons.add_a_photo_rounded, Icons.history_rounded, Icons.person_rounded];
        } else if (role == 'Farmer') {
          pages = [const FarmerMarketScreen(), const CropDoctorScreen(), const FarmerDemandScreen(), const ProfileScreen()];
          icons = [Icons.storefront_rounded, Icons.eco_rounded, Icons.local_shipping_rounded, Icons.person_rounded];
        } else {
          pages = [const AdminDashboardScreen(), const AdminAssignScreen(), const AdminAnalyticsScreen(), const AdminUsersScreen(), const AdminWarehouseScreen(), const ProfileScreen()];
          icons = [Icons.dashboard_rounded, Icons.assignment_rounded, Icons.map_rounded, Icons.people_rounded, Icons.warehouse_rounded, Icons.person_rounded];
        }

        final safeIndex = appState.navIndex.clamp(0, pages.length - 1);
        if (appState.navIndex != safeIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) => appState.setNav(safeIndex));
        }

        return Stack(
          children: [
            IndexedStack(index: safeIndex, children: pages),
            Align(alignment: Alignment.bottomCenter,
                child: _DeepGlassBottomNav(icons: icons, currentIndex: safeIndex, onTap: appState.setNav)),
          ],
        );
      },
    );
  }
}

class _DeepGlassBottomNav extends StatefulWidget {
  final List<IconData> icons; final int currentIndex; final ValueChanged<int> onTap;
  const _DeepGlassBottomNav({required this.icons, required this.currentIndex, required this.onTap});
  @override
  State<_DeepGlassBottomNav> createState() => _DeepGlassBottomNavState();
}
class _DeepGlassBottomNavState extends State<_DeepGlassBottomNav> {
  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    final navWidth = math.min(MediaQuery.of(context).size.width - 48, 500.0);
    final itemWidth = navWidth / widget.icons.length;

    return SafeArea(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: navWidth, margin: const EdgeInsets.only(bottom: 24), height: 75,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                  ),
                  child: Stack(children: [
                    AnimatedPositioned(duration: const Duration(milliseconds: 350), curve: Curves.easeOutBack,
                        left: widget.currentIndex * itemWidth, top: 0, bottom: 0, width: itemWidth,
                        child: Container(margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: const Color(0xFF2A9D8F).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]))),
                    AnimatedPositioned(duration: const Duration(milliseconds: 350), curve: Curves.easeOutBack,
                        left: widget.currentIndex * itemWidth, top: 0, bottom: 0, width: itemWidth,
                        child: Container(margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(34),
                                gradient: RadialGradient(colors: [const Color(0xFF2A9D8F).withValues(alpha: 0.12), Colors.transparent])))),
                    Row(children: List.generate(widget.icons.length, (index) {
                      final isSelected = index == widget.currentIndex;
                      final isTapped = _tappedIndex == index;
                      return Expanded(child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => setState(() => _tappedIndex = index),
                        onTapUp: (_) { setState(() => _tappedIndex = null); widget.onTap(index); },
                        onTapCancel: () => setState(() => _tappedIndex = null),
                        child: Center(child: AnimatedScale(
                          scale: isTapped ? 0.85 : (isSelected ? 1.05 : 1.0),
                          duration: const Duration(milliseconds: 150),
                          child: Icon(widget.icons[index], color: isSelected ? const Color(0xFF264653) : Colors.black45, size: isSelected ? 30 : 24),
                        )),
                      ));
                    })),
                  ]),
                ),
              ),
            ),
          ),
          // Notification badge for unread
          AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              if (appState.unreadCount == 0) return const SizedBox();
              return Positioned(
                bottom: 82, right: MediaQuery.of(context).size.width / 2 - navWidth / 2 + 16,
                child: GestureDetector(
                  onTap: () => _showNotifications(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('${appState.unreadCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, ctrl) => RevealCard(child: DeepGlassCard(borderRadius: 30,
          child: Column(children: [
            Row(children: [
              Text(appState.t('notifications'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
              const Spacer(),
              TextButton(onPressed: () { appState.markAllNotificationsRead(); }, child: Text(appState.t('mark_read'), style: const TextStyle(color: Color(0xFF2A9D8F)))),
            ]),
            const SizedBox(height: 8),
            Expanded(child: AnimatedBuilder(animation: appState, builder: (_, __) {
              if (appState.notifications.isEmpty) {
                return Center(child: Text(appState.t('no_notifications'), style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)));
              }
              return ListView.builder(controller: ctrl, itemCount: appState.notifications.length,
                itemBuilder: (context, i) {
                  final n = appState.notifications[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: n.isRead ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF2A9D8F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: n.isRead ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF2A9D8F).withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(_notifIcon(n.type), color: const Color(0xFF2A9D8F), size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.bold : FontWeight.w900, fontSize: 14, color: const Color(0xFF264653))),
                          const SizedBox(height: 2),
                          Text(n.body, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ])),
                        if (!n.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2A9D8F), shape: BoxShape.circle)),
                      ]),
                    ),
                  );
                },
              );
            })),
          ]),
        )),
      ),
    );
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'report_accepted': return Icons.check_circle_rounded;
      case 'report_resolved': return Icons.done_all_rounded;
      case 'new_report': return Icons.report_rounded;
      case 'new_logistics': return Icons.local_shipping_rounded;
      case 'logistics_update': return Icons.airport_shuttle_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}

// ==========================================
// PUBLIC HOME SCREEN
// ==========================================
class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          StaggeredEntrance(index: 0, child: AnimatedBuilder(animation: appState, builder: (context, _) => TappableGlassCard(padding: 24,
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appState.t('welcome'), style: const TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(appState.currentUser?.name ?? '', style: const TextStyle(color: Color(0xFF264653), fontSize: 26, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: appState.weatherLoading
                    ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2))
                    : Column(children: [
                        Icon(appState.weatherIcon, color: const Color(0xFFE9C46A), size: 36),
                        const SizedBox(height: 4),
                        Text(appState.weatherTemp, style: const TextStyle(color: Color(0xFF264653), fontWeight: FontWeight.w900, fontSize: 18)),
                      ])),
            ]),
          ))),
          const SizedBox(height: 40),
          StaggeredEntrance(index: 1, child: AnimatedBuilder(animation: appState, builder: (context, _) =>
              Text(appState.t('essential_services'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF264653))))),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
            itemCount: 5,
            itemBuilder: (context, index) => StaggeredEntrance(index: index + 2, child: _buildPortalTile(context, index)),
          ),
          const SizedBox(height: 120),
        ]),
      ),
    )));
  }

  Widget _buildPortalTile(BuildContext context, int index) {
    final tiles = [
      _PortalTile(icon: Icons.local_hospital_rounded, label: appState.t('hospitals'), color: const Color(0xFFFFB5A7),
          // Fixed hospital URL to properly open Google Maps with hospitals near user location
          url: 'https://www.google.com/maps/search/hospitals+near+me'),
      _PortalTile(icon: Icons.article_rounded, label: appState.t('schemes'), color: const Color(0xFFA8DADC), url: 'https://www.myscheme.gov.in'),
      _PortalTile(icon: Icons.gavel_rounded, label: appState.t('rti'), color: const Color(0xFFF4A261), url: 'https://rtionline.gov.in'),
      _PortalTile(icon: Icons.directions_bus_rounded, label: appState.t('transport'), color: const Color(0xFFD4A373), url: 'https://www.tnstc.in'),
      _PortalTile(icon: Icons.contact_mail_rounded, label: appState.t('cm_cell'), color: const Color(0xFF81B29A), url: 'https://cmhelpline.tnega.org/'),
    ];
    return tiles[index];
  }
}

class _PortalTile extends StatelessWidget {
  final IconData icon; final String label; final Color color; final String url;
  const _PortalTile({required this.icon, required this.label, required this.color, required this.url});
  @override
  Widget build(BuildContext context) {
    return TappableGlassCard(padding: 0, onTap: () async {
        HapticFeedback.lightImpact();
        // For hospitals, use geo URI for Google Maps to show nearby results
        Uri uri;
        if (url.contains('hospitals')) {
          final lat = appState.userLocation.latitude;
          final lng = appState.userLocation.longitude;
          // Try geo URI first (Android), fallback to web URL
          uri = Uri.parse('geo:$lat,$lng?q=hospitals+near+me');
          if (!await canLaunchUrl(uri)) {
            uri = Uri.parse('https://www.google.com/maps/search/hospitals/@$lat,$lng,15z');
          }
        } else {
          uri = Uri.parse(url);
        }
        if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); }
        else if (context.mounted) { showMessage(context, 'Cannot open link. Please try manually.', isError: true); }
      },
      child: Container(decoration: BoxDecoration(color: color.withValues(alpha: 0.3)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Icon(icon, size: 32, color: const Color(0xFF264653))),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF264653)), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

// ==========================================
// MY REPORTS SCREEN (with status tracking)
// ==========================================
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Assigned': return Colors.blue;
      case 'In Progress': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Resolved': return Icons.done_all_rounded;
      case 'Rejected': return Icons.close_rounded;
      case 'Assigned': return Icons.assignment_rounded;
      case 'In Progress': return Icons.construction_rounded;
      default: return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('my_reports'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(animation: repo, builder: (context, _) {
        final uid = appState.currentUser?.uid ?? '';
        final myReports = repo.reports.where((r) => r.userId == uid).toList();
        if (myReports.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.inbox_rounded, size: 80, color: Colors.black26),
            const SizedBox(height: 16),
            AnimatedBuilder(animation: appState, builder: (_, __) =>
                Text(appState.t('no_reports'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black45))),
          ]));
        }
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
          child: ListView.builder(padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), itemCount: myReports.length,
            itemBuilder: (context, index) {
              final r = myReports[index];
              final statusColor = _statusColor(r.status);
              return StaggeredEntrance(index: index, child: Padding(padding: const EdgeInsets.only(bottom: 14),
                child: DeepGlassCard(padding: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(_statusIcon(r.status), color: statusColor, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF264653))),
                      const SizedBox(height: 4),
                      Text(r.category, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(r.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13))),
                  ]),
                  if (r.department != null) ...[
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.business_rounded, size: 14, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text('${appState.t('department')}: ${r.department}', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ],
                  if (r.wardName != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_city_rounded, size: 14, color: Colors.black45),
                      const SizedBox(width: 6),
                      Text(r.wardName!, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ])),
              ));
            },
          ),
        ));
      }),
    );
  }
}

// ==========================================
// PUBLIC MAP SCREEN
// ==========================================
class PublicMapScreen extends StatefulWidget {
  const PublicMapScreen({super.key});
  @override
  State<PublicMapScreen> createState() => _PublicMapScreenState();
}
class _PublicMapScreenState extends State<PublicMapScreen> with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLiveLocation;
  bool _locationPermissionDenied = false;
  late AnimationController _pulseCtrl;
  Map<String, dynamic>? get _nearestMandi => _mandiData[appState.detectedDistrict] ?? _mandiData['Default'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _startLocationStream();
  }
  @override
  void dispose() { _positionStream?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _startLocationStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { if (mounted) setState(() => _locationPermissionDenied = true); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationPermissionDenied = true); return;
      }
      final initial = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)));
      if (mounted) {
        setState(() => _currentLiveLocation = LatLng(initial.latitude, initial.longitude));
        _mapController.move(_currentLiveLocation!, 15);
        appState.updateLocation(_currentLiveLocation!);
      }
      _positionStream = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
          .listen((Position position) {
        if (mounted) { setState(() => _currentLiveLocation = LatLng(position.latitude, position.longitude)); appState.updateLocation(_currentLiveLocation!); }
      });
    } catch (e) { debugPrint('Location stream error: $e'); if (mounted) setState(() => _locationPermissionDenied = true); }
  }

  void _onMapLongPress(TapPosition tapPos, LatLng loc) async {
    HapticFeedback.heavyImpact();
    await appState.prepareReportAt(loc);
    if (!mounted) return;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => Padding(padding: const EdgeInsets.all(16),
        child: RevealCard(child: DeepGlassCard(borderRadius: 30, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on_rounded, size: 50, color: Color(0xFFE76F51)),
          const SizedBox(height: 16),
          Text(appState.t('report_issue'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
          const SizedBox(height: 8),
          AnimatedBuilder(animation: appState, builder: (context, _) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(appState.reportDraftAddress, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 60, child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(context); appState.setNav(2); },
            child: Text(appState.t('start_report'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 20),
        ])))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        AnimatedBuilder(animation: Listenable.merge([repo, _pulseCtrl]), builder: (context, _) {
          final mandi = _nearestMandi;
          final mandiLatLng = mandi != null ? LatLng(mandi['lat'] as double, mandi['lng'] as double) : null;
          final pulseRadius = 150.0 + (_pulseCtrl.value * 60);

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentLiveLocation ?? appState.userLocation, initialZoom: 14, onLongPress: _onMapLongPress),
            children: [
              TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c', 'd']),
              CircleLayer(circles: [
                ...repo.reports.map((r) => CircleMarker(point: r.loc,
                    color: (r.status == 'Resolved' ? Colors.green : Colors.red).withValues(alpha: 0.12),
                    borderStrokeWidth: 2, borderColor: (r.status == 'Resolved' ? Colors.green : Colors.red).withValues(alpha: 0.5),
                    useRadiusInMeter: true, radius: 150)),
                ...repo.reports.where((r) => r.status == 'Pending').map((r) => CircleMarker(point: r.loc,
                    color: Colors.red.withValues(alpha: (1 - _pulseCtrl.value) * 0.08), borderStrokeWidth: 0, useRadiusInMeter: true, radius: pulseRadius)),
                if (mandiLatLng != null)
                  CircleMarker(point: mandiLatLng, color: Colors.amber.withValues(alpha: 0.15), borderStrokeWidth: 2, borderColor: Colors.amber.withValues(alpha: 0.5), useRadiusInMeter: true, radius: 200),
              ]),
              MarkerLayer(markers: [
                ...repo.reports.map((r) => Marker(point: r.loc, width: 40, height: 40,
                    child: Icon(Icons.location_pin, color: r.status == 'Resolved' ? Colors.green : Colors.red, size: 40))),
                if (mandiLatLng != null) Marker(point: mandiLatLng, width: 120, height: 60,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 8)]),
                        child: Text(appState.t('nearest_mandi'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF264653)), textAlign: TextAlign.center)),
                    const Icon(Icons.store_mall_directory_rounded, color: Colors.amber, size: 28),
                  ])),
              ]),
              if (_currentLiveLocation != null)
                MarkerLayer(markers: [Marker(point: _currentLiveLocation!, width: 24, height: 24,
                    child: Container(decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 5)])))]),
            ],
          );
        }),
        if (_locationPermissionDenied)
          Positioned(top: 60, left: 16, right: 16, child: DeepGlassCard(padding: 16, color: Colors.orange.withValues(alpha: 0.3),
            child: Row(children: [
              const Icon(Icons.location_off_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(child: Text(appState.t('location_unavailable'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653)))),
            ]))),
      ]),
      floatingActionButton: Padding(padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(backgroundColor: Colors.white, elevation: 8,
          onPressed: () { HapticFeedback.selectionClick(); if (_currentLiveLocation != null) _mapController.move(_currentLiveLocation!, 16); },
          child: const Icon(Icons.my_location_rounded, color: Color(0xFF264653)))),
    );
  }
}

// ==========================================
// PUBLIC REPORT SCREEN
// ==========================================
class PublicReportScreen extends StatefulWidget {
  const PublicReportScreen({super.key});
  @override
  State<PublicReportScreen> createState() => _PublicReportScreenState();
}
class _PublicReportScreenState extends State<PublicReportScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Roads';
  XFile? _image;
  bool _isSubmitting = false;
  static const _categories = ['Roads', 'Water', 'Garbage', 'Electricity', 'Other'];

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final pickedFile = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 75);
      if (pickedFile != null) setState(() => _image = pickedFile);
    } catch (e) { debugPrint('Image picker error: $e'); if (mounted) showMessage(context, 'Cannot open camera.', isError: true); }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Padding(padding: const EdgeInsets.all(16), child: RevealCard(child: DeepGlassCard(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Add Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _ImageSourceBtn(icon: Icons.camera_alt_rounded, label: 'Camera', onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); })),
          const SizedBox(width: 16),
          Expanded(child: _ImageSourceBtn(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); })),
        ]),
        const SizedBox(height: 8),
      ])))),
    );
  }

  void _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) { showMessage(context, appState.t('add_title'), isError: true); return; }
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    final report = CivicReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(), userId: appState.currentUser?.uid ?? 'unknown',
      title: title, desc: _descCtrl.text.trim(), category: _category,
      loc: appState.reportDraftLocation ?? appState.userLocation,
      address: appState.reportDraftAddress.isNotEmpty ? appState.reportDraftAddress : null,
    );
    await repo.saveReport(report, _image);
    if (mounted) {
      setState(() { _isSubmitting = false; _titleCtrl.clear(); _descCtrl.clear(); _image = null; appState.reportDraftLocation = null; appState.reportDraftAddress = ''; });
      // NO points on submission - points only on admin acceptance
      showMessage(context, appState.t('report_submitted'));
      appState.setNav(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('new_report'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GestureDetector(onTap: _showImageSourceDialog,
              child: DeepGlassCard(padding: 0, child: Container(height: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                child: _image == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 50, color: Color(0xFF2A9D8F))),
                        const SizedBox(height: 12),
                        Text(appState.t('photo_optional'), style: const TextStyle(color: Color(0xFF264653), fontWeight: FontWeight.bold, fontSize: 15)),
                      ])
                    : Stack(fit: StackFit.expand, children: [
                        ClipRRect(borderRadius: BorderRadius.circular(20),
                            child: kIsWeb ? Image.network(_image!.path, fit: BoxFit.cover) : Image.file(io.File(_image!.path), fit: BoxFit.cover)),
                        Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => setState(() => _image = null),
                          child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18)))),
                      ]),
              )),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(animation: appState, builder: (context, _) => DeepGlassCard(padding: 16,
              child: Row(children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFFE76F51), size: 28),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(appState.t('location'), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(appState.reportDraftAddress.isNotEmpty ? appState.reportDraftAddress : appState.t('using_gps'),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653), fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            )),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
              child: DropdownButton<String>(value: _category, isExpanded: true, underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF264653)),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                onChanged: (v) { HapticFeedback.lightImpact(); if (v != null) setState(() => _category = v); }),
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl, textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: appState.t('short_title'), prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF2A9D8F)))),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl, maxLines: 4, textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: appState.t('provide_context'), alignLabelWithHint: true)),
            const SizedBox(height: 32),
            SizedBox(height: 60, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5),
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? appState.t('submitting') : appState.t('submit'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 120),
          ]),
        ),
      )),
    );
  }
}

class _ImageSourceBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ImageSourceBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A9D8F).withValues(alpha: 0.3))),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF2A9D8F), size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
        ]),
      ),
    );
  }
}

// ==========================================
// FARMER MARKET SCREEN
// ==========================================
class FarmerMarketScreen extends StatefulWidget {
  const FarmerMarketScreen({super.key});
  @override
  State<FarmerMarketScreen> createState() => _FarmerMarketScreenState();
}
class _FarmerMarketScreenState extends State<FarmerMarketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      repo.loadLocalCropData(appState.detectedDistrict);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('local_market'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(animation: Listenable.merge([repo, appState]), builder: (context, _) {
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), children: [
            Padding(padding: const EdgeInsets.only(bottom: 16), child: DeepGlassCard(padding: 12, color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF2A9D8F), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(appState.t('agmarknet_source'), style: const TextStyle(fontSize: 11, color: Color(0xFF264653), fontWeight: FontWeight.bold))),
              ]),
            )),
            ...List.generate(repo.crops.length, (index) {
              final crop = repo.crops[index];
              final isUp = crop.predictedPrice > crop.currentPrice;
              final hasAlert = appState.priceAlerts[crop.name] ?? false;
              return StaggeredEntrance(index: index, child: Padding(padding: const EdgeInsets.only(bottom: 16),
                child: TappableGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(contentPadding: EdgeInsets.zero,
                    leading: Container(padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.grass_rounded, color: Color(0xFF2A9D8F), size: 30)),
                    title: Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF264653))),
                    subtitle: Text('${appState.t('demand')}: ${crop.demand}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('₹${crop.currentPrice.toStringAsFixed(0)}/kg', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF264653))),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isUp ? Colors.green : Colors.red, size: 16),
                        Text('₹${crop.predictedPrice.toStringAsFixed(0)}', style: TextStyle(color: isUp ? Colors.green : Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Icon(Icons.notifications_rounded, size: 16, color: hasAlert ? const Color(0xFF2A9D8F) : Colors.black38),
                    const SizedBox(width: 6),
                    Text(appState.t('set_alert'), style: TextStyle(fontSize: 12, color: hasAlert ? const Color(0xFF2A9D8F) : Colors.black38, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                      child: Switch(key: ValueKey(hasAlert), value: hasAlert, activeTrackColor: const Color(0xFF2A9D8F),
                        onChanged: (v) { HapticFeedback.selectionClick(); appState.togglePriceAlert(crop.name); showMessage(context, v ? appState.t('alert_on') : appState.t('alert_off')); }),
                    ),
                  ]),
                ])),
              ));
            }),
          ]),
        ));
      }),
    );
  }
}

// ==========================================
// CROP DOCTOR SCREEN
// ==========================================
class CropDoctorScreen extends StatefulWidget {
  const CropDoctorScreen({super.key});
  @override
  State<CropDoctorScreen> createState() => _CropDoctorScreenState();
}
class _CropDoctorScreenState extends State<CropDoctorScreen> with TickerProviderStateMixin {
  XFile? _image;
  bool _isAnalyzing = false;
  String _diagnosis = '';
  String _errorMsg = '';
  double _imageScale = 0.0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final pickedFile = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 60);
      if (pickedFile != null) {
        setState(() { _image = pickedFile; _diagnosis = ''; _errorMsg = ''; _imageScale = 0.0; });
        Future.delayed(const Duration(milliseconds: 50), () { if (mounted) setState(() => _imageScale = 1.0); });
      }
    } catch (e) { debugPrint('Image picker error: $e'); }
  }

  Future<void> _analyzeCrop() async {
    if (_image == null) return;
    HapticFeedback.mediumImpact();
    setState(() { _isAnalyzing = true; _errorMsg = ''; });

    if (groqApiKey.isEmpty || groqApiKey == 'YOUR_GROQ_API_KEY') {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      const mockDiagnosis = '**Early Blight (Alternaria solani)**\n\n**Symptoms:** Brown spots with concentric rings on lower leaves.\n\n**Treatment:**\n• Apply copper-based fungicide\n• Remove infected leaves\n• Ensure proper crop spacing for air circulation\n• Avoid overhead irrigation';
      setState(() { _diagnosis = mockDiagnosis; _isAnalyzing = false; });
      appState.addDiagnosis(DiagnosisEntry(imagePath: _image!.path, diagnosis: mockDiagnosis, timestamp: DateTime.now()));
      return;
    }

    try {
      final bytes = await _image!.readAsBytes();
      // Limit image size to avoid 413 errors
      if (bytes.length > 4 * 1024 * 1024) {
        setState(() { _errorMsg = 'Image too large. Please use a photo under 4MB or choose a lower resolution.'; _isAnalyzing = false; });
        return;
      }
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $groqApiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama-3.2-11b-vision-preview', 'max_tokens': 512,
          'messages': [{'role': 'user', 'content': [
            {'type': 'text', 'text': 'You are an expert agricultural plant pathologist. Identify any visible plant disease in this leaf image. Provide: 1) Disease name 2) Key symptoms 3) Treatment recommendation. Be concise and practical for a farmer.'},
            {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image', 'detail': 'low'}}
          ]}]
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final result = (jsonDecode(response.body)['choices'][0]['message']['content'] as String?) ?? 'No result';
        setState(() => _diagnosis = result);
        appState.addDiagnosis(DiagnosisEntry(imagePath: _image!.path, diagnosis: result, timestamp: DateTime.now()));
      } else if (response.statusCode == 413) {
        setState(() => _errorMsg = 'Image file is too large for AI analysis. Please take a closer photo or use gallery to pick a smaller image.');
      } else if (response.statusCode == 429) {
        setState(() => _errorMsg = 'AI service is busy right now. Please wait a moment and try again. (Rate limit reached)');
      } else if (response.statusCode == 401) {
        setState(() => _errorMsg = 'AI API key invalid. Demo mode: contact admin to configure.');
      } else {
        final errorBody = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        setState(() => _errorMsg = 'Analysis failed (HTTP ${response.statusCode}). Try again shortly.');
        debugPrint('Groq error body: $errorBody');
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _errorMsg = 'Request timed out after 30s. Check your internet connection and try again.');
    } on FormatException {
      if (!mounted) return;
      setState(() => _errorMsg = 'Unexpected response from AI service. Please try again.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Network error: Unable to reach AI service. Check your internet connection.');
      debugPrint('Groq API error: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('doctor'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), children: [
          DeepGlassCard(child: Column(children: [
            AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('snap_leaf'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
            const SizedBox(height: 24),
            AnimatedBuilder(animation: _pulseAnim, builder: (_, __) {
              return AnimatedScale(scale: _image != null ? _imageScale : 1.0, duration: const Duration(milliseconds: 300), curve: Curves.elasticOut,
                child: Stack(alignment: Alignment.center, children: [
                  if (_isAnalyzing) ...List.generate(3, (i) => Transform.scale(
                    scale: 1.0 + (_pulseCtrl.value * 0.15 * (i + 1)),
                    child: Container(width: 260, height: 260, decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF2A9D8F).withValues(alpha: (1 - _pulseCtrl.value * 0.4) * (0.4 - i * 0.1)), width: 2),
                        borderRadius: BorderRadius.circular(20))),
                  )),
                  GestureDetector(onTap: () => _pickImage(ImageSource.camera),
                    child: Container(height: 250, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
                      child: _image == null
                          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.document_scanner_rounded, size: 60, color: Color(0xFF2A9D8F)),
                              const SizedBox(height: 12),
                              AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('tap_scan'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A9D8F), fontSize: 16))),
                            ])
                          : ClipRRect(borderRadius: BorderRadius.circular(18),
                              child: kIsWeb ? Image.network(_image!.path, fit: BoxFit.cover) : Image.file(io.File(_image!.path), fit: BoxFit.cover)),
                    ),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 12),
            TextButton.icon(onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF2A9D8F)),
                label: const Text('Choose from Gallery', style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Stack(children: [
              SizedBox(width: double.infinity, height: 55, child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE76F51), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5),
                onPressed: (_image == null || _isAnalyzing) ? null : _analyzeCrop,
                icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
                label: AnimatedBuilder(animation: appState, builder: (_, __) => Text(_isAnalyzing ? appState.t('analyzing') : appState.t('analyze_crop'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              )),
              if (_isAnalyzing) Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: const ShimmerBox(height: 55, borderRadius: 16))),
            ]),
          ])),
          if (_errorMsg.isNotEmpty) ...[
            const SizedBox(height: 16),
            RevealCard(child: DeepGlassCard(color: Colors.red.withValues(alpha: 0.1), border: Border.all(color: Colors.redAccent, width: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                const SizedBox(width: 12),
                Expanded(child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
              ]),
            )),
          ],
          if (_diagnosis.isNotEmpty) ...[
            const SizedBox(height: 24),
            RevealCard(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF2A9D8F).withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)]),
              child: DeepGlassCard(color: const Color(0xFF2A9D8F).withValues(alpha: 0.1), border: Border.all(color: const Color(0xFF2A9D8F), width: 2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.healing_rounded, color: Color(0xFF264653), size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('diagnosis_treatment'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF264653))))),
                  ]),
                  const Divider(height: 24, thickness: 2),
                  Text(_diagnosis, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87, fontWeight: FontWeight.w500)),
                ]),
              ),
            )),
          ],
          AnimatedBuilder(animation: appState, builder: (context, _) {
            if (appState.diagnosisHistory.isEmpty) return const SizedBox();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 32),
              Row(children: [
                Text(appState.t('crop_history'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
                const Spacer(),
                TextButton.icon(onPressed: () { HapticFeedback.lightImpact(); appState.clearDiagnosisHistory(); },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    label: Text(appState.t('clear_history'), style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
              ]),
              ...appState.diagnosisHistory.asMap().entries.map((e) {
                final entry = e.value;
                return Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: TappableGlassCard(padding: 16, onTap: () => setState(() => _diagnosis = entry.diagnosis),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 50, height: 50,
                          child: kIsWeb ? Image.network(entry.imagePath, fit: BoxFit.cover) : Image.file(io.File(entry.imagePath), fit: BoxFit.cover))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(entry.diagnosis.split('\n').first.replaceAll('**', ''),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF264653)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                      ])),
                      const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                    ]),
                  ),
                );
              }),
            ]);
          }),
        ]),
      )),
    );
  }
}

// ==========================================
// FARMER DEMAND / TRANSPORT SCREEN (UPGRADED)
// ==========================================
class FarmerDemandScreen extends StatefulWidget {
  const FarmerDemandScreen({super.key});
  @override
  State<FarmerDemandScreen> createState() => _FarmerDemandScreenState();
}
class _FarmerDemandScreenState extends State<FarmerDemandScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('logistics'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(animation: Listenable.merge([repo, appState]), builder: (context, _) {
        final uid = appState.currentUser?.uid ?? '';
        final myRequests = repo.logistics.where((l) => l.farmerId == uid).toList();
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), children: [
            // Book new transport card
            StaggeredEntrance(index: 0, child: DeepGlassCard(padding: 28, child: Column(children: [
              const Icon(Icons.airport_shuttle_rounded, size: 80, color: Color(0xFFE9C46A)),
              const SizedBox(height: 16),
              Text(appState.t('micro_market'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF264653)), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(appState.t('connect_citizens'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 28),
              SizedBox(height: 55, width: double.infinity, child: FilledButton.icon(
                onPressed: () => _showRequestDialog(context),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(appState.t('booking_transport'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5),
              )),
            ]))),

            // My logistics requests
            if (myRequests.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(appState.t('my_logistics'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
              const SizedBox(height: 12),
              ...myRequests.asMap().entries.map((e) => StaggeredEntrance(index: e.key + 1, child: Padding(padding: const EdgeInsets.only(bottom: 14),
                child: DeepGlassCard(padding: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF2A9D8F), size: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.value.crop, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF264653))),
                      Text('${e.value.weightKg.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                    ])),
                    _LogisticsStatusBadge(status: e.value.status),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.black45),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.value.pickupAddress, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  if (e.value.scheduledTime != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text('Pickup: ${e.value.scheduledTime}', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ])),
              ))),
            ] else ...[
              const SizedBox(height: 20),
              Center(child: Text(appState.t('no_logistics'), style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold))),
            ],
          ]),
        ));
      }),
    );
  }

  void _showRequestDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    String selectedCrop = _cropOptions.first;
    final weightCtrl = TextEditingController();
    LatLng pickupLocation = appState.userLocation;
    String pickupAddress = appState.reportDraftAddress.isNotEmpty ? appState.reportDraftAddress : 'Current Location';

    showDialog(context: context, builder: (dialogCtx) => StatefulBuilder(builder: (dialogCtx, setDialogState) {
      return AlertDialog(backgroundColor: Colors.transparent, contentPadding: EdgeInsets.zero,
        content: RevealCard(child: SingleChildScrollView(child: DeepGlassCard(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.local_shipping_rounded, size: 40, color: Color(0xFF2A9D8F)),
          const SizedBox(height: 12),
          Text(appState.t('booking_transport'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF264653)), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Bilingual crop dropdown
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(14)),
            child: DropdownButton<String>(value: selectedCrop, isExpanded: true, underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF264653)),
              items: _cropOptions.map((c) {
                final tamil = _cropOptionsTamil[c] ?? c;
                return DropdownMenuItem(value: c, child: Text(appState.lang == 'ta' ? '$tamil ($c)' : c, style: const TextStyle(fontWeight: FontWeight.bold)));
              }).toList(),
              onChanged: (v) { if (v != null) setDialogState(() => selectedCrop = v); }),
          ),
          const SizedBox(height: 14),
          TextField(controller: weightCtrl, keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: appState.t('load_weight'), prefixIcon: const Icon(Icons.scale_rounded, color: Color(0xFF2A9D8F)))),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF2A9D8F), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(pickupAddress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF264653)), maxLines: 2)),
            ]),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF264653), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final wText = weightCtrl.text.trim();
              if (wText.isEmpty) { if (dialogCtx.mounted) showMessage(dialogCtx, appState.t('fill_all_fields'), isError: true); return; }
              final weight = double.tryParse(wText);
              if (weight == null || weight <= 0) { if (dialogCtx.mounted) showMessage(dialogCtx, 'Please enter a valid weight.', isError: true); return; }
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              final req = LogisticsRequest(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                farmerId: appState.currentUser?.uid ?? 'unknown',
                farmerName: appState.currentUser?.name ?? 'Farmer',
                crop: selectedCrop, weightKg: weight,
                pickupAddress: pickupAddress,
                pickupLoc: pickupLocation,
              );
              await repo.submitLogisticsRequest(req);
              if (context.mounted) showMessage(context, appState.t('truck_assigned'));
            },
            child: Text(appState.t('confirm_booking')),
          ),
        ])))),
      );
    }));
  }
}

class _LogisticsStatusBadge extends StatelessWidget {
  final String status;
  const _LogisticsStatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'Confirmed': return Colors.blue;
      case 'Scheduled': return Colors.orange;
      case 'Picked Up': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12)));
  }
}

// ==========================================
// ADMIN DASHBOARD
// ==========================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pieCtrl;
  late Animation<double> _pieSweep;

  @override
  void initState() {
    super.initState();
    _pieCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pieSweep = CurvedAnimation(parent: _pieCtrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _pieCtrl.forward(); });
  }
  @override
  void dispose() { _pieCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: Listenable.merge([repo, _pieCtrl]), builder: (context, _) {
      final total = repo.reports.length;
      final resolved = repo.reports.where((r) => r.status == 'Resolved').length;
      final rejected = repo.reports.where((r) => r.status == 'Rejected').length;
      final pending = repo.reports.where((r) => r.status == 'Pending').length;
      final assigned = repo.reports.where((r) => r.status == 'Assigned' || r.status == 'In Progress').length;

      return Scaffold(
        appBar: AppBar(
          title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('command_center'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
          backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
        ),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(children: [
              Row(children: [
                Expanded(child: StaggeredEntrance(index: 0, child: _AnimatedStatCard(title: appState.t('total'), value: total, color: Colors.blue))),
                const SizedBox(width: 12),
                Expanded(child: StaggeredEntrance(index: 1, child: _AnimatedStatCard(title: appState.t('pending'), value: pending, color: Colors.orange))),
                const SizedBox(width: 12),
                Expanded(child: StaggeredEntrance(index: 2, child: _AnimatedStatCard(title: appState.t('resolved'), value: resolved, color: Colors.green))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: StaggeredEntrance(index: 3, child: _AnimatedStatCard(title: appState.t('status_assigned'), value: assigned, color: Colors.blue.shade700))),
                const SizedBox(width: 12),
                Expanded(child: StaggeredEntrance(index: 4, child: _AnimatedStatCard(title: appState.t('reject'), value: rejected, color: Colors.red))),
                const SizedBox(width: 12),
                Expanded(child: StaggeredEntrance(index: 5, child: _AnimatedStatCard(title: 'Logistics', value: repo.logistics.length, color: const Color(0xFFE9C46A)))),
              ]),
              const SizedBox(height: 32),
              if (total == 0)
                StaggeredEntrance(index: 6, child: DeepGlassCard(padding: 40, child: Column(children: [
                  const Icon(Icons.done_all_rounded, size: 60, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(appState.t('zero_issues'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
                  const SizedBox(height: 8),
                  Text(appState.t('zero_desc'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ])))
              else
                StaggeredEntrance(index: 6, child: DeepGlassCard(padding: 32, child: Column(children: [
                  Text(appState.t('resolution_ratio'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
                  const SizedBox(height: 32),
                  SizedBox(height: 220, child: AnimatedBuilder(animation: _pieSweep, builder: (_, __) => CustomPaint(
                    painter: _AnimatedPieChartPainter(resolved: resolved, pending: pending + assigned, progress: _pieSweep.value),
                    size: const Size(220, 220),
                  ))),
                  const SizedBox(height: 32),
                  Wrap(spacing: 16, runSpacing: 8, alignment: WrapAlignment.center, children: [
                    _Legend(color: Colors.green, label: appState.t('resolved')),
                    _Legend(color: Colors.orange, label: appState.t('pending')),
                    if (rejected > 0) _Legend(color: Colors.red, label: appState.t('reject')),
                  ]),
                ]))),
            ]),
          ),
        )),
      );
    });
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final String title; final int value; final Color color;
  const _AnimatedStatCard({required this.title, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return DeepGlassCard(color: color.withValues(alpha: 0.15), border: Border.all(color: color.withValues(alpha: 0.3), width: 2), padding: 16,
      child: Column(children: [
        Text(title, style: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w900, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        AnimatedCounterText(value: value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }
}


class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }
}

class _AnimatedPieChartPainter extends CustomPainter {
  final int resolved, pending; final double progress;
  _AnimatedPieChartPainter({required this.resolved, required this.pending, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final total = math.max(1, resolved + pending);
    final resolvedAngle = (resolved / total) * 2 * math.pi * progress;
    final totalAngle = 2 * math.pi * progress;
    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.color = Colors.green; canvas.drawArc(rect, -math.pi / 2, resolvedAngle, true, paint);
    paint.color = Colors.orange; canvas.drawArc(rect, -math.pi / 2 + resolvedAngle, totalAngle - resolvedAngle, true, paint);
    paint.color = const Color(0xFFF6F4EB).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 3, paint);
    if (progress >= 0.9) {
      final pct = '${((resolved / total) * 100).round()}%';
      final tp = TextPainter(text: TextSpan(text: pct, style: const TextStyle(color: Color(0xFF264653), fontWeight: FontWeight.w900, fontSize: 22)), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
    }
  }
  @override
  bool shouldRepaint(covariant _AnimatedPieChartPainter old) => old.progress != progress || old.resolved != resolved || old.pending != pending;
}

// ==========================================
// ADMIN ASSIGN SCREEN (with Department Assignment)
// ==========================================
class AdminAssignScreen extends StatefulWidget {
  const AdminAssignScreen({super.key});
  @override
  State<AdminAssignScreen> createState() => _AdminAssignScreenState();
}
class _AdminAssignScreenState extends State<AdminAssignScreen> {
  String _selectedWard = 'all';

  List<CivicReport> get _filteredReports {
    final pending = repo.reports.where((r) => r.status == 'Pending').toList();
    if (_selectedWard == 'all') return pending;
    return pending.where((r) => r.wardId == _selectedWard).toList();
  }

  Map<String, int> get _wardIssueCounts {
    final counts = <String, int>{};
    for (final w in _wardData) { counts[w['id'] as String] = 0; }
    for (final r in repo.reports.where((r) => r.status == 'Pending')) {
      if (r.wardId != null) counts[r.wardId!] = (counts[r.wardId!] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: repo, builder: (context, _) {
      final pending = _filteredReports;
      final wardCounts = _wardIssueCounts;

      return Scaffold(
        appBar: AppBar(
          title: AnimatedBuilder(animation: appState, builder: (_, __) => Text('${appState.t('live_issues')} (${pending.length})', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
          backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
        ),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
          child: Column(children: [
            // Ward filter chips
            SizedBox(height: 60, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              children: [
                _WardChip(label: appState.t('all_wards'), isSelected: _selectedWard == 'all', count: repo.reports.where((r) => r.status == 'Pending').length,
                    onTap: () => setState(() => _selectedWard = 'all')),
                const SizedBox(width: 8),
                ..._wardData.map((w) => Padding(padding: const EdgeInsets.only(right: 8),
                  child: _WardChip(label: w['name'] as String, isSelected: _selectedWard == w['id'],
                      count: wardCounts[w['id']] ?? 0, onTap: () => setState(() => _selectedWard = w['id'] as String)))),
              ],
            )),
            Expanded(child: pending.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(appState.t('all_resolved'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green)),
                ]))
              : ListView.builder(padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final r = pending[index];
                    return StaggeredEntrance(index: index, child: Padding(padding: const EdgeInsets.only(bottom: 20),
                      child: DeepGlassCard(padding: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text(r.category, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900))),
                          if (r.wardName != null)
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.location_city_rounded, size: 12, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text(r.wardName!, style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
                              ])),
                        ]),
                        const SizedBox(height: 16),
                        Text(r.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
                        if (r.desc.isNotEmpty) ...[const SizedBox(height: 8), Text(r.desc, style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.5))],
                        if (r.imagePath != null && r.imagePath!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(r.imagePath!, height: 200, width: double.infinity, fit: BoxFit.cover,
                              loadingBuilder: (context, child, prog) => prog == null ? child : Container(height: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                              errorBuilder: (context, e, _) => Container(height: 100, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))))),
                        ],
                        if (r.address != null) ...[
                          const SizedBox(height: 16),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.location_on, size: 20, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${r.address!}\n(${r.loc.latitude.toStringAsFixed(4)}, ${r.loc.longitude.toStringAsFixed(4)})',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, height: 1.4))),
                          ]),
                        ],
                        const SizedBox(height: 24),
                        // Reject + Accept+Assign buttons
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () { HapticFeedback.mediumImpact(); repo.updateReportStatus(r.id, 'Rejected'); },
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            icon: const Icon(Icons.close_rounded),
                            label: Text(appState.t('reject'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: FilledButton.icon(
                            onPressed: () => _showAssignDialog(context, r),
                            style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 5),
                            icon: const Icon(Icons.assignment_turned_in_rounded),
                            label: Text(appState.t('assign'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          )),
                        ]),
                      ])),
                    ));
                  }),
            ),
          ]),
        )),
      );
    });
  }

  void _showAssignDialog(BuildContext context, CivicReport r) {
    String selectedDept = _departments.first;
    showDialog(context: context, builder: (dialogCtx) => StatefulBuilder(builder: (dialogCtx, setS) => AlertDialog(
      backgroundColor: Colors.transparent, contentPadding: EdgeInsets.zero,
      content: RevealCard(child: DeepGlassCard(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.assignment_rounded, size: 40, color: Color(0xFF2A9D8F)),
        const SizedBox(height: 12),
        Text(appState.t('assign_dept'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF264653)), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(r.title, style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(14)),
          child: DropdownButton<String>(value: selectedDept, isExpanded: true, underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF264653)),
            items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            onChanged: (v) { if (v != null) setS(() => selectedDept = v); }),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            HapticFeedback.mediumImpact();
            Navigator.pop(dialogCtx);
            await repo.acceptAndAssignReport(r.id, selectedDept);
            if (context.mounted) showMessage(context, '${r.title} assigned to $selectedDept dept. +50 pts to citizen!');
          },
          icon: const Icon(Icons.check_rounded),
          label: Text(appState.t('accept'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ]))),
    )));
  }
}

class _WardChip extends StatelessWidget {
  final String label; final bool isSelected; final int count; final VoidCallback onTap;
  const _WardChip({required this.label, required this.isSelected, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF264653) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF264653) : Colors.black26, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF264653), fontSize: 13)),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(width: 20, height: 20, decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.red, shape: BoxShape.circle),
                child: Center(child: Text('$count', style: TextStyle(color: isSelected ? const Color(0xFF264653) : Colors.white, fontWeight: FontWeight.w900, fontSize: 10)))),
          ],
        ]),
      ),
    );
  }
}

// ==========================================
// ADMIN ANALYTICS (HEATMAP)
// ==========================================
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}
class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLiveLocation;
  late AnimationController _pulseCtrl;

  @override
  void initState() { super.initState(); _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); _startLocationStream(); }
  @override
  void dispose() { _positionStream?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _startLocationStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      final initial = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)));
      if (mounted) { setState(() => _currentLiveLocation = LatLng(initial.latitude, initial.longitude)); _mapController.move(_currentLiveLocation!, 12); }
      _positionStream = Geolocator.getPositionStream().listen((p) { if (mounted) setState(() => _currentLiveLocation = LatLng(p.latitude, p.longitude)); });
    } catch (e) { debugPrint('Analytics location error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('city_heatmap'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(animation: Listenable.merge([repo, _pulseCtrl]), builder: (context, _) {
        final pendingReports = repo.reports.where((r) => r.status == 'Pending').toList();
        final pulseAlpha = (math.sin(_pulseCtrl.value * math.pi) * 0.15 + 0.2).clamp(0.0, 1.0);
        return Stack(children: [
          FlutterMap(mapController: _mapController,
            options: MapOptions(initialCenter: _currentLiveLocation ?? appState.userLocation, initialZoom: 12),
            children: [
              TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c', 'd']),
              CircleLayer(circles: pendingReports.map((r) => CircleMarker(point: r.loc, color: Colors.red.withValues(alpha: pulseAlpha), borderStrokeWidth: 0, useRadiusInMeter: true, radius: 800)).toList()),
              MarkerLayer(markers: pendingReports.map((r) => Marker(point: r.loc, width: 50, height: 50, child: const Icon(Icons.location_on, color: Colors.red, size: 45))).toList()),
              if (_currentLiveLocation != null)
                MarkerLayer(markers: [Marker(point: _currentLiveLocation!, width: 24, height: 24,
                    child: Container(decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 5)])))]),
            ],
          ),
          Positioned(top: 24, left: 24, right: 24, child: DeepGlassCard(padding: 16,
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Text('${pendingReports.length} pending · ${appState.t('high_density')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653), fontSize: 13))),
            ]),
          )),
        ]);
      }),
    );
  }
}

// ==========================================
// ADMIN USERS DIRECTORY
// ==========================================
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  void _confirmDelete(BuildContext context, String docId, String userName) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.transparent, contentPadding: EdgeInsets.zero,
      content: RevealCard(child: DeepGlassCard(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
        const SizedBox(height: 16),
        Text(appState.t('delete_citizen'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF264653))),
        const SizedBox(height: 8),
        Text('"$userName"\n${appState.t('delete_confirm')}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2A9D8F))), child: Text(appState.t('cancel')))),
          const SizedBox(width: 16),
          Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                if (!context.mounted) return;
                Navigator.pop(context); showMessage(context, appState.t('delete_success'));
              } catch (e) { if (!context.mounted) return; Navigator.pop(context); showMessage(context, appState.t('error_generic'), isError: true); }
            },
            child: Text(appState.t('delete')))),
        ])
      ]))),
    ));
  }

  void _editUserDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name'] as String? ?? '');
    final passCtrl = TextEditingController(text: data['password'] as String? ?? '');
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.transparent, contentPadding: EdgeInsets.zero,
      content: RevealCard(child: DeepGlassCard(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(appState.t('edit_profile'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF264653)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: appState.t('name'), prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF2A9D8F)))),
        const SizedBox(height: 12),
        TextField(controller: passCtrl, decoration: InputDecoration(labelText: appState.t('password'), prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF2A9D8F)))),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF264653), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            try {
              await FirebaseFirestore.instance.collection('users').doc(docId).update({'name': nameCtrl.text.trim(), 'password': passCtrl.text.trim()});
              if (!context.mounted) return;
              Navigator.pop(context); showMessage(context, 'Profile updated successfully.');
            } catch (e) { if (!context.mounted) return; Navigator.pop(context); showMessage(context, appState.t('error_generic'), isError: true); }
          },
          child: Text(appState.t('save')),
        ),
      ]))),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return Scaffold(body: Center(child: Text(appState.t('no_firebase'), style: const TextStyle(fontWeight: FontWeight.bold))));
    }
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('citizens_directory'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: DeepGlassCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48), const SizedBox(height: 12), Text(appState.t('error_generic'), style: const TextStyle(fontWeight: FontWeight.bold))]))));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No users registered yet.', style: TextStyle(fontWeight: FontWeight.bold)));
          final users = snapshot.data!.docs;
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
            child: Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: AnimatedBuilder(animation: appState, builder: (_, __) => DeepGlassCard(color: const Color(0xFF2A9D8F).withValues(alpha: 0.2),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.people_alt_rounded, size: 36, color: Color(0xFF264653)),
                  const SizedBox(width: 16),
                  Text('${appState.t('citizens_directory')}: ${users.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
                ]),
              ))),
              Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), itemCount: users.length,
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  final docId = users[index].id;
                  final userName = data['name'] as String? ?? 'Unknown';
                  final role = data['role'] as String? ?? 'Unknown';
                  final phone = data['phone'] as String? ?? 'N/A';
                  final points = data['civicPoints'] as int? ?? 0;
                  return StaggeredEntrance(index: index, delayMs: 60, child: Padding(padding: const EdgeInsets.only(bottom: 12),
                    child: DeepGlassCard(padding: 16, child: ListTile(contentPadding: EdgeInsets.zero,
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE9C46A).withValues(alpha: 0.3), shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: Color(0xFF264653))),
                      title: Text(userName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF264653))),
                      subtitle: Text('Role: $role | Phone: $phone\nPoints: $points ⭐', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, height: 1.5)),
                      isThreeLine: true,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit_rounded, color: Color(0xFF2A9D8F)), onPressed: () => _editUserDialog(context, docId, data), tooltip: 'Edit'),
                        IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () => _confirmDelete(context, docId, userName), tooltip: 'Delete'),
                      ]),
                    )),
                  ));
                },
              )),
            ]),
          ));
        },
      ),
    );
  }
}

// ==========================================
// ADMIN WAREHOUSE SCREEN (NEW)
// ==========================================
class AdminWarehouseScreen extends StatelessWidget {
  const AdminWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('warehouse_mgmt'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(animation: repo, builder: (context, _) {
        final pendingLogistics = repo.logistics.where((l) => l.status == 'Requested').toList();
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), children: [
            // Warehouse cards
            Text(appState.t('warehouse_mgmt'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
            const SizedBox(height: 12),
            ..._warehouseData.asMap().entries.map((e) => StaggeredEntrance(index: e.key, child: Padding(padding: const EdgeInsets.only(bottom: 14),
              child: DeepGlassCard(padding: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE9C46A).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.warehouse_rounded, color: Color(0xFFE9C46A), size: 28)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.value['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF264653))),
                    Text(e.value['location'] as String, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
                  ])),
                ]),
                const SizedBox(height: 14),
                // Capacity bar
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(appState.t('capacity'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
                    Text('${e.value['used']}/${e.value['capacity']} tons', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
                    value: (e.value['used'] as int) / (e.value['capacity'] as int),
                    minHeight: 10, backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>((e.value['used'] as int) / (e.value['capacity'] as int) > 0.8 ? Colors.red : const Color(0xFF2A9D8F)),
                  )),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: (e.value['crops'] as List).map((c) => Chip(
                  label: Text(c as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                  padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList()),
              ])),
            ))),

            // Pending logistics requests
            const SizedBox(height: 20),
            Text('Incoming Logistics Requests (${pendingLogistics.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF264653))),
            const SizedBox(height: 12),
            if (pendingLogistics.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No pending logistics requests.', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold))))
            else
              ...pendingLogistics.asMap().entries.map((e) {
                final req = e.value;
                return StaggeredEntrance(index: e.key + _warehouseData.length + 1, child: Padding(padding: const EdgeInsets.only(bottom: 14),
                  child: DeepGlassCard(padding: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.agriculture_rounded, color: Color(0xFF2A9D8F), size: 28),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(req.farmerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF264653))),
                        Text('${req.crop} · ${req.weightKg.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ])),
                      _LogisticsStatusBadge(status: req.status),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(child: Text(req.pickupAddress, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await repo.updateLogisticsStatus(req.id, 'Confirmed');
                          if (context.mounted) showMessage(context, appState.t('logistics_accepted'));
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(appState.t('accept'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton.icon(
                        onPressed: () => _schedulePickup(context, req),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(appState.t('schedule_pickup'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      )),
                    ]),
                  ])),
                ));
              }),
          ]),
        ));
      }),
    );
  }

  void _schedulePickup(BuildContext context, LogisticsRequest req) {
    final timeCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.transparent, contentPadding: EdgeInsets.zero,
      content: RevealCard(child: DeepGlassCard(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.schedule_rounded, size: 40, color: Color(0xFF2A9D8F)),
        const SizedBox(height: 12),
        Text(appState.t('schedule_pickup'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF264653)), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('${req.crop} · ${req.farmerName}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Pickup date & time (e.g., Tomorrow 9:00 AM)', prefixIcon: Icon(Icons.event_rounded, color: Color(0xFF2A9D8F)))),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            if (timeCtrl.text.trim().isEmpty) return;
            HapticFeedback.mediumImpact();
            Navigator.pop(ctx);
            await repo.updateLogisticsStatus(req.id, 'Scheduled', scheduledTime: timeCtrl.text.trim());
            if (context.mounted) showMessage(context, appState.t('pickup_scheduled'));
          },
          child: Text(appState.t('confirm_booking'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]))),
    ));
  }
}

// ==========================================
// PROFILE SCREEN
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(animation: appState, builder: (_, __) => Text(appState.t('profile'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
        backgroundColor: Colors.transparent, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: AnimatedBuilder(animation: appState, builder: (context, _) {
            final user = appState.currentUser;
            final role = user?.role ?? 'Public';
            final badge = appState.reputationBadge;
            return Column(children: [
              StaggeredEntrance(index: 0, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF2A9D8F).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 15))]),
                child: CircleAvatar(radius: 65, backgroundColor: const Color(0xFF2A9D8F),
                  child: Icon(role == 'Farmer' ? Icons.agriculture_rounded : role == 'Admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded, size: 70, color: Colors.white)))),
              const SizedBox(height: 16),
              StaggeredEntrance(index: 1, child: Text(user?.name ?? 'Admin', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF264653)))),
              StaggeredEntrance(index: 2, child: Text(role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54))),
              const SizedBox(height: 24),
              if (role == 'Public' || role == 'Farmer') ...[
                StaggeredEntrance(index: 3, child: DeepGlassCard(color: (badge['color'] as Color).withValues(alpha: 0.15),
                  border: Border.all(color: (badge['color'] as Color).withValues(alpha: 0.4), width: 2), padding: 16,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(badge['icon'] as IconData, color: badge['color'] as Color, size: 36),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${badge['label']} Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: badge['color'] as Color)),
                      Text('${user?.civicPoints ?? 0} ${appState.t('civic_points')}', style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                )),
                const SizedBox(height: 16),
              ],
              StaggeredEntrance(index: 4, child: DeepGlassCard(child: Column(children: [
                ListTile(leading: const Icon(Icons.phone_rounded, color: Color(0xFF2A9D8F)),
                    title: Text(appState.t('phone'), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(user?.phone.isNotEmpty == true ? user!.phone : 'N/A', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black87))),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.home_rounded, color: Color(0xFF2A9D8F)),
                    title: const Text('Address', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(user?.address.isNotEmpty == true ? user!.address : 'N/A', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black87))),
                if (user != null && user.email.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.email_rounded, color: Color(0xFF2A9D8F)),
                      title: const Text('Email', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(user.email, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black87))),
                ],
              ]))),
              const SizedBox(height: 32),
              StaggeredEntrance(index: 5, child: SizedBox(height: 60, width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE76F51), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    appState.logout();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Scaffold(
                      body: Stack(children: [AnimatedMeshBackground(), RoleSelectionScreen()]),
                    )), (route) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(appState.t('logout'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )),
              const SizedBox(height: 120),
            ]);
          }),
        ),
      )),
    );
  }
}