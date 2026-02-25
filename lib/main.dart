import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:ui' as ui;

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

bool demoMode = false;
LatLng? demoLocationOverride;

// ==========================================
// MOCK DATA
// ==========================================
const Map<String, Map<String, dynamic>> _mandiData = {
  'Erode': {
    'name': 'Erode APMC Mandi',
    'lat': 11.3410,
    'lng': 77.7172,
    'distance': '45 km',
  },
  'Sathyamangalam': {
    'name': 'Sathy Farmers Market',
    'lat': 11.5034,
    'lng': 77.2387,
    'distance': '2 km',
  },
  'Gobichettipalayam': {
    'name': 'Gobi APMC Mandi',
    'lat': 11.4520,
    'lng': 77.4350,
    'distance': '18 km',
  },
  'Coimbatore': {
    'name': 'Coimbatore APMC Mandi',
    'lat': 11.0168,
    'lng': 76.9558,
    'distance': '60 km',
  },
  'Salem': {
    'name': 'Salem APMC Mandi',
    'lat': 11.6643,
    'lng': 78.1460,
    'distance': '82 km',
  },
  'Default': {
    'name': 'Nearest Mandi (Demo)',
    'lat': 11.5034,
    'lng': 77.3000,
    'distance': '5 km',
  },
};

const Map<String, List<Map<String, dynamic>>> _agmarknetData = {
  'Erode': [
    {
      'name': 'Tomato',
      'price': 38.0,
      'predicted': 41.0,
      'demand': 'High',
      'history': [32.0, 34.0, 36.0, 35.0, 38.0],
    },
    {
      'name': 'Onion',
      'price': 28.0,
      'predicted': 25.0,
      'demand': 'Medium',
      'history': [25.0, 27.0, 29.0, 28.0, 28.0],
    },
    {
      'name': 'Banana',
      'price': 22.0,
      'predicted': 24.0,
      'demand': 'High',
      'history': [19.0, 20.0, 21.0, 21.5, 22.0],
    },
    {
      'name': 'Turmeric',
      'price': 95.0,
      'predicted': 102.0,
      'demand': 'High',
      'history': [88.0, 90.0, 92.0, 94.0, 95.0],
    },
    {
      'name': 'Coconut',
      'price': 18.0,
      'predicted': 17.0,
      'demand': 'Medium',
      'history': [20.0, 19.0, 18.5, 18.0, 18.0],
    },
  ],
  'Sathyamangalam': [
    {
      'name': 'Tomato',
      'price': 34.0,
      'predicted': 37.0,
      'demand': 'High',
      'history': [28.0, 30.0, 32.0, 33.0, 34.0],
    },
    {
      'name': 'Brinjal',
      'price': 24.0,
      'predicted': 27.0,
      'demand': 'High',
      'history': [20.0, 21.0, 22.0, 23.0, 24.0],
    },
    {
      'name': 'Banana',
      'price': 20.0,
      'predicted': 22.0,
      'demand': 'Medium',
      'history': [17.0, 18.0, 19.0, 19.5, 20.0],
    },
    {
      'name': 'Onion',
      'price': 26.0,
      'predicted': 23.0,
      'demand': 'Medium',
      'history': [24.0, 25.0, 26.0, 26.0, 26.0],
    },
    {
      'name': 'Coconut',
      'price': 16.0,
      'predicted': 18.0,
      'demand': 'High',
      'history': [14.0, 15.0, 15.5, 16.0, 16.0],
    },
  ],
  'Default': [
    {
      'name': 'Tomato',
      'price': 35.0,
      'predicted': 38.0,
      'demand': 'High',
      'history': [30.0, 31.0, 33.0, 34.0, 35.0],
    },
    {
      'name': 'Onion',
      'price': 25.0,
      'predicted': 22.0,
      'demand': 'Medium',
      'history': [22.0, 23.0, 25.0, 25.0, 25.0],
    },
    {
      'name': 'Potato',
      'price': 30.0,
      'predicted': 32.0,
      'demand': 'High',
      'history': [27.0, 28.0, 29.0, 30.0, 30.0],
    },
    {
      'name': 'Brinjal',
      'price': 20.0,
      'predicted': 24.0,
      'demand': 'High',
      'history': [16.0, 17.0, 18.0, 19.0, 20.0],
    },
    {
      'name': 'Banana',
      'price': 18.0,
      'predicted': 17.0,
      'demand': 'Medium',
      'history': [19.0, 18.5, 18.0, 18.0, 18.0],
    },
  ],
};

const List<Map<String, dynamic>> _warehouseData = [
  {
    'id': 'wh1',
    'name': 'Sathyamangalam Cold Storage',
    'location': 'Market Road, Sathy',
    'lat': 11.5034,
    'lng': 77.2387,
    'capacity': 500,
    'used': 320,
    'crops': ['Tomato', 'Onion', 'Banana'],
  },
  {
    'id': 'wh2',
    'name': 'Erode APMC Warehouse',
    'location': 'NH-544, Erode',
    'lat': 11.3410,
    'lng': 77.7172,
    'capacity': 800,
    'used': 450,
    'crops': ['Turmeric', 'Onion', 'Coconut'],
  },
  {
    'id': 'wh3',
    'name': 'Gobi Farmers Aggregation Center',
    'location': 'Bhavani Road, Gobichettipalayam',
    'lat': 11.4520,
    'lng': 77.4350,
    'capacity': 350,
    'used': 180,
    'crops': ['Sugarcane', 'Tomato', 'Potato'],
  },
];

const List<Map<String, dynamic>> _wardData = [
  {
    'id': 'w1',
    'name': 'Market Road Area',
    'ward': 'Ward 1',
    'officer': 'Mr. Rajan Kumar',
    'center_lat': 11.5034,
    'center_lng': 77.2387,
    'radius': 0.015,
    'resolved_month': 8,
    'open_issues': 3,
  },
  {
    'id': 'w2',
    'name': 'Bus Stand Colony',
    'ward': 'Ward 2',
    'officer': 'Ms. Priya Devi',
    'center_lat': 11.5090,
    'center_lng': 77.2410,
    'radius': 0.012,
    'resolved_month': 5,
    'open_issues': 1,
  },
  {
    'id': 'w3',
    'name': 'Bannari Road Junction',
    'ward': 'Ward 3',
    'officer': 'Mr. Selvam G',
    'center_lat': 11.4970,
    'center_lng': 77.2320,
    'radius': 0.018,
    'resolved_month': 12,
    'open_issues': 4,
  },
  {
    'id': 'w4',
    'name': 'Thalamalai Colony',
    'ward': 'Ward 4',
    'officer': 'Ms. Kavitha S',
    'center_lat': 11.5120,
    'center_lng': 77.2280,
    'radius': 0.014,
    'resolved_month': 7,
    'open_issues': 2,
  },
  {
    'id': 'w5',
    'name': 'Sathy Town Panchayat',
    'ward': 'Ward 5',
    'officer': 'Mr. Murugesan P',
    'center_lat': 11.5010,
    'center_lng': 77.2450,
    'radius': 0.020,
    'resolved_month': 15,
    'open_issues': 0,
  },
  {
    'id': 'w6',
    'name': 'Karattur Village',
    'ward': 'Ward 6',
    'officer': 'Mr. Anand R',
    'center_lat': 11.4890,
    'center_lng': 77.2510,
    'radius': 0.016,
    'resolved_month': 3,
    'open_issues': 5,
  },
];

final List<LatLng> _safeRoutePoints = [
  const LatLng(11.5034, 77.2387),
  const LatLng(11.5050, 77.2400),
  const LatLng(11.5070, 77.2415),
  const LatLng(11.5090, 77.2410),
  const LatLng(11.5110, 77.2430),
];

const List<Map<String, dynamic>> _govSchemes = [
  {
    'name': 'PM-KISAN',
    'category': 'Agriculture',
    'summary':
        '₹6,000/year direct income support to small farmers in 3 equal installments.',
    'eligibility': [
      'Land ownership records',
      'Aadhaar-linked bank account',
      'Small/marginal farmer',
    ],
    'url': 'https://pmkisan.gov.in',
  },
  {
    'name': 'PM Awas Yojana',
    'category': 'Housing',
    'summary':
        'Financial assistance for construction of pucca houses for homeless/kutcha house owners.',
    'eligibility': ['No pucca house', 'BPL family', 'Aadhaar card required'],
    'url': 'https://pmaymis.gov.in',
  },
  {
    'name': 'Ayushman Bharat',
    'category': 'Health',
    'summary':
        'Health coverage up to ₹5 lakh per family per year for secondary and tertiary care.',
    'eligibility': [
      'SECC database listed',
      'Valid Aadhaar',
      'No existing coverage',
    ],
    'url': 'https://pmjay.gov.in',
  },
  {
    'name': 'PMFBY (Crop Insurance)',
    'category': 'Agriculture',
    'summary':
        'Crop insurance scheme covering yield losses due to natural calamities, pests, diseases.',
    'eligibility': [
      'Farmer with crop loan',
      'Land records',
      'Aadhaar-bank link',
    ],
    'url': 'https://pmfby.gov.in',
  },
  {
    'name': 'Mid-Day Meal Scheme',
    'category': 'Education',
    'summary':
        'Free nutritious meal for students in government schools Classes 1–8.',
    'eligibility': ['Enrolled in govt school', 'Classes 1 to 8'],
    'url': 'https://mdm.nic.in',
  },
  {
    'name': 'Kisan Credit Card',
    'category': 'Agriculture',
    'summary':
        'Short-term credit for crop cultivation, post-harvest expenses, and maintenance of farm assets.',
    'eligibility': [
      'Active farmer',
      'Valid land records',
      'Good credit history',
    ],
    'url': 'https://www.nabard.org',
  },
  {
    'name': 'MGNREGS',
    'category': 'Employment',
    'summary':
        '100 days guaranteed wage employment per year for rural households.',
    'eligibility': [
      'Rural household',
      'Willing to do unskilled work',
      'Job card required',
    ],
    'url': 'https://nrega.nic.in',
  },
  {
    'name': 'Atal Pension Yojana',
    'category': 'Social Security',
    'summary':
        'Guaranteed pension of ₹1,000–₹5,000/month after age 60 for unorganised sector workers.',
    'eligibility': ['Age 18–40', 'Bank/post account', 'Aadhaar linked'],
    'url': 'https://npscra.nsdl.co.in',
  },
  {
    'name': 'PM Mudra Yojana',
    'category': 'Finance',
    'summary':
        'Loans up to ₹10 lakh for non-corporate, non-farm small/micro enterprises.',
    'eligibility': ['Non-farm business', 'Valid ID proof', 'Business plan'],
    'url': 'https://mudra.org.in',
  },
  {
    'name': "TN CM's Breakfast Scheme",
    'category': 'Education',
    'summary':
        'Free breakfast for government primary school students in Tamil Nadu.',
    'eligibility': ['TN govt school student', 'Classes 1–5'],
    'url': 'https://www.tnschools.gov.in',
  },
  {
    'name': 'Pradhan Mantri Vaya Vandana',
    'category': 'Social Security',
    'summary':
        'Pension scheme for senior citizens aged 60+, guaranteed return of 7.4% p.a.',
    'eligibility': ['Age 60+', 'Indian citizen', 'Maximum ₹15 lakh investment'],
    'url': 'https://licindia.in',
  },
  {
    'name': 'Sukanya Samriddhi Yojana',
    'category': 'Finance',
    'summary':
        'Savings scheme for girl child with 8.2% interest p.a. and tax benefits.',
    'eligibility': [
      'Girl child below 10',
      'Legal guardian opens account',
      'Post office/bank',
    ],
    'url': 'https://www.indiapost.gov.in',
  },
];

const List<Map<String, dynamic>> _examNotifications = [
  {
    'exam': 'TNPSC Group II',
    'date': 'March 2025',
    'apply_by': 'Jan 31, 2025',
    'url': 'https://www.tnpsc.gov.in',
  },
  {
    'exam': 'SSC CGL 2025',
    'date': 'April–May 2025',
    'apply_by': 'Feb 15, 2025',
    'url': 'https://ssc.nic.in',
  },
  {
    'exam': 'Railway NTPC 2025',
    'date': 'June 2025',
    'apply_by': 'Mar 10, 2025',
    'url': 'https://www.rrbchennai.gov.in',
  },
  {
    'exam': 'TNPSC Group IV',
    'date': 'July 2025',
    'apply_by': 'Apr 30, 2025',
    'url': 'https://www.tnpsc.gov.in',
  },
];

const List<Map<String, dynamic>> _helplines = [
  {'name': 'Emergency (Police)', 'number': '112', 'icon': 'police'},
  {'name': 'Ambulance / Medical', 'number': '108', 'icon': 'medical'},
  {'name': 'Women Helpline', 'number': '181', 'icon': 'women'},
  {'name': 'Child Helpline', 'number': '1098', 'icon': 'child'},
  {'name': 'Disaster Management', 'number': '1070', 'icon': 'disaster'},
  {'name': 'Cyber Crime', 'number': '1930', 'icon': 'cyber'},
];

const List<Map<String, dynamic>> _newsFeed = [
  {
    'title': 'New Water Pipeline Inaugurated',
    'body': 'Ward 3 residents to receive 24-hour water supply from June 20.',
    'category': 'Civic',
    'time': '2h ago',
  },
  {
    'title': 'Tomato Prices Expected to Rise',
    'body':
        'Agri dept forecasts 15% price increase due to pest damage in neighboring districts.',
    'category': 'Agriculture',
    'time': '4h ago',
  },
  {
    'title': 'Road Repair Drive — Ward 1',
    'body':
        'Market Road pothole repair work scheduled for June 15–18. Use alternate route.',
    'category': 'Ward',
    'time': '6h ago',
  },
  {
    'title': 'Free Soil Testing Camp',
    'body':
        'Dept of Agriculture conducting free soil testing at Sathy APMC on June 22.',
    'category': 'Agriculture',
    'time': '1d ago',
  },
  {
    'title': 'TNPSC Group II Notification Released',
    'body':
        'Apply before Jan 31. Visit tnpsc.gov.in for full details and syllabus.',
    'category': 'Exam',
    'time': '1d ago',
  },
  {
    'title': 'Women Safety Patrol Launched',
    'body':
        'New night patrol scheme covering all 6 wards. Dial 181 for immediate assistance.',
    'category': 'Safety',
    'time': '2d ago',
  },
];

const List<Map<String, dynamic>> _bankLoanInfo = [
  {
    'name': 'Kisan Credit Card (KCC)',
    'desc':
        'Flexible credit up to ₹3 lakh at 4–7% interest for crop cultivation & maintenance.',
    'eligibility': [
      'Farmer with land records',
      'Min 1 acre cultivation',
      'Aadhaar-bank link',
    ],
    'url': 'https://www.nabard.org/content.aspx?id=572',
  },
  {
    'name': 'NABARD Agricultural Loan',
    'desc':
        'Term loans for farm equipment, irrigation, land development via rural banks.',
    'eligibility': [
      'Agri/allied activity',
      'Valid ID & land docs',
      'Project feasibility',
    ],
    'url': 'https://www.nabard.org',
  },
  {
    'name': 'SBI Agri Gold Loan',
    'desc':
        'Loan against gold ornaments for urgent farm needs at competitive interest rates.',
    'eligibility': ['Gold ornaments as collateral', 'SBI account', 'Valid KYC'],
    'url': 'https://sbi.co.in/web/agri-rural/agriculture-banking/crop-loan',
  },
  {
    'name': 'TN Agricultural Cooperative Bank',
    'desc':
        'Short & medium term agricultural loans through district co-operative banks.',
    'eligibility': [
      'TN resident farmer',
      'Member of co-op society',
      'Land patta required',
    ],
    'url': 'https://www.tncoopbank.com',
  },
];

const List<String> _advisories = [
  '🌾 Tip: Apply neem oil spray to prevent early blight on tomato crops.',
  '💧 Water conservation: Use drip irrigation to save 30–50% water.',
  '🌡️ Heat alert: Temperatures above 38°C expected. Water crops before 7AM.',
  '📋 Reminder: PMFBY crop insurance enrollment closes June 30.',
  '🐛 Pest alert: Fall armyworm detected in maize fields — report to Agri Dept.',
  '💰 PM-KISAN 3rd installment being credited this week. Check your account.',
];

const List<String> _departments = [
  'Roads',
  'Water',
  'Sanitation',
  'Electricity',
  'Transport',
  'Public Works',
];
const List<String> _cropOptions = [
  'Tomato',
  'Onion',
  'Potato',
  'Brinjal',
  'Banana',
  'Sugarcane',
  'Turmeric',
  'Coconut',
  'Cauliflower',
  'Beans',
  'Other',
];
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
    // Profile Screen
'points': 'Points',
'citizen': 'Citizen',
'ward_leaderboard': 'Ward Leaderboard',
'language': 'Language',
'address': 'Address',
'profile_updated': 'Profile updated successfully!',

// Farmer Home Screen
'farmer': 'Farmer',
'best_crop': 'Best Crop Today',
'market_prices': 'Market Prices',
'view_all': 'View All',
'create': 'Create',

// Crop Doctor Screen
'crop_doctor': 'Crop Doctor',
'ai_powered': 'AI-powered leaf disease detection',
'take_photo': 'Take a Photo of the Leaf',
'photo_hint': 'Clear, well-lit photo gives best results',
'analyze': 'Analyze Crop',
'diagnosis': 'AI Diagnosis',
'history': 'Recent Diagnoses',

// Farmer Logistics Screen
'book_pickup': 'Book Pickup',
'my_requests': 'My Requests',
'weight': 'Load Weight (kg)',
'pickup_address': 'Pickup Address',
'select_warehouse': 'Select Warehouse',
'request_submitted': 'Pickup request submitted!',
'no_requests': 'No pickup requests yet.',

// Admin Dashboard Screen
'admin_dashboard': 'Admin Dashboard',
'total_reports': 'Total Reports',
'sla_breached': 'SLA Breached',
'broadcast_hint': 'Type a broadcast message...',
'broadcast_sent': 'Broadcast sent to all users!',
'assigned': 'Assigned',

// Admin Analytics Screen
'by_category': 'Issues by Category',
'by_ward': 'Issues by Ward',
'community_polls': 'Community Polls',
'ward_notices': 'Ward Notices',

// Market Screen
'prices': 'Prices',
'post_listing': 'Post Crop Listing',
'search_schemes': 'Search schemes...',
'no_schemes_found': 'No schemes found.',
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
    'connect_citizens':
        'Book a government-subsidized truck to transport your harvest to the market directly.',
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
    'high_density':
        'High density areas indicate severe infrastructure failure.',
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
    'delete_confirm':
        'This will permanently remove the user from the database.',
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
    'alert_on': "Alert set! You'll be notified when price rises.",
    'alert_off': 'Alert removed.',
    'set_alert': 'Set Alert',
    'crop_history': 'Diagnosis History',
    'clear_history': 'Clear History',
    'nearest_mandi': 'Nearest Mandi',
    'agmarknet_source': 'Prototype Price Data — Integration Planned',
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
    'schemes_portal': 'Schemes & Services',
    'exam_alerts': 'Exam Alerts',
    'safety': 'Safety & Helplines',
    'sos_hint': 'Press & Hold 3 sec for SOS',
    'sos_sent': 'SOS Alert Sent! Help is on the way.',
    'ward_card': 'Your Ward',
    'officer': 'Ward Officer',
    'news_feed': "Today's Updates",
    'best_opportunity': 'Best Opportunity Today',
    'offline_banner': 'Offline mode — data may not be current',
    'cooperative': 'Farmer Cooperative',
    'sell_board': 'Crop Listing Board',
    'bank_info': 'Farmer Loans & Banks',
    'dev_settings': 'Developer Settings',
    'demo_location': 'Set Demo Location',
    'demo_mode': 'Demo Mode (Crop Doctor)',
    'ward_ops': 'Ward Ops',
    'notice_board': 'Notice Board',
    'community_poll': 'Community Poll',
    'budget_tracker': 'Ward Budget',
    'broadcast': 'Broadcast Alert',
    'leaderboard': 'Ward Leaderboard',
    'add_notice': 'Add Notice',
    'vote': 'Vote',
    'mandi_compare': 'Compare Mandis',
    'navigate': 'Navigate',
    'sla_flag': 'Pending >7 days — SLA Breach!',
    'news': 'News Feed',
    'bank_loans': 'Loans & Banks',
    'eb_website': 'EB (TNEB)',
    'ration_card': 'Ration Portal',
    'eligibility': 'Check Eligibility',
    'advisories': 'Farm Advisories',
    'safe_route': 'Safe Route',
    'cooperative_group': 'Cooperative Group',
    'ward_logistics': 'Ward Logistics',
    'export_ward': 'Export Snapshot',
    'transport_timeline': 'Transport Timeline',
    'swipe_assign': 'Swipe to Assign',
    'join_cooperative': 'Join Cooperative',
    'create_cooperative': 'Create Group',
    'group_members': 'Group Members',
    'combined_weight': 'Combined Weight',
    'group_booking': 'Group Booking',
    'no_cooperative': 'No active cooperative groups.',
    'issue_resolved_anim': 'Issue Resolved!',
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
    // Profile Screen
'points': 'புள்ளிகள்',
'citizen': 'குடிமகன்',
'ward_leaderboard': 'வார்டு தரவரிசை',
'language': 'மொழி',
'address': 'முகவரி',
'profile_updated': 'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!',

// Farmer Home Screen
'farmer': 'விவசாயி',
'best_crop': 'இன்றைய சிறந்த பயிர்',
'market_prices': 'சந்தை விலைகள்',
'view_all': 'அனைத்தும் காண்க',
'create': 'உருவாக்கு',

// Crop Doctor Screen
'crop_doctor': 'பயிர் மருத்துவர்',
'ai_powered': 'AI-ஆல் இலை நோய் கண்டறிதல்',
'take_photo': 'இலையின் புகைப்படம் எடுக்கவும்',
'photo_hint': 'தெளிவான, நல்ல வெளிச்சத்தில் எடுக்கவும்',
'analyze': 'பயிரை பகுப்பாய்வு செய்',
'diagnosis': 'AI நோயறிதல்',
'history': 'சமீபத்திய நோயறிதல்கள்',

// Farmer Logistics Screen
'book_pickup': 'பிக்கப் பதிவு செய்',
'my_requests': 'என் கோரிக்கைகள்',
'weight': 'சுமை எடை (கிலோ)',
'pickup_address': 'எடுக்கும் இடம்',
'select_warehouse': 'கிடங்கு தேர்வு செய்',
'request_submitted': 'பிக்கப் கோரிக்கை சமர்ப்பிக்கப்பட்டது!',
'no_requests': 'பிக்கப் கோரிக்கைகள் இல்லை.',

// Admin Dashboard Screen
'admin_dashboard': 'நிர்வாக கட்டுப்பாட்டகம்',
'total_reports': 'மொத்த புகார்கள்',
'sla_breached': 'SLA மீறல்',
'broadcast_hint': 'ஒளிபரப்பு செய்தி தட்டச்சு செய்யவும்...',
'broadcast_sent': 'அனைத்து பயனர்களுக்கும் அனுப்பப்பட்டது!',
'assigned': 'ஒதுக்கப்பட்டது',

// Admin Analytics Screen
'by_category': 'வகை வாரியான புகார்கள்',
'by_ward': 'வார்டு வாரியான புகார்கள்',
'community_polls': 'சமூக வாக்கெடுப்புகள்',
'ward_notices': 'வார்டு அறிவிப்புகள்',

// Market Screen
'prices': 'விலைகள்',
'post_listing': 'பயிர் விற்பனை பதிவு செய்',
'search_schemes': 'திட்டங்களை தேடுக...',
'no_schemes_found': 'திட்டங்கள் எதுவும் கிடைக்கவில்லை.',
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
    'connect_citizens':
        'உங்கள் அறுவடையை சந்தைக்கு கொண்டு செல்ல அரசு மானிய டிரக்கை பதிவு செய்யவும்.',
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
    'high_density':
        'அதிக அடர்த்தி பகுதிகள் உள்கட்டமைப்பு தோல்வியைக் குறிக்கின்றன.',
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
    'zero_desc':
        'குடிமக்கள் புதிய புகார்களை சமர்ப்பிக்கும் வரை காத்திருக்கிறோம்.',
    'edit_profile': 'சுயவிவரம் திருத்து',
    'name': 'பெயர்',
    'no_firebase': 'நேரடி பயனர் பட்டியலுக்கு Firebase தேவை.',
    'add_title': 'புகாருக்கு ஒரு தலைப்பு சேர்க்கவும்.',
    'report_submitted':
        'புகார் சமர்ப்பிக்கப்பட்டது! நிர்வாகி ஆய்வுக்காக காத்திருக்கிறது.',
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
    'agmarknet_source': 'முன்மாதிரி விலை தரவு — இணைப்பு திட்டமிடப்பட்டது',
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
    'schemes_portal': 'திட்டங்கள் மற்றும் சேவைகள்',
    'exam_alerts': 'தேர்வு அறிவிப்புகள்',
    'safety': 'பாதுகாப்பு மற்றும் உதவி',
    'sos_hint': 'SOS-க்கு 3 வினாடி அழுத்திப் பிடி',
    'sos_sent': 'SOS அனுப்பப்பட்டது! உதவி வருகிறது.',
    'ward_card': 'உங்கள் வார்டு',
    'officer': 'வார்டு அதிகாரி',
    'news_feed': 'இன்றைய புதுப்பிப்புகள்',
    'best_opportunity': 'இன்றைய சிறந்த வாய்ப்பு',
    'offline_banner': 'ஆஃப்லைன் பயன்முறை — தரவு புதுப்பிக்கப்படாமல் இருக்கலாம்',
    'cooperative': 'விவசாய கூட்டுறவு',
    'sell_board': 'பயிர் விற்பனை பலகை',
    'bank_info': 'விவசாயி கடன் மற்றும் வங்கிகள்',
    'dev_settings': 'டெவலப்பர் அமைப்புகள்',
    'demo_location': 'டெமோ இருப்பிட அமைப்பு',
    'demo_mode': 'டெமோ பயன்முறை (பயிர் மருத்துவர்)',
    'ward_ops': 'வார்டு நடவடிக்கைகள்',
    'notice_board': 'அறிவிப்பு பலகை',
    'community_poll': 'சமூக வாக்கெடுப்பு',
    'budget_tracker': 'வார்டு பட்ஜெட்',
    'broadcast': 'ஒளிபரப்பு எச்சரிக்கை',
    'leaderboard': 'வார்டு தரவரிசை',
    'add_notice': 'அறிவிப்பு சேர்',
    'vote': 'வாக்களி',
    'mandi_compare': 'மண்டி ஒப்பீடு',
    'navigate': 'வழிநடத்து',
    'sla_flag': 'நிலுவையில் >7 நாட்கள் — SLA மீறல்!',
    'news': 'செய்திகள்',
    'bank_loans': 'கடன் & வங்கிகள்',
    'eb_website': 'EB (TNEB)',
    'ration_card': 'ரேஷன் போர்டல்',
    'eligibility': 'தகுதி சரிபார்',
    'advisories': 'விவசாய ஆலோசனை',
    'safe_route': 'பாதுகாப்பான பாதை',
    'cooperative_group': 'கூட்டுறவு குழு',
    'ward_logistics': 'வார்டு தளவாடம்',
    'export_ward': 'தரவிறக்கம்',
    'transport_timeline': 'போக்குவரத்து நிலை',
    'swipe_assign': 'ஒதுக்க ஸ்வைப்',
    'join_cooperative': 'குழுவில் சேர்',
    'create_cooperative': 'குழு உருவாக்கு',
    'group_members': 'குழு உறுப்பினர்கள்',
    'combined_weight': 'மொத்த எடை',
    'group_booking': 'குழு பதிவு',
    'no_cooperative': 'கூட்டுறவு குழுக்கள் இல்லை.',
    'issue_resolved_anim': 'சிக்கல் தீர்க்கப்பட்டது!',
  },
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
  String? wardId;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    required this.password,
    this.civicPoints = 0,
    this.wardId,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'role': role,
    'name': name,
    'phone': phone,
    'address': address,
    'email': email,
    'password': password,
    'civicPoints': civicPoints,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] ?? '',
    role: map['role'] ?? 'Public',
    name: map['name'] ?? 'Citizen',
    phone: map['phone'] ?? '',
    address: map['address'] ?? '',
    email: map['email'] ?? '',
    password: map['password'] ?? '',
    civicPoints: map['civicPoints'] ?? 0,
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
  String status;
  String? department;
  String? wardId;
  String? wardName;
  DateTime? assignedAt;
  final DateTime createdAt;
  int upvotes;

  CivicReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.desc,
    required this.category,
    required this.loc,
    this.address,
    this.imagePath,
    this.status = 'Pending',
    this.department,
    this.wardId,
    this.wardName,
    this.assignedAt,
    DateTime? createdAt,
    this.upvotes = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isSlaBreached =>
      status == 'Pending' && DateTime.now().difference(createdAt).inDays >= 7;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'desc': desc,
    'category': category,
    'lat': loc.latitude,
    'lng': loc.longitude,
    'address': address,
    'status': status,
    'department': department,
    'wardId': wardId,
    'wardName': wardName,
    'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
    'upvotes': upvotes,
  };
}

class CropItem {
  final String name;
  final double currentPrice;
  final double predictedPrice;
  final String demand;
  final List<double> history;
  CropItem(
    this.name,
    this.currentPrice,
    this.predictedPrice,
    this.demand, {
    this.history = const [],
  });
}

class DiagnosisEntry {
  final String imagePath;
  final String diagnosis;
  final DateTime timestamp;
  DiagnosisEntry({
    required this.imagePath,
    required this.diagnosis,
    required this.timestamp,
  });
}

class LogisticsRequest {
  final String id;
  final String farmerId;
  final String farmerName;
  final String crop;
  final double weightKg;
  final String pickupAddress;
  final LatLng pickupLoc;
  final String? warehouseId;
  String status;
  String? scheduledTime;
  String? groupId;

  LogisticsRequest({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.crop,
    required this.weightKg,
    required this.pickupAddress,
    required this.pickupLoc,
    this.warehouseId,
    this.status = 'Requested',
    this.scheduledTime,
    this.groupId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'farmerId': farmerId,
    'farmerName': farmerName,
    'crop': crop,
    'weightKg': weightKg,
    'pickupAddress': pickupAddress,
    'pickupLat': pickupLoc.latitude,
    'pickupLng': pickupLoc.longitude,
    'warehouseId': warehouseId,
    'status': status,
    'scheduledTime': scheduledTime,
    'groupId': groupId,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory LogisticsRequest.fromMap(Map<String, dynamic> map) =>
      LogisticsRequest(
        id: map['id'] ?? '',
        farmerId: map['farmerId'] ?? '',
        farmerName: map['farmerName'] ?? '',
        crop: map['crop'] ?? '',
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
        pickupAddress: map['pickupAddress'] ?? '',
        pickupLoc: LatLng(
          (map['pickupLat'] as num?)?.toDouble() ?? 0,
          (map['pickupLng'] as num?)?.toDouble() ?? 0,
        ),
        warehouseId: map['warehouseId'],
        status: map['status'] ?? 'Requested',
        scheduledTime: map['scheduledTime'],
        groupId: map['groupId'],
      );
}

class AppNotification {
  final String id;
  final String targetUid;
  final String title;
  final String body;
  final String type;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.targetUid,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'targetUid': targetUid,
    'title': title,
    'body': body,
    'type': type,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] ?? '',
    targetUid: map['targetUid'] ?? '',
    title: map['title'] ?? '',
    body: map['body'] ?? '',
    type: map['type'] ?? '',
    isRead: map['isRead'] ?? false,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class WardNotice {
  final String id;
  final String title;
  final String body;
  final String wardId;
  final DateTime createdAt;

  WardNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.wardId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'wardId': wardId,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory WardNotice.fromMap(Map<String, dynamic> m) => WardNotice(
    id: m['id'] ?? '',
    title: m['title'] ?? '',
    body: m['body'] ?? '',
    wardId: m['wardId'] ?? '',
    createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class PollOption {
  final String label;
  int votes;
  PollOption(this.label, {this.votes = 0});
}

class CropListing {
  final String id;
  final String farmerId;
  final String farmerName;
  final String crop;
  final double pricePerKg;
  final double quantityKg;
  final String location;
  final DateTime createdAt;

  CropListing({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.crop,
    required this.pricePerKg,
    required this.quantityKg,
    required this.location,
    required this.createdAt,
  });
}

class FarmerCooperative {
  final String id;
  final String wardId;
  final String crop;
  final List<String> farmerIds;
  final List<String> farmerNames;
  final double totalWeightKg;
  String status;

  FarmerCooperative({
    required this.id,
    required this.wardId,
    required this.crop,
    required this.farmerIds,
    required this.farmerNames,
    required this.totalWeightKg,
    this.status = 'Open',
  });
}

// ==========================================
// STATE MANAGEMENT
// ==========================================
class AppState extends ChangeNotifier {
  String lang = 'en';
  String t(String k) => i18n[lang]?[k] ?? i18n['en']?[k] ?? k;
  void toggleLang() {
    lang = lang == 'en' ? 'ta' : 'en';
    notifyListeners();
  }
void refreshProfile() {
  notifyListeners();
}
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

  bool isOffline = false;
  bool sosActive = false;
  String? activeBroadcast;

  int _advisoryIndex = 0;
  String get currentAdvisory =>
      _advisories[_advisoryIndex % _advisories.length];
  Timer? _advisoryTimer;

  void startAdvisoryRotation() {
    _advisoryTimer?.cancel();
    _advisoryTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _advisoryIndex++;
      notifyListeners();
    });
  }

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  StreamSubscription<QuerySnapshot>? _notifStream;

  final List<FarmerCooperative> cooperatives = [
    FarmerCooperative(
      id: 'cg1',
      wardId: 'w1',
      crop: 'Tomato',
      farmerIds: ['f1', 'f2'],
      farmerNames: ['Murugan K', 'Selvi R'],
      totalWeightKg: 700,
      status: 'Open',
    ),
    FarmerCooperative(
      id: 'cg2',
      wardId: 'w3',
      crop: 'Onion',
      farmerIds: ['f3'],
      farmerNames: ['Balu S'],
      totalWeightKg: 300,
      status: 'Open',
    ),
  ];

  final List<WardNotice> wardNotices = [
    WardNotice(
      id: 'wn1',
      title: 'Road Repair Scheduled',
      body:
          'Market Road repair work from June 10–12. Please use alternate route.',
      wardId: 'w1',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    WardNotice(
      id: 'wn2',
      title: 'Water Supply Disruption',
      body:
          'No water supply on June 11 for maintenance. Store water in advance.',
      wardId: 'w2',
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),
    WardNotice(
      id: 'wn3',
      title: 'Community Meeting',
      body: 'Ward 5 community meeting at Town Hall, June 15 at 6 PM.',
      wardId: 'w5',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final Map<String, Map<String, dynamic>> wardBudget = {
    'Roads': {'allocated': 500000, 'spent': 320000},
    'Water': {'allocated': 300000, 'spent': 180000},
    'Sanitation': {'allocated': 200000, 'spent': 150000},
    'Electricity': {'allocated': 150000, 'spent': 90000},
  };

  final List<Map<String, dynamic>> polls = [
    {
      'id': 'p1',
      'question': 'Which area needs road repair most urgently?',
      'options': [
        PollOption('Market Road'),
        PollOption('Bus Stand Area'),
        PollOption('Bannari Junction'),
      ],
      'votedBy': <String>{},
    },
    {
      'id': 'p2',
      'question': 'What new facility should be added to Ward 5?',
      'options': [
        PollOption('Public Library'),
        PollOption('Sports Ground'),
        PollOption('Health Centre'),
      ],
      'votedBy': <String>{},
    },
  ];

  final List<CropListing> cropListings = [
    CropListing(
      id: 'cl1',
      farmerId: 'f1',
      farmerName: 'Murugan K',
      crop: 'Tomato',
      pricePerKg: 33.0,
      quantityKg: 500.0,
      location: 'Sathy',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CropListing(
      id: 'cl2',
      farmerId: 'f2',
      farmerName: 'Selvi R',
      crop: 'Onion',
      pricePerKg: 24.0,
      quantityKg: 200.0,
      location: 'Gobi',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    CropListing(
      id: 'cl3',
      farmerId: 'f3',
      farmerName: 'Balu S',
      crop: 'Banana',
      pricePerKg: 19.0,
      quantityKg: 800.0,
      location: 'Erode',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  void login(AppUser user) {
    currentUser = user;
    navIndex = 0;
    fetchWeather();
    _detectDistrict();
    _listenToNotifications();
    final nearest = _findNearestWard(userLocation);
    if (nearest != null) {
      currentUser!.wardId = nearest;
    }
    startAdvisoryRotation();
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
    _advisoryTimer?.cancel();
    sosActive = false;
    activeBroadcast = null;
    notifyListeners();
  }

  void setNav(int i) {
    HapticFeedback.selectionClick();
    navIndex = i;
    notifyListeners();
  }

  void addPoints(int pts) {
    if (currentUser != null) {
      currentUser!.civicPoints += pts;
      notifyListeners();
      _syncPointsToFirestore();
    }
  }

  void _syncPointsToFirestore() {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'civicPoints': currentUser!.civicPoints});
      }
    } catch (e) {
      debugPrint('Points sync failed: $e');
    }
  }

  void updateLocation(LatLng l) {
    userLocation = l;
    final nearest = _findNearestWard(l);
    if (nearest != null && currentUser != null) {
      currentUser!.wardId = nearest;
    }
    notifyListeners();
  }

  void togglePriceAlert(String cropName) {
    priceAlerts[cropName] = !(priceAlerts[cropName] ?? false);
    notifyListeners();
  }

  void addDiagnosis(DiagnosisEntry entry) {
    diagnosisHistory.insert(0, entry);
    if (diagnosisHistory.length > 5) {
      diagnosisHistory.removeLast();
    }
    notifyListeners();
  }

  void clearDiagnosisHistory() {
    diagnosisHistory.clear();
    notifyListeners();
  }

  Future<void> triggerSOS() async {
    sosActive = true;
    HapticFeedback.vibrate();
    notifyListeners();
    await sendNotification(
      targetUid: 'admin',
      title: '🚨 SOS ALERT — ${currentUser?.name ?? "Unknown"}',
      body:
          'Emergency at ${userLocation.latitude.toStringAsFixed(4)}, ${userLocation.longitude.toStringAsFixed(4)}',
      type: 'sos',
    );
    await Future.delayed(const Duration(seconds: 3));
    sosActive = false;
    notifyListeners();
  }

  void setBroadcast(String? msg) {
    activeBroadcast = msg;
    notifyListeners();
  }

  void votePoll(int pollIndex, int optionIndex) {
    final uid = currentUser?.uid ?? '';
    final poll = polls[pollIndex];
    final votedBy = poll['votedBy'] as Set<String>;
    if (votedBy.contains(uid)) return;
    (poll['options'] as List<PollOption>)[optionIndex].votes++;
    votedBy.add(uid);
    notifyListeners();
  }

  void addWardNotice(WardNotice n) {
    wardNotices.insert(0, n);
    notifyListeners();
  }

  void joinCooperative(String groupId) {
    final idx = cooperatives.indexWhere((c) => c.id == groupId);
    if (idx == -1) return;
    final uid = currentUser?.uid ?? '';
    final name = currentUser?.name ?? '';
    if (!cooperatives[idx].farmerIds.contains(uid)) {
      cooperatives[idx].farmerIds.add(uid);
      cooperatives[idx].farmerNames.add(name);
      notifyListeners();
    }
  }

  void createCooperative(String crop, double weightKg) {
    final coop = FarmerCooperative(
      id: 'cg_${DateTime.now().millisecondsSinceEpoch}',
      wardId: currentUser?.wardId ?? 'w1',
      crop: crop,
      farmerIds: [currentUser?.uid ?? ''],
      farmerNames: [currentUser?.name ?? ''],
      totalWeightKg: weightKg,
    );
    cooperatives.insert(0, coop);
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    if (Firebase.apps.isNotEmpty && currentUser != null) {
      for (final n in _notifications) {
        try {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(n.id)
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
        if (role == 'Admin') {
          targetUids.add('admin');
        }
        _notifStream?.cancel();
        _notifStream = FirebaseFirestore.instance
            .collection('notifications')
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
    } catch (e) {
      debugPrint('Notifications listener error: $e');
    }
  }

  Future<void> _detectDistrict() async {
    final loc = demoLocationOverride ?? userLocation;
    try {
      final placemarks = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
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
    } catch (_) {
      detectedDistrict = 'Default';
    }
    notifyListeners();
  }

  Future<void> prepareReportAt(LatLng loc) async {
    reportDraftLocation = loc;
    reportDraftAddress = t('loading');
    notifyListeners();
    try {
      final placemarks = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      ).timeout(const Duration(seconds: 8));
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
        ].where((s) => s != null && s.isNotEmpty).toList();
        reportDraftAddress = parts.isNotEmpty
            ? parts.join(', ')
            : 'Unknown Location';
      } else {
        reportDraftAddress = 'Unknown Location';
      }
    } on TimeoutException {
      reportDraftAddress = 'Address unavailable (GPS only)';
    } catch (_) {
      reportDraftAddress = 'Address unavailable (GPS only)';
    }
    notifyListeners();
  }

  Future<void> fetchWeather() async {
    if (openWeatherApiKey.isEmpty ||
        openWeatherApiKey.startsWith('OPEN_WEATHER')) {
      final mock = ['32°C', '29°C', '35°C'];
      final descs = ['Clear Sky', 'Partly Cloudy', 'Sunny'];
      final idx = DateTime.now().hour % 3;
      weatherTemp = mock[idx];
      weatherDesc = descs[idx];
      weatherIcon = Icons.wb_sunny_rounded;
      notifyListeners();
      return;
    }
    weatherLoading = true;
    notifyListeners();
    final loc = demoLocationOverride ?? userLocation;
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${loc.latitude}&lon=${loc.longitude}&units=metric&appid=$openWeatherApiKey';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        weatherTemp = '${(data['main']['temp'] as num).round()}°C';
        weatherDesc = data['weather'][0]['main'] as String;
        weatherIcon = _weatherIcon(weatherDesc);
      } else {
        weatherTemp = '32°C';
        weatherDesc = 'Clear Sky';
        weatherIcon = Icons.wb_sunny_rounded;
      }
    } catch (_) {
      weatherTemp = '32°C';
      weatherDesc = 'Clear Sky';
      weatherIcon = Icons.wb_sunny_rounded;
    } finally {
      weatherLoading = false;
      notifyListeners();
    }
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
    if (pts > 500) {
      return {
        'label': 'Gold',
        'icon': Icons.workspace_premium_rounded,
        'color': const Color(0xFFFFD700),
      };
    }
    if (pts >= 200) {
      return {
        'label': 'Silver',
        'icon': Icons.military_tech_rounded,
        'color': const Color(0xFFC0C0C0),
      };
    }
    return {
      'label': 'Bronze',
      'icon': Icons.emoji_events_rounded,
      'color': const Color(0xFFCD7F32),
    };
  }

  List<Map<String, dynamic>> get wardLeaderboard {
    final list = List<Map<String, dynamic>>.from(_wardData);
    list.sort(
      (a, b) =>
          (b['resolved_month'] as int).compareTo(a['resolved_month'] as int),
    );
    return list;
  }
}

final appState = AppState();

Future<void> sendNotification({
  required String targetUid,
  required String title,
  required String body,
  required String type,
}) async {
  try {
    if (Firebase.apps.isNotEmpty) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final notif = AppNotification(
        id: id,
        targetUid: targetUid,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .set(notif.toMap());
    }
  } catch (e) {
    debugPrint('Notification send error: $e');
  }
}

String? _findNearestWard(LatLng loc) {
  String? nearestId;
  double minDist = double.infinity;
  for (final ward in _wardData) {
    final dLat = loc.latitude - (ward['center_lat'] as double);
    final dLng = loc.longitude - (ward['center_lng'] as double);
    final dist = math.sqrt(dLat * dLat + dLng * dLng);
    if (dist < minDist) {
      minDist = dist;
      nearestId = ward['id'] as String;
    }
  }
  return nearestId;
}

String? _wardNameFromId(String? id) {
  if (id == null) return null;
  try {
    return _wardData.firstWhere((w) => w['id'] == id)['name'] as String;
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _wardDataFromId(String? id) {
  if (id == null) return null;
  try {
    return _wardData.firstWhere((w) => w['id'] == id);
  } catch (_) {
    return null;
  }
}

// ==========================================
// DATA REPOSITORY
// ==========================================
class DataRepository extends ChangeNotifier {
  final List<CivicReport> _reports = [];
  Future<void> deleteReport(String id) async {
  _reports.removeWhere((r) => r.id == id);
  notifyListeners();
  try {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseFirestore.instance.collection('reports').doc(id).delete();
    }
  } catch (e) {
    debugPrint('Delete report error: $e');
  }
}
  final List<LogisticsRequest> _logistics = [];
  List<CropItem> crops = [
    CropItem(
      'Tomato',
      35.0,
      38.0,
      'High',
      history: [30.0, 31.0, 33.0, 34.0, 35.0],
    ),
    CropItem(
      'Onion',
      25.0,
      22.0,
      'Medium',
      history: [22.0, 23.0, 25.0, 25.0, 25.0],
    ),
    CropItem(
      'Potato',
      30.0,
      32.0,
      'High',
      history: [27.0, 28.0, 29.0, 30.0, 30.0],
    ),
    CropItem(
      'Brinjal',
      20.0,
      24.0,
      'High',
      history: [16.0, 17.0, 18.0, 19.0, 20.0],
    ),
    CropItem(
      'Banana',
      18.0,
      17.0,
      'Medium',
      history: [19.0, 18.5, 18.0, 18.0, 18.0],
    ),
  ];

  List<CivicReport> get reports => List.unmodifiable(_reports);
  List<LogisticsRequest> get logistics => List.unmodifiable(_logistics);

  CropItem? get bestOpportunity {
    if (crops.isEmpty) return null;
    return crops.reduce(
      (a, b) =>
          (b.predictedPrice - b.currentPrice) >
              (a.predictedPrice - a.currentPrice)
          ? b
          : a,
    );
  }

  DataRepository() {
    _listenToFirebaseReports();
    _listenToLogistics();
    _seedDemoData();
  }

  Future<void> _seedDemoData() async {
    if (Firebase.apps.isEmpty) {
      _reports.addAll([
        CivicReport(
          id: 'demo1',
          userId: 'demo',
          title: 'Large Pothole on Main Road',
          desc: 'Near market junction',
          category: 'Roads',
          loc: const LatLng(11.5030, 77.2390),
          address: 'Market Road, Sathy',
          status: 'Pending',
          wardId: 'w1',
          wardName: 'Market Road Area',
          createdAt: DateTime.now().subtract(const Duration(days: 9)),
        ),
        CivicReport(
          id: 'demo2',
          userId: 'demo',
          title: 'Street Light Not Working',
          desc: '3 lights on Bus Stand Road are off',
          category: 'Electricity',
          loc: const LatLng(11.5085, 77.2415),
          address: 'Bus Stand Colony',
          status: 'Assigned',
          department: 'Electricity',
          wardId: 'w2',
          wardName: 'Bus Stand Colony',
        ),
        CivicReport(
          id: 'demo3',
          userId: 'demo',
          title: 'Garbage Not Collected',
          desc: 'Overflowing bin near school',
          category: 'Garbage',
          loc: const LatLng(11.4975, 77.2325),
          address: 'Bannari Road',
          status: 'Resolved',
          wardId: 'w3',
          wardName: 'Bannari Road Junction',
        ),
      ]);
      _logistics.addAll([
        LogisticsRequest(
          id: 'log1',
          farmerId: 'f1',
          farmerName: 'Murugan K',
          crop: 'Tomato',
          weightKg: 300,
          pickupAddress: 'Farm Road, Sathy',
          pickupLoc: const LatLng(11.5010, 77.2400),
          status: 'Requested',
        ),
        LogisticsRequest(
          id: 'log2',
          farmerId: 'f2',
          farmerName: 'Selvi R',
          crop: 'Onion',
          weightKg: 500,
          pickupAddress: 'Karattur Village',
          pickupLoc: const LatLng(11.4890, 77.2510),
          status: 'Scheduled',
          scheduledTime: 'Tomorrow 8:00 AM',
        ),
      ]);
      notifyListeners();
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        final mockReports = [
          {
            'id': 'seed1',
            'userId': 'seed',
            'title': 'Large Pothole on Main Road',
            'desc': 'Near market junction, dangerous at night',
            'category': 'Roads',
            'lat': 11.5030,
            'lng': 77.2390,
            'address': 'Market Road, Sathy',
            'status': 'Pending',
            'wardId': 'w1',
            'wardName': 'Market Road Area',
            'upvotes': 5,
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 9)),
            ),
          },
          {
            'id': 'seed2',
            'userId': 'seed',
            'title': 'Street Light Not Working',
            'desc': '3 lights on Bus Stand Road are off',
            'category': 'Electricity',
            'lat': 11.5085,
            'lng': 77.2415,
            'address': 'Bus Stand Colony',
            'status': 'Assigned',
            'department': 'Electricity',
            'wardId': 'w2',
            'wardName': 'Bus Stand Colony',
            'upvotes': 2,
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 3)),
            ),
          },
          {
            'id': 'seed3',
            'userId': 'seed',
            'title': 'Garbage Not Collected',
            'desc': 'Overflowing bin near school',
            'category': 'Garbage',
            'lat': 11.4975,
            'lng': 77.2325,
            'address': 'Bannari Road',
            'status': 'Resolved',
            'wardId': 'w3',
            'wardName': 'Bannari Road Junction',
            'upvotes': 8,
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5)),
            ),
          },
        ];
        for (final r in mockReports) {
          batch.set(
            FirebaseFirestore.instance
                .collection('reports')
                .doc(r['id'] as String),
            r,
          );
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Seed data error: $e');
    }
  }

  void _listenToFirebaseReports() {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('reports')
            .snapshots()
            .listen(
              (snap) {
                _reports.clear();
                for (final doc in snap.docs) {
                  final data = doc.data();
                  try {
                    final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
                    final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
                    _reports.add(
                      CivicReport(
                        id: data['id'] as String? ?? doc.id,
                        userId: data['userId'] as String? ?? '',
                        title: data['title'] as String? ?? 'Untitled',
                        desc: data['desc'] as String? ?? '',
                        category: data['category'] as String? ?? 'Other',
                        loc: LatLng(lat, lng),
                        address: data['address'] as String?,
                        imagePath: data['imageUrl'] as String?,
                        status: data['status'] as String? ?? 'Pending',
                        department: data['department'] as String?,
                        wardId: data['wardId'] as String?,
                        wardName: data['wardName'] as String?,
                        assignedAt: (data['assignedAt'] as Timestamp?)
                            ?.toDate(),
                        createdAt:
                            (data['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.now(),
                        upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error parsing report ${doc.id}: $e');
                  }
                }
                notifyListeners();
              },
              onError: (e) {
                debugPrint('Firestore listen error: $e');
              },
            );
      }
    } catch (e) {
      debugPrint('Firestore listener setup error: $e');
    }
  }

  void _listenToLogistics() {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('logistics_requests')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen(
              (snap) {
                _logistics.clear();
                for (final doc in snap.docs) {
                  try {
                    _logistics.add(LogisticsRequest.fromMap(doc.data()));
                  } catch (_) {}
                }
                notifyListeners();
              },
              onError: (e) {
                debugPrint('Logistics listen error: $e');
              },
            );
      }
    } catch (e) {
      debugPrint('Logistics listener error: $e');
    }
  }

  Future<bool> saveReport(CivicReport r, XFile? image) async {
    final wardId = _findNearestWard(r.loc);
    r.wardId = wardId;
    r.wardName = _wardNameFromId(wardId);
    _reports.add(r);
    notifyListeners();
    try {
      if (Firebase.apps.isNotEmpty) {
        String? imgUrl;
        if (image != null) {
          imgUrl = await _uploadImage(r.id, image);
        }
        await FirebaseFirestore.instance.collection('reports').doc(r.id).set({
          ...r.toMap(),
          'imageUrl': imgUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await sendNotification(
          targetUid: 'admin',
          title: 'New Issue Reported',
          body: '${r.category}: ${r.title}',
          type: 'new_report',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Firebase Save Failed: $e');
      return false;
    }
  }

  Future<String?> _uploadImage(String reportId, XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref('reports/$reportId.jpg');
      if (kIsWeb) {
        await ref.putData(await image.readAsBytes());
      } else {
        await ref.putFile(io.File(image.path));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image Upload Failed: $e');
      return null;
    }
  }

  Future<void> upvoteReport(String id) async {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].upvotes++;
      notifyListeners();
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance.collection('reports').doc(id).update(
            {'upvotes': FieldValue.increment(1)},
          );
        }
      } catch (_) {}
    }
  }

  Future<void> acceptAndAssignReport(String id, String department) async {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = 'Assigned';
      _reports[index].department = department;
      _reports[index].assignedAt = DateTime.now();
      notifyListeners();
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(id)
              .update({
                'status': 'Assigned',
                'department': department,
                'assignedAt': FieldValue.serverTimestamp(),
              });
          final report = _reports[index];
          await FirebaseFirestore.instance
              .collection('users')
              .doc(report.userId)
              .update({'civicPoints': FieldValue.increment(50)});
          await sendNotification(
            targetUid: report.userId,
            title: 'Report Accepted! +50 Points',
            body:
                'Your report "${report.title}" has been assigned to $department.',
            type: 'report_accepted',
          );
        }
      } catch (e) {
        debugPrint('Accept report error: $e');
      }
    }
  }

  Future<void> updateReportStatus(String id, String status) async {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = status;
      notifyListeners();
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance.collection('reports').doc(id).update(
            {'status': status},
          );
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
      } catch (e) {
        debugPrint('Status update sync failed: $e');
      }
    }
  }

  Future<bool> submitLogisticsRequest(LogisticsRequest req) async {
    _logistics.insert(0, req);
    notifyListeners();
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('logistics_requests')
            .doc(req.id)
            .set(req.toMap());
        await sendNotification(
          targetUid: 'admin',
          title: 'New Logistics Request',
          body:
              '${req.farmerName} requests pickup of ${req.weightKg}kg ${req.crop}',
          type: 'new_logistics',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Logistics save error: $e');
      return false;
    }
  }

  Future<void> updateLogisticsStatus(
    String id,
    String status, {
    String? scheduledTime,
  }) async {
    final index = _logistics.indexWhere((l) => l.id == id);
    if (index != -1) {
      _logistics[index].status = status;
      if (scheduledTime != null) {
        _logistics[index].scheduledTime = scheduledTime;
      }
      notifyListeners();
      try {
        if (Firebase.apps.isNotEmpty) {
          final updates = <String, dynamic>{'status': status};
          if (scheduledTime != null) {
            updates['scheduledTime'] = scheduledTime;
          }
          await FirebaseFirestore.instance
              .collection('logistics_requests')
              .doc(id)
              .update(updates);
          final req = _logistics[index];
          String notifTitle = '';
          String notifBody = '';
          if (status == 'Confirmed') {
            notifTitle = 'Logistics Confirmed!';
            notifBody = 'Your pickup for ${req.crop} has been confirmed.';
          } else if (status == 'Scheduled') {
            notifTitle = 'Pickup Scheduled!';
            notifBody =
                'Pickup for ${req.crop} scheduled at ${scheduledTime ?? ''}';
          } else if (status == 'Picked Up') {
            notifTitle = 'Crop Picked Up!';
            notifBody = 'Your ${req.crop} has been picked up successfully.';
          }
          if (notifTitle.isNotEmpty) {
            await sendNotification(
              targetUid: req.farmerId,
              title: notifTitle,
              body: notifBody,
              type: 'logistics_update',
            );
          }
        }
      } catch (e) {
        debugPrint('Logistics status update error: $e');
      }
    }
  }
  

  void loadLocalCropData(String district) {
    final localData = _agmarknetData[district] ?? _agmarknetData['Default']!;
    final rng = math.Random();
    crops = localData.map((d) {
      final variance = (rng.nextDouble() - 0.5) * 2;
      return CropItem(
        d['name'] as String,
        ((d['price'] as num).toDouble() + variance).clamp(1.0, 999.0),
        (d['predicted'] as num).toDouble(),
        d['demand'] as String,
        history: List<double>.from(
          (d['history'] as List).map((v) => (v as num).toDouble()),
        ),
      );
    }).toList();
    notifyListeners();
  }
}

final repo = DataRepository();
// ==========================================
// APP ENTRY POINT
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase Connected Successfully!');
  } catch (e) {
    debugPrint('Firebase connection failed. Offline mode. Error: $e');
  }
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
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF2A9D8F),
            scaffoldBackgroundColor: Colors.transparent,
            fontFamily: 'Roboto',
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          home: const Scaffold(
            body: Stack(
              children: [AnimatedMeshBackground(), RoleSelectionScreen()],
            ),
          ),
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
  final Widget child;
  final double padding;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;

  const DeepGlassCard({
    super.key,
    required this.child,
    this.padding = 24.0,
    this.borderRadius = 24.0,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class TappableGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double padding;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;

  const TappableGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = 24.0,
    this.borderRadius = 24.0,
    this.color,
    this.border,
  });

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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: DeepGlassCard(
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          color: widget.color,
          border: widget.border,
          child: widget.child,
        ),
      ),
    );
  }
}

void showMessage(BuildContext context, String message, {bool isError = false}) {
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError
          ? const Color(0xFFE76F51)
          : const Color(0xFF264653),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(20),
      elevation: 10,
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AnimatedCounterText extends StatefulWidget {
  final int value;
  final TextStyle style;

  const AnimatedCounterText({
    super.key,
    required this.value,
    required this.style,
  });

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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounterText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = IntTween(
        begin: old.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(_anim.value.toString(), style: widget.style),
    );
  }
}

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final int delayMs;

  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.index,
    this.delayMs = 80,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
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

class _RevealCardState extends State<RevealCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class ResolvedPulse extends StatefulWidget {
  final Widget child;
  const ResolvedPulse({super.key, required this.child});

  @override
  State<ResolvedPulse> createState() => _ResolvedPulseState();
}

class _ResolvedPulseState extends State<ResolvedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(count: 2);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}

// ==========================================
// MINI SPARKLINE
// ==========================================
class MiniSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const MiniSparkline({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox();
    return SizedBox(
      width: 60,
      height: 30,
      child: CustomPaint(painter: _SparkPainter(data, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparkPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final range = (maxVal - minVal).abs().clamp(0.001, double.infinity);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final ui.Path path = ui.Path();
    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - (size.height * (data[i] - minVal) / range);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ==========================================
// SOS BUTTON
// ==========================================
class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _pressing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startPress() {
    setState(() => _pressing = true);
    HapticFeedback.heavyImpact();
    _ctrl.forward();
    _timer = Timer(const Duration(seconds: 3), () async {
      await appState.triggerSOS();
      if (mounted) {
        showMessage(context, appState.t('sos_sent'));
        _ctrl.reset();
        setState(() => _pressing = false);
      }
    });
  }

  void _cancelPress() {
    _timer?.cancel();
    _ctrl.reverse();
    setState(() => _pressing = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startPress(),
      onLongPressEnd: (_) {
        if (_pressing) _cancelPress();
      },
      onLongPressCancel: () {
        if (_pressing) _cancelPress();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            if (_pressing)
              ...List.generate(
                2,
                (i) => Transform.scale(
                  scale: 1.0 + (_ctrl.value * 0.5 * (i + 1)),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withValues(
                          alpha: (1 - _ctrl.value * 0.5) * (0.5 - i * 0.2),
                        ),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.red.shade400, Colors.red.shade800],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_pressing)
                    CircularProgressIndicator(
                      value: _ctrl.value,
                      color: Colors.white,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// AUTH CHARACTER
// ==========================================
class _AuthCharacter extends StatefulWidget {
  final bool isTyping;
  final bool isPasswordVisible;
  final bool isLoading;

  const _AuthCharacter({
    required this.isTyping,
    required this.isPasswordVisible,
    required this.isLoading,
  });

  @override
  State<_AuthCharacter> createState() => _AuthCharacterState();
}

class _AuthCharacterState extends State<_AuthCharacter>
    with TickerProviderStateMixin {
  late AnimationController _wobble;
  late AnimationController _blink;
  late AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AuthCharacter old) {
    super.didUpdateWidget(old);
    if (widget.isPasswordVisible && !old.isPasswordVisible) {
      _blink.forward(from: 0).then((_) => _blink.reverse());
    }
  }

  @override
  void dispose() {
    _wobble.dispose();
    _blink.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_wobble, _blink, _bounce]),
      builder: (_, __) {
        final wobbleVal = widget.isLoading
            ? math.sin(_wobble.value * math.pi) * 6
            : 0.0;
        final bounceVal = widget.isTyping
            ? math.sin(_bounce.value * math.pi) * 4
            : 0.0;
        return Transform.translate(
          offset: Offset(wobbleVal, bounceVal),
          child: SizedBox(
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A9D8F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A9D8F).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 18,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Eye(
                        covered: !widget.isPasswordVisible && !widget.isTyping,
                        blinking: _blink.value > 0.3,
                      ),
                      const SizedBox(width: 14),
                      _Eye(
                        covered: !widget.isPasswordVisible && !widget.isTyping,
                        blinking: _blink.value > 0.3,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Container(
                          width: 24,
                          height: 10,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.9),
                                width: 3,
                              ),
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Eye extends StatelessWidget {
  final bool covered;
  final bool blinking;

  const _Eye({required this.covered, required this.blinking});

  @override
  Widget build(BuildContext context) {
    if (covered) {
      return Container(
        width: 12,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    if (blinking) {
      return Container(
        width: 12,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF264653),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TRANSPORT TIMELINE WIDGET
// ==========================================
class TransportTimeline extends StatelessWidget {
  final String currentStatus;

  const TransportTimeline({super.key, required this.currentStatus});

  static const _steps = ['Requested', 'Confirmed', 'Scheduled', 'Picked Up'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(currentStatus);
    return Row(
      children: _steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final done = i <= currentIndex;
        final isLast = i == _steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? const Color(0xFF2A9D8F)
                            : Colors.grey.shade300,
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : Icons.circle_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: done ? const Color(0xFF2A9D8F) : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done && i < currentIndex
                        ? const Color(0xFF2A9D8F)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ==========================================
// ROLE SELECTION SCREEN
// ==========================================
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    if (appState.currentUser != null) return const MainShell();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('app_name'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF264653),
                      ),
                    ),
                    Text(
                      t('subtitle'),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF264653).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    appState.toggleLang();
                    setState(() {});
                  },
                  child: DeepGlassCard(
                    padding: 8,
                    borderRadius: 12,
                    child: Text(
                      appState.lang == 'en' ? '🇮🇳 தமிழ்' : '🇬🇧 English',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              'Select Your Role',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF264653).withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              (
                'Public',
                Icons.people_rounded,
                t('role_public'),
                const Color(0xFF2A9D8F),
              ),
              (
                'Farmer',
                Icons.agriculture_rounded,
                t('role_farmer'),
                const Color(0xFF52B788),
              ),
              (
                'Admin',
                Icons.admin_panel_settings_rounded,
                t('role_admin'),
                const Color(0xFFE76F51),
              ),
            ].asMap().entries.map((entry) {
              final i = entry.key;
              final (role, icon, label, color) = entry.value;
              final selected = _selectedRole == role;
              return StaggeredEntrance(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TappableGlassCard(
                    onTap: () => setState(() => _selectedRole = role),
                    color: selected ? color.withValues(alpha: 0.2) : null,
                    border: selected
                        ? Border.all(color: color, width: 2)
                        : null,
                    padding: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          Icon(Icons.check_circle_rounded, color: color),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            if (_selectedRole != null)
              StaggeredEntrance(
                index: 3,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(role: _selectedRole!),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    t('login'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (_selectedRole == 'Public' || _selectedRole == 'Farmer')
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(
                      initialRole: _selectedRole!,
                    ),
                  ),
                ),
                child: Text(
                  _selectedRole == 'Farmer'
                      ? 'New farmer? Register here'
                      : t('new_citizen'),
                  style: const TextStyle(
                    color: Color(0xFF2A9D8F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      
          ],
    ),
      ),
    );
  }
}

// ==========================================
// LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _typing = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (phone.isEmpty || pass.isEmpty) {
      showMessage(context, appState.t('fill_all_fields'), isError: true);
      return;
    }
    if (widget.role != 'Admin' && phone.length != 10) {
      showMessage(context, appState.t('invalid_phone'), isError: true);
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (widget.role == 'Admin') {
      if (pass == adminMasterCode) {
        final adminUser = AppUser(
          uid: 'admin_master',
          role: 'Admin',
          name: 'Administrator',
          phone: phone,
          address: 'City Hall',
          email: 'admin@smartera.gov',
          password: pass,
          civicPoints: 9999,
        );
        appState.login(adminUser);
        if (mounted) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      } else {
        if (mounted) {
          showMessage(
            context,
            appState.t('invalid_credentials'),
            isError: true,
          );
        }
      }
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();
        if (!mounted) return;
        if (snap.docs.isEmpty) {
          showMessage(context, appState.t('user_not_found'), isError: true);
          setState(() => _loading = false);
          return;
        }
        final data = snap.docs.first.data();
        if (data['password'] != pass) {
          showMessage(
            context,
            appState.t('invalid_credentials'),
            isError: true,
          );
          setState(() => _loading = false);
          return;
        }
        final user = AppUser.fromMap(data);
        appState.login(user);
        if (mounted) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      } else {
        final demoUser = AppUser(
          uid: 'demo_${widget.role.toLowerCase()}',
          role: widget.role,
          name: widget.role == 'Farmer' ? 'Murugan Farmer' : 'Demo Citizen',
          phone: phone,
          address: 'Sathyamangalam',
          email: '',
          password: pass,
          civicPoints: 150,
        );
        appState.login(demoUser);
        if (mounted) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, appState.t('error_generic'), isError: true);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _AuthCharacter(
                    isTyping: _typing,
                    isPasswordVisible: !_obscure,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 24),
                  DeepGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${t('login')} — ${widget.role}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF264653),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          onChanged: (v) =>
                              setState(() => _typing = v.isNotEmpty),
                          decoration: InputDecoration(
                            labelText: t('phone'),
                            prefixIcon: const Icon(Icons.phone_rounded),
                            hintText: '10-digit mobile',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          onChanged: (v) =>
                              setState(() => _typing = v.isNotEmpty),
                          decoration: InputDecoration(
                            labelText: widget.role == 'Admin'
                                ? t('otp')
                                : t('password'),
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              t('forgot_password'),
                              style: const TextStyle(color: Color(0xFF2A9D8F)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A9D8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  t('login'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.role == 'Public')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: Text(
                          t('new_citizen'),
                          style: const TextStyle(
                            color: Color(0xFF2A9D8F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// REGISTER SCREEN
// ==========================================
class RegisterScreen extends StatefulWidget {
  final String initialRole;
  const RegisterScreen({super.key, this.initialRole = 'Public'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  
  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _addrCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (_nameCtrl.text.isEmpty ||
        _phoneCtrl.text.length != 10 ||
        _passCtrl.text.isEmpty ||
        _addrCtrl.text.isEmpty) {
      showMessage(context, appState.t('fill_all_fields'), isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final user = AppUser(
        uid: uid,
        role: widget.initialRole,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addrCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        civicPoints: 100,
      );
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(user.toMap());
      }
      appState.login(user);
      if (mounted) {
        showMessage(context, appState.t('registration_success'));
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, appState.t('error_generic'), isError: true);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DeepGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t('register'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF264653),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: t('full_name'),
                            prefixIcon: const Icon(Icons.person_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: t('phone'),
                            prefixIcon: const Icon(Icons.phone_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addrCtrl,
                          decoration: InputDecoration(
                            labelText: t('city_village'),
                            prefixIcon: const Icon(Icons.location_on_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: t('email_optional'),
                            prefixIcon: const Icon(Icons.email_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: t('password'),
                            prefixIcon: const Icon(Icons.lock_rounded),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A9D8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  t('register'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            t('already_account'),
                            style: const TextStyle(color: Color(0xFF2A9D8F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORGOT PASSWORD SCREEN
// ==========================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  String? _retrievedPassword;
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _getPassword() async {
    if (_phoneCtrl.text.length != 10) {
      showMessage(context, appState.t('invalid_phone'), isError: true);
      return;
    }
    setState(() {
      _loading = true;
      _retrievedPassword = null;
    });
    try {
      if (Firebase.apps.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: _phoneCtrl.text.trim())
            .limit(1)
            .get();
        if (!mounted) return;
        if (snap.docs.isEmpty) {
          showMessage(context, appState.t('user_not_found'), isError: true);
        } else {
          setState(
            () => _retrievedPassword =
                snap.docs.first.data()['password'] as String?,
          );
        }
      } else {
        setState(() => _retrievedPassword = 'demo123');
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, appState.t('error_generic'), isError: true);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DeepGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t('retrieve_password'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF264653),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: t('phone'),
                            prefixIcon: const Icon(Icons.phone_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _getPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A9D8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  t('get_password'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        if (_retrievedPassword != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2A9D8F,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.key_rounded,
                                  color: Color(0xFF2A9D8F),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _retrievedPassword!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF264653),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MAIN SHELL
// ==========================================
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final user = appState.currentUser!;
        final t = appState.t;
        Widget body;
        List<BottomNavigationBarItem> navItems;

        if (user.role == 'Admin') {
          final pages = [
            const AdminDashboardScreen(),
            const AdminAnalyticsScreen(),
            const AdminUsersScreen(),
            const AdminWarehouseScreen(),
            const ProfileScreen(),
          ];
          body = AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(appState.navIndex),
              child: pages[appState.navIndex.clamp(0, pages.length - 1)],
            ),
          );
          navItems = [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: t('dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_rounded),
              label: t('analytics'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_rounded),
              label: t('users'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.warehouse_rounded),
              label: t('warehouse'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: t('profile'),
            ),
          ];
        } else if (user.role == 'Farmer') {
          final pages = [
            const FarmerHomeScreen(),
            const MarketScreen(),
            const CropDoctorScreen(),
            const FarmerLogisticsScreen(),
            const ProfileScreen(),
          ];
          body = AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(appState.navIndex),
              child: pages[appState.navIndex.clamp(0, pages.length - 1)],
            ),
          );
          navItems = [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: t('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_rounded),
              label: t('market'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.local_hospital_rounded),
              label: t('doctor'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.local_shipping_rounded),
              label: t('logistics'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: t('profile'),
            ),
          ];
        } else {
          final pages = [
            const PublicHomeScreen(),
            const CivicMapScreen(),
            const ReportScreen(),
            const SchemesScreen(),
            const ProfileScreen(),
          ];
          body = AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(appState.navIndex),
              child: pages[appState.navIndex.clamp(0, pages.length - 1)],
            ),
          );
          navItems = [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: t('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_rounded),
              label: t('map'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_rounded),
              label: t('report'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_rounded),
              label: t('schemes'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: t('profile'),
            ),
          ];
        }

        return Scaffold(
          body: Stack(
            children: [
              const AnimatedMeshBackground(),
              Column(
                children: [
                  if (appState.activeBroadcast != null)
                    Container(
                      color: const Color(0xFFE76F51),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appState.activeBroadcast!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => appState.setBroadcast(null),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(child: body),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: BottomNavigationBar(
                  currentIndex: appState.navIndex.clamp(0, navItems.length - 1),
                  onTap: appState.setNav,
                  items: navItems,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: const Color(0xFF2A9D8F),
                  unselectedItemColor: Colors.grey,
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  elevation: 0,
                  selectedFontSize: 11,
                  unselectedFontSize: 10,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// PUBLIC HOME SCREEN
// ==========================================
class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      if (mounted) {
        appState.updateLocation(LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final user = appState.currentUser!;
    final wardData = _wardDataFromId(user.wardId);
    final badge = appState.reputationBadge;

    return AnimatedBuilder(
      animation: Listenable.merge([appState, repo]),
      builder: (context, _) {
        final userReports = repo.reports
            .where((r) => r.userId == user.uid)
            .toList();
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await appState.fetchWeather();
              if (mounted) setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                StaggeredEntrance(
                  index: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t('welcome')} ${user.name.split(' ').first}!',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF264653),
                              ),
                            ),
                            Text(
                              user.address,
                              style: TextStyle(
                                color: const Color(
                                  0xFF264653,
                                ).withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _NotifBell(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (badge['color'] as Color).withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              badge['icon'] as IconData,
                              color: badge['color'] as Color,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.civicPoints} pts',
                              style: TextStyle(
                                color: badge['color'] as Color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Advisory banner
                StaggeredEntrance(
                  index: 0,
                  child: AnimatedBuilder(
                    animation: appState,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF52B788).withValues(alpha: 0.2),
                            const Color(0xFF2A9D8F).withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF52B788).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFF52B788),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appState.currentAdvisory,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF264653),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Weather + Ward Card
                StaggeredEntrance(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: DeepGlassCard(
                          padding: 16,
                          child: Row(
                            children: [
                              Icon(
                                appState.weatherIcon,
                                color: const Color(0xFFE9C46A),
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appState.weatherTemp,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF264653),
                                    ),
                                  ),
                                  Text(
                                    appState.weatherDesc,
                                    style: TextStyle(
                                      color: const Color(
                                        0xFF264653,
                                      ).withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (wardData != null)
                        Expanded(
                          child: DeepGlassCard(
                            padding: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('ward_card'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(
                                      0xFF264653,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  wardData['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF264653),
                                  ),
                                ),
                                Text(
                                  wardData['officer'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2A9D8F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Quick Report Card
                StaggeredEntrance(
                  index: 2,
                  child: TappableGlassCard(
                    padding: 20,
                    onTap: () => appState.setNav(2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE76F51,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.report_problem_rounded,
                            color: Color(0xFFE76F51),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('report_issue'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF264653),
                                ),
                              ),
                              Text(
                                t('using_gps'),
                                style: TextStyle(
                                  color: const Color(
                                    0xFF264653,
                                  ).withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Color(0xFF264653),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Essential Services Grid
                StaggeredEntrance(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('essential_services'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                        children: [
                          _ServiceTile(
                            icon: Icons.local_hospital_rounded,
                            label: t('hospitals'),
                            color: const Color(0xFFE76F51),
                            onTap: () => _launchUrl(
                              'https://www.google.com/maps/search/hospital',
                            ),
                          ),
                          _ServiceTile(
                            icon: Icons.account_balance_rounded,
                            label: t('schemes'),
                            color: const Color(0xFF2A9D8F),
                            onTap: () => appState.setNav(3),
                          ),
                          _ServiceTile(
                            icon: Icons.description_rounded,
                            label: t('rti'),
                            color: const Color(0xFF457B9D),
                            onTap: () =>
                                _launchUrl('https://rtionline.tn.gov.in'),
                          ),
                          _ServiceTile(
                            icon: Icons.headset_mic_rounded,
                            label: t('cm_cell'),
                            color: const Color(0xFFE9C46A),
                            onTap: () => _launchUrl('https://cmhelpline.tnega.org/portal/en/home'),
                          ),
                          _ServiceTile(
                            icon: Icons.bolt_rounded,
                            label: t('eb_website'),
                            color: const Color(0xFF52B788),
                            onTap: () => _launchUrl('https://www.tnpdcl.org'),
                          ),
                          _ServiceTile(
                            icon: Icons.rice_bowl_rounded,
                            label: t('ration_card'),
                            color: const Color(0xFFF4A261),
                            onTap: () => _launchUrl('https://www.tnpds.gov.in'),
                          ),
                          _ServiceTile(
                            icon: Icons.newspaper_rounded,
                            label: t('news'),
                            color: const Color(0xFF2A9D8F),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewsFeedScreen(),
                              ),
                            ),
                          ),
                          _ServiceTile(
                            icon: Icons.map_rounded,
                            label: t('map'),
                            color: const Color(0xFF457B9D),
                            onTap: () => appState.setNav(1),
                          ),
                          _ServiceTile(
                            icon: Icons.checklist_rounded,
                            label: t('eligibility'),
                            color: const Color(0xFF52B788),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EligibilityScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // SOS Section
                StaggeredEntrance(
                  index: 4,
                  child: DeepGlassCard(
                    padding: 16,
                    child: Column(
                      children: [
                        Text(
                          t('safety'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('sos_hint'),
                          style: TextStyle(
                            color: const Color(
                              0xFF264653,
                            ).withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SOSButton(),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _helplines
                              .map(
                                (h) => GestureDetector(
                                  onTap: () => _launchUrl('tel:${h['number']}'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2A9D8F,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.call_rounded,
                                          color: Color(0xFF2A9D8F),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${h['name']} ${h['number']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF264653),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // My Reports summary
                if (userReports.isNotEmpty)
                  StaggeredEntrance(
                    index: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t('my_reports'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF264653),
                              ),
                            ),
                            TextButton(
                              onPressed: () => appState.setNav(1),
                              child: const Text('View Map'),
                            ),
                          ],
                        ),
                        ...userReports
                            .take(3)
                            .map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: r.status == 'Resolved'
                                    ? ResolvedPulse(
                                        child: _ReportSummaryRow(r: r),
                                      )
                                    : _ReportSummaryRow(r: r),
                              ),
                            ),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportSummaryRow extends StatelessWidget {
  final CivicReport r;
  const _ReportSummaryRow({required this.r});

  Future<void> _deleteReport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text('This will permanently remove this report.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(r.id)
              .delete();
        }
        await repo.deleteReport(r.id);
        if (context.mounted) showMessage(context, 'Report deleted.');
      } catch (e) {
        if (context.mounted) {
  showMessage(context, 'Delete failed.', isError: true);
        }
      }
  }
  }

  @override
  Widget build(BuildContext context) {
    return DeepGlassCard(
      padding: 12,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(r.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              r.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Text(
            r.status,
            style: TextStyle(fontSize: 11, color: _statusColor(r.status)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deleteReport(context),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Color(0xFFE76F51),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String s) {
  switch (s) {
    case 'Resolved':
      return const Color(0xFF52B788);
    case 'Assigned':
      return const Color(0xFF457B9D);
    case 'In Progress':
      return const Color(0xFFE9C46A);
    case 'Rejected':
      return const Color(0xFFE76F51);
    default:
      return Colors.grey;
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TappableGlassCard(
      padding: 10,
      borderRadius: 16,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF264653),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifBell extends StatelessWidget {
  const _NotifBell();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (_, __) => Stack(
        children: [
          IconButton(
            icon: const Icon(
              Icons.notifications_rounded,
              color: Color(0xFF264653),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          if (appState.unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFE76F51),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${appState.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ==========================================
// NEWS FEED SCREEN
// ==========================================
class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                      ),
                      Text(
                        t('news_feed'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _newsFeed.length,
                    itemBuilder: (_, i) {
                      final news = _newsFeed[i];
                      final catColors = {
                        'Civic': const Color(0xFF457B9D),
                        'Agriculture': const Color(0xFF52B788),
                        'Ward': const Color(0xFF2A9D8F),
                        'Exam': const Color(0xFFE9C46A),
                        'Safety': const Color(0xFFE76F51),
                      };
                      final catColor =
                          catColors[news['category']] ??
                          const Color(0xFF2A9D8F);
                      return StaggeredEntrance(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DeepGlassCard(
                            padding: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        news['category'] as String,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: catColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      news['time'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF264653),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  news['body'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(
                                      0xFF264653,
                                    ).withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ELIGIBILITY SCREEN
// ==========================================
class EligibilityScreen extends StatefulWidget {
  const EligibilityScreen({super.key});

  @override
  State<EligibilityScreen> createState() => _EligibilityScreenState();
}

class _EligibilityScreenState extends State<EligibilityScreen> {
  final Map<String, bool> _checks = {
    'Aadhaar card available': false,
    'Bank account linked to Aadhaar': false,
    'Land ownership records': false,
    'BPL / Income certificate': false,
    'Residence proof (TN)': false,
    'Enrolled in Govt School (for education schemes)': false,
    'Job card registered (for MGNREGS)': false,
    'Small/Marginal farmer (below 5 acres)': false,
  };

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final checkedCount = _checks.values.where((v) => v).length;
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                      ),
                      Expanded(
                        child: Text(
                          t('eligibility'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DeepGlassCard(
                    padding: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scheme Eligibility Checker',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check which documents/conditions you meet to see eligible schemes.',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF264653,
                            ).withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: checkedCount / _checks.length,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF2A9D8F),
                          ),
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$checkedCount / ${_checks.length} conditions met',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2A9D8F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ..._checks.keys.toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final key = entry.value;
                        return StaggeredEntrance(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _checks[key] = !(_checks[key] ?? false),
                              ),
                              child: DeepGlassCard(
                                padding: 14,
                                color: (_checks[key] ?? false)
                                    ? const Color(
                                        0xFF52B788,
                                      ).withValues(alpha: 0.15)
                                    : null,
                                border: (_checks[key] ?? false)
                                    ? Border.all(
                                        color: const Color(0xFF52B788),
                                        width: 1.5,
                                      )
                                    : null,
                                child: Row(
                                  children: [
                                    Icon(
                                      (_checks[key] ?? false)
                                          ? Icons.check_circle_rounded
                                          : Icons
                                                .radio_button_unchecked_rounded,
                                      color: (_checks[key] ?? false)
                                          ? const Color(0xFF52B788)
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        key,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: (_checks[key] ?? false)
                                              ? const Color(0xFF264653)
                                              : const Color(
                                                  0xFF264653,
                                                ).withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      if (checkedCount > 0) ...[
                        const Text(
                          'Schemes You May Be Eligible For:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._govSchemes
                            .where((scheme) {
                              final eligibilityList =
                                  scheme['eligibility'] as List;
                              int matchCount = 0;
                              for (final req in eligibilityList) {
                                if (_checks.keys.any(
                                  (k) =>
                                      k.toLowerCase().contains(
                                        (req as String)
                                            .toLowerCase()
                                            .split(' ')
                                            .first
                                            .toLowerCase(),
                                      ) &&
                                      (_checks[k] ?? false),
                                )) {
                                  matchCount++;
                                }
                              }
                              return matchCount > 0 || checkedCount >= 3;
                            })
                            .take(6)
                            .map(
                              (scheme) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TappableGlassCard(
                                  padding: 14,
                                  onTap: () =>
                                      _launchUrl(scheme['url'] as String),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF2A9D8F,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_rounded,
                                          color: Color(0xFF2A9D8F),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              scheme['name'] as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF264653),
                                              ),
                                            ),
                                            Text(
                                              scheme['summary'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: const Color(
                                                  0xFF264653,
                                                ).withValues(alpha: 0.6),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 16,
                                        color: Color(0xFF2A9D8F),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CIVIC MAP SCREEN
// ==========================================
class CivicMapScreen extends StatefulWidget {
  const CivicMapScreen({super.key});

  @override
  State<CivicMapScreen> createState() => _CivicMapScreenState();
}

class _CivicMapScreenState extends State<CivicMapScreen> {
  final MapController _mapCtrl = MapController();
  String _filter = 'All';
  bool _showWards = true;
  bool _showSafeRoute = false;
  bool _showHeatmap = false;
  final List<String> _filters = ['All', 'Pending', 'Assigned', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final filtered = _filter == 'All'
            ? repo.reports
            : repo.reports.where((r) => r.status == _filter).toList();
        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: appState.userLocation,
                  initialZoom: 13.5,
                  onTap: (_, latLng) {
                    if (appState.currentUser?.role == 'Public') {
                      appState.prepareReportAt(latLng);
                      appState.setNav(2);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartera.app',
                  ),
                  if (_showWards)
                    CircleLayer(
                      circles: _wardData.map((w) {
                        final openIssues = w['open_issues'] as int;
                        return CircleMarker(
                          point: LatLng(
                            w['center_lat'] as double,
                            w['center_lng'] as double,
                          ),
                          radius: (w['radius'] as double) * 80000,
                          color:
                              (openIssues > 3
                                      ? const Color(0xFFE76F51)
                                      : const Color(0xFF2A9D8F))
                                  .withValues(alpha: 0.12),
                          borderColor: openIssues > 3
                              ? const Color(0xFFE76F51)
                              : const Color(0xFF2A9D8F),
                          borderStrokeWidth: 1.5,
                        );
                      }).toList(),
                    ),
                  if (_showSafeRoute)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _safeRoutePoints,
                          color: const Color(0xFF52B788),
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  if (_showHeatmap)
                    CircleLayer(
                      circles: filtered
                          .map(
                            (r) => CircleMarker(
                              point: r.loc,
                              radius: 40,
                              color: _statusColor(
                                r.status,
                              ).withValues(alpha: 0.25),
                              borderStrokeWidth: 0,
                            ),
                          )
                          .toList(),
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: appState.userLocation,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2A9D8F),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2A9D8F,
                                ).withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      if (_showWards)
                        ..._wardData.map(
                          (w) => Marker(
                            point: LatLng(
                              w['center_lat'] as double,
                              w['center_lng'] as double,
                            ),
                            width: 80,
                            height: 24,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                w['ward'] as String,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF264653),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ...filtered.map(
                        (r) => Marker(
                          point: r.loc,
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () => _showReportDetail(context, r),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _statusColor(r.status),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _statusColor(
                                          r.status,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _categoryIcon(r.category),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                if (r.isSlaBreached)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._filters.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _filter = f),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _filter == f
                                          ? const Color(0xFF2A9D8F)
                                          : Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                        color: _filter == f
                                            ? Colors.white
                                            : const Color(0xFF264653),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _MapChip(
                              label: t('ward'),
                              active: _showWards,
                              activeColor: const Color(0xFF457B9D),
                              onTap: () =>
                                  setState(() => _showWards = !_showWards),
                            ),
                            const SizedBox(width: 8),
                            _MapChip(
                              label: t('safe_route'),
                              active: _showSafeRoute,
                              activeColor: const Color(0xFF52B788),
                              onTap: () => setState(
                                () => _showSafeRoute = !_showSafeRoute,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MapChip(
                              label: 'Heat',
                              active: _showHeatmap,
                              activeColor: const Color(0xFFE76F51),
                              onTap: () =>
                                  setState(() => _showHeatmap = !_showHeatmap),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'locate',
                      backgroundColor: Colors.white,
                      onPressed: () => _mapCtrl.move(appState.userLocation, 14),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFF2A9D8F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'report_fab',
                      backgroundColor: const Color(0xFFE76F51),
                      onPressed: () => appState.setNav(2),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    '${filtered.length} issues',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF264653),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDetail(BuildContext context, CivicReport r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: DeepGlassCard(
          padding: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _statusColor(r.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryIcon(r.category),
                      color: _statusColor(r.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF264653),
                          ),
                        ),
                        Text(
                          r.status,
                          style: TextStyle(
                            color: _statusColor(r.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                r.desc,
                style: TextStyle(
                  color: const Color(0xFF264653).withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              if (r.address != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '📍 ${r.address}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2A9D8F),
                    ),
                  ),
                ),
              if (r.isSlaBreached)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          appState.t('sla_flag'),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.thumb_up_alt_rounded,
                    size: 14,
                    color: Color(0xFF2A9D8F),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${r.upvotes} upvotes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF264653),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      repo.upvoteReport(r.id);
                      appState.addPoints(5);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    label: const Text('Upvote'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Roads':
        return Icons.directions_car_rounded;
      case 'Electricity':
        return Icons.bolt_rounded;
      case 'Water':
        return Icons.water_drop_rounded;
      case 'Garbage':
        return Icons.delete_outline_rounded;
      case 'Sanitation':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }
}

class _MapChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _MapChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF264653),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// REPORT SCREEN
// ==========================================
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Roads';
  XFile? _image;
  bool _submitting = false;

  final List<String> _categories = [
    'Roads',
    'Water',
    'Electricity',
    'Garbage',
    'Sanitation',
    'Other',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (img != null) {
      setState(() => _image = img);
    }
  }

  Future<void> _submit() async {
    final t = appState.t;
    FocusScope.of(context).unfocus();
    if (_titleCtrl.text.trim().isEmpty) {
      showMessage(context, t('add_title'), isError: true);
      return;
    }
    if (appState.reportDraftLocation == null) {
      showMessage(context, t('location_unavailable'), isError: true);
      return;
    }
    setState(() => _submitting = true);
    final report = CivicReport(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      userId: appState.currentUser!.uid,
      title: _titleCtrl.text.trim(),
      desc: _descCtrl.text.trim(),
      category: _category,
      loc: appState.reportDraftLocation!,
      address: appState.reportDraftAddress,
    );
    final success = await repo.saveReport(report, _image);
    if (!mounted) return;
    if (success) {
      appState.addPoints(50);
      showMessage(context, t('report_submitted'));
      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _image = null;
        _submitting = false;
      });
    } else {
      setState(() => _submitting = false);
      showMessage(context, t('error_generic'), isError: true);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showMessage(
            context,
            appState.t('location_unavailable'),
            isError: true,
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showMessage(
            context,
            appState.t('location_unavailable'),
            isError: true,
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));
      final loc = LatLng(pos.latitude, pos.longitude);
      appState.updateLocation(loc);
      await appState.prepareReportAt(loc);
    } catch (e) {
      if (mounted) {
        showMessage(context, appState.t('location_unavailable'), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StaggeredEntrance(
              index: 0,
              child: Text(
                t('new_report'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF264653),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 1,
              child: TappableGlassCard(
                padding: 16,
                onTap: _getCurrentLocation,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A9D8F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF2A9D8F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('location'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF264653),
                            ),
                          ),
                          Text(
                            appState.reportDraftAddress.isEmpty
                                ? t('using_gps')
                                : appState.reportDraftAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF264653,
                              ).withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF2A9D8F),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            StaggeredEntrance(
              index: 2,
              child: DeepGlassCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('issue_category'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF264653),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories
                          .map(
                            (cat) => GestureDetector(
                              onTap: () => setState(() => _category = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _category == cat
                                      ? const Color(0xFF2A9D8F)
                                      : const Color(
                                          0xFF2A9D8F,
                                        ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: _category == cat
                                        ? Colors.white
                                        : const Color(0xFF2A9D8F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            StaggeredEntrance(
              index: 3,
              child: DeepGlassCard(
                padding: 16,
                child: Column(
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: t('short_title'),
                        prefixIcon: const Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: t('provide_context'),
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            StaggeredEntrance(
              index: 4,
              child: TappableGlassCard(
                padding: 16,
                onTap: _pickImage,
                child: Column(
                  children: [
                    if (_image != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(
                                _image!.path,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                io.File(_image!.path),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Change Photo'),
                      ),
                    ] else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_rounded,
                            color: Color(0xFF2A9D8F),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t('photo_optional'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF264653),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            StaggeredEntrance(
              index: 5,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE76F51),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(t('submitting')),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded),
                          const SizedBox(width: 8),
                          Text(
                            t('submit'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCHEMES SCREEN
// ==========================================
class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Agriculture',
    'Housing',
    'Education',
    'Health',
    'Women',
    'Employment',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final filtered = _govSchemes.where((s) {
      final matchSearch =
          _searchQuery.isEmpty ||
          (s['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (s['summary'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchCat =
          _selectedCategory == null ||
          _selectedCategory == 'All' ||
          (s['category'] as String) == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('schemes'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EligibilityScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.checklist_rounded, size: 16),
                      label: Text(t('eligibility')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: t('search_schemes'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.map((cat) {
                      final selected = (_selectedCategory ?? 'All') == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _selectedCategory = cat == 'All' ? null : cat,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF2A9D8F)
                                  : Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF264653),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: const Color(0xFF2A9D8F),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2A9D8F),
                  tabs: [
                    Tab(text: t('schemes')),
                    Tab(text: t('exam_alerts')),
                    Tab(text: t('bank_loans')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Schemes Tab
                filtered.isEmpty
                    ? Center(
                        child: Text(
                          t('no_schemes_found'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final scheme = filtered[i];
                          final catColorMap = {
                            'Agriculture': const Color(0xFF52B788),
                            'Housing': const Color(0xFF457B9D),
                            'Education': const Color(0xFFE9C46A),
                            'Health': const Color(0xFFE76F51),
                            'Women': const Color(0xFFF4A261),
                            'Employment': const Color(0xFF2A9D8F),
                          };
                          final catColor =
                              catColorMap[scheme['category']] ??
                              const Color(0xFF2A9D8F);
                          return StaggeredEntrance(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TappableGlassCard(
                                padding: 16,
                                onTap: () =>
                                    _launchUrl(scheme['url'] as String),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.account_balance_rounded,
                                            color: catColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                scheme['name'] as String,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF264653),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: catColor.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  scheme['category'] as String,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: catColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 16,
                                          color: Color(0xFF2A9D8F),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      scheme['summary'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(
                                          0xFF264653,
                                        ).withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: (scheme['eligibility'] as List)
                                          .map(
                                            (e) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                e as String,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF264653),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                // Exam Alerts Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _examNotifications.length,
                  itemBuilder: (_, i) {
                    final exam = _examNotifications[i];
                    return StaggeredEntrance(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TappableGlassCard(
                          padding: 14,
                          onTap: () => _launchUrl(exam['url'] as String),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE9C46A,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Color(0xFFE9C46A),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exam['exam'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF264653),
                                      ),
                                    ),
                                    Text(
                                      'Apply by: ${exam['apply_by']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFE76F51),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Exam Date: ${exam['date']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: const Color(
                                          0xFF264653,
                                        ).withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: Color(0xFF2A9D8F),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Bank Loans Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bankLoanInfo.length,
                  itemBuilder: (_, i) {
                    final loan = _bankLoanInfo[i];
                    return StaggeredEntrance(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TappableGlassCard(
                          padding: 14,
                          onTap: () => _launchUrl(loan['url'] as String),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF457B9D,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF457B9D),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF264653),
                                      ),
                                    ),
                                    Text(
                                      loan['desc'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2A9D8F),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: (loan['eligibility'] as List)
                                          .map(
                                            (e) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                e as String,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF264653),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: Color(0xFF2A9D8F),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PROFILE SCREEN
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final user = appState.currentUser!;
    final badge = appState.reputationBadge;

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StaggeredEntrance(
              index: 0,
              child: DeepGlassCard(
                padding: 24,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2A9D8F),
                            const Color(0xFF52B788),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2A9D8F,
                            ).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF264653),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A9D8F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role,
                        style: const TextStyle(
                          color: Color(0xFF2A9D8F),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          badge['icon'] as IconData,
                          color: badge['color'] as Color,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        AnimatedCounterText(
                          value: user.civicPoints,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: badge['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t('points'),
                          style: TextStyle(
                            color: badge['color'] as Color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${badge['label']} ${t('citizen')}',
                      style: TextStyle(
                        color: (badge['color'] as Color).withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 1,
              child: DeepGlassCard(
                padding: 16,
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.phone_rounded,
                      label: t('phone'),
                      value: user.phone,
                    ),
                    const Divider(height: 20),
                    _ProfileRow(
                      icon: Icons.location_on_rounded,
                      label: t('address'),
                      value: user.address,
                    ),
                    if (user.email.isNotEmpty) ...[
                      const Divider(height: 20),
                      _ProfileRow(
                        icon: Icons.email_rounded,
                        label: t('email_optional'),
                        value: user.email,
                      ),
                    ],
                    if (user.wardId != null) ...[
                      const Divider(height: 20),
                      _ProfileRow(
                        icon: Icons.map_rounded,
                        label: t('ward_card'),
                        value: _wardNameFromId(user.wardId) ?? user.wardId!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reports summary
            AnimatedBuilder(
              animation: repo,
              builder: (_, __) {
                final myReports = repo.reports
                    .where((r) => r.userId == user.uid)
                    .toList();
                if (myReports.isEmpty) return const SizedBox();
                final resolved = myReports
                    .where((r) => r.status == 'Resolved')
                    .length;
                final pending = myReports
                    .where((r) => r.status == 'Pending')
                    .length;
                return StaggeredEntrance(
                  index: 2,
                  child: DeepGlassCard(
                    padding: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('my_reports'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                label: t('total'),
                                value: myReports.length,
                                color: const Color(0xFF2A9D8F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatBox(
                                label: t('resolved'),
                                value: resolved,
                                color: const Color(0xFF52B788),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatBox(
                                label: t('pending'),
                                value: pending,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Ward Leaderboard
            StaggeredEntrance(
              index: 3,
              child: DeepGlassCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('ward_leaderboard'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF264653),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...appState.wardLeaderboard
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                          final i = entry.key;
                          final ward = entry.value;
                          final medals = ['🥇', '🥈', '🥉'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  i < 3 ? medals[i] : '${i + 1}.',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ward['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF264653),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${ward['resolved_month']} resolved',
                                  style: const TextStyle(
                                    color: Color(0xFF52B788),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Edit Profile
            StaggeredEntrance(
              index: 4,
              child: TappableGlassCard(
                padding: 16,
                onTap: () => _showEditProfileDialog(context, user),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: Color(0xFF2A9D8F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appState.t('edit_profile'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            // Language toggle
            StaggeredEntrance(
              index: 5,
              child: TappableGlassCard(
                padding: 16,
                onTap: () => appState.toggleLang(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: Color(0xFF2A9D8F),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t('language'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ),
                    Text(
                      appState.lang == 'en' ? 'English' : 'தமிழ்',
                      style: const TextStyle(
                        color: Color(0xFF2A9D8F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF2A9D8F),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Logout
            StaggeredEntrance(
              index: 6,
              child: TappableGlassCard(
                padding: 16,
                color: const Color(0xFFE76F51).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFFE76F51).withValues(alpha: 0.3),
                ),
                onTap: () {
                  appState.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Stack(
                          children: [
                            AnimatedMeshBackground(),
                            RoleSelectionScreen(),
                          ],
                        ),
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFE76F51)),
                    const SizedBox(width: 12),
                    Text(
                      t('logout'),
                      style: const TextStyle(
                        color: Color(0xFFE76F51),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2A9D8F), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF264653).withValues(alpha: 0.5),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF264653),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AnimatedCounterText(
            value: value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// NOTIFICATIONS SCREEN
// ==========================================
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: appState,
              builder: (context, _) {
                final notifs = appState.notifications;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_rounded),
                          ),
                          Expanded(
                            child: Text(
                              t('notifications'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF264653),
                              ),
                            ),
                          ),
                          if (appState.unreadCount > 0)
                            TextButton(
                              onPressed: appState.markAllNotificationsRead,
                              child: Text(
                                t('mark_all_read'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2A9D8F),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: notifs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    t('no_notifications'),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: notifs.length,
                              itemBuilder: (_, i) {
                                final n = notifs[i];
                                final typeIconMap = {
                                  'sos': Icons.warning_rounded,
                                  'new_report': Icons.report_problem_rounded,
                                  'report_accepted': Icons.check_circle_rounded,
                                  'report_resolved': Icons.done_all_rounded,
                                  'new_logistics': Icons.local_shipping_rounded,
                                  'logistics_update': Icons.update_rounded,
                                };
                                final typeColorMap = {
                                  'sos': const Color(0xFFE76F51),
                                  'new_report': Colors.orange,
                                  'report_accepted': const Color(0xFF52B788),
                                  'report_resolved': const Color(0xFF2A9D8F),
                                  'new_logistics': const Color(0xFF457B9D),
                                  'logistics_update': const Color(0xFF52B788),
                                };
                                final icon =
                                    typeIconMap[n.type] ??
                                    Icons.notifications_rounded;
                                final color =
                                    typeColorMap[n.type] ??
                                    const Color(0xFF2A9D8F);
                                return StaggeredEntrance(
                                  index: i,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: DeepGlassCard(
                                      padding: 14,
                                      color: n.isRead
                                          ? null
                                          : color.withValues(alpha: 0.05),
                                      border: n.isRead
                                          ? null
                                          : Border.all(
                                              color: color.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              icon,
                                              color: color,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  n.title,
                                                  style: TextStyle(
                                                    fontWeight: n.isRead
                                                        ? FontWeight.w500
                                                        : FontWeight.bold,
                                                    fontSize: 13,
                                                    color: const Color(
                                                      0xFF264653,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  n.body,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: const Color(
                                                      0xFF264653,
                                                    ).withValues(alpha: 0.7),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _timeAgo(n.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: color,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: color,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

// ==========================================
// FARMER HOME SCREEN
// ==========================================
class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  @override
  void initState() {
    super.initState();
    repo.loadLocalCropData(appState.detectedDistrict);
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final user = appState.currentUser!;

    return AnimatedBuilder(
      animation: Listenable.merge([appState, repo]),
      builder: (context, _) {
        final best = repo.bestOpportunity;
        final myCoops = appState.cooperatives
            .where(
              (c) => c.farmerIds.contains(user.uid) || c.wardId == user.wardId,
            )
            .toList();

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              repo.loadLocalCropData(appState.detectedDistrict);
              await appState.fetchWeather();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                StaggeredEntrance(
                  index: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t('welcome')} ${user.name.split(' ').first}!',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF264653),
                              ),
                            ),
                            Text(
                              '📍 ${appState.detectedDistrict} • ${t('farmer')}',
                              style: TextStyle(
                                color: const Color(
                                  0xFF264653,
                                ).withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _NotifBell(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Advisory
                StaggeredEntrance(
                  index: 0,
                  child: AnimatedBuilder(
                    animation: appState,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF52B788).withValues(alpha: 0.2),
                            const Color(0xFF2A9D8F).withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF52B788).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.agriculture_rounded,
                            color: Color(0xFF52B788),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appState.currentAdvisory,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF264653),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Weather + Best Crop
                StaggeredEntrance(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: DeepGlassCard(
                          padding: 14,
                          child: Row(
                            children: [
                              Icon(
                                appState.weatherIcon,
                                color: const Color(0xFFE9C46A),
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appState.weatherTemp,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF264653),
                                    ),
                                  ),
                                  Text(
                                    appState.weatherDesc,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (best != null)
                        Expanded(
                          child: TappableGlassCard(
                            padding: 14,
                            onTap: () => appState.setNav(1),
                            color: const Color(
                              0xFF52B788,
                            ).withValues(alpha: 0.1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('best_crop'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF52B788),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  best.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF264653),
                                  ),
                                ),
                                Text(
                                  '↑ ₹${best.predictedPrice.toStringAsFixed(0)}/kg',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF52B788),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Quick Actions
                StaggeredEntrance(
                  index: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: TappableGlassCard(
                          padding: 16,
                          onTap: () => appState.setNav(1),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFF2A9D8F),
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t('market'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF264653),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TappableGlassCard(
                          padding: 16,
                          onTap: () => appState.setNav(2),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.local_hospital_rounded,
                                color: Color(0xFF52B788),
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t('doctor'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF264653),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TappableGlassCard(
                          padding: 16,
                          onTap: () => appState.setNav(3),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.local_shipping_rounded,
                                color: Color(0xFF457B9D),
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t('logistics'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF264653),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Crop Price Overview
                StaggeredEntrance(
                  index: 3,
                  child: DeepGlassCard(
                    padding: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t('market_prices'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF264653),
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () => appState.setNav(1),
                              child: Text(
                                t('view_all'),
                                style: const TextStyle(
                                  color: Color(0xFF2A9D8F),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...repo.crops.take(3).map((crop) {
                          final rising =
                              crop.predictedPrice >= crop.currentPrice;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    crop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF264653),
                                    ),
                                  ),
                                ),
                                MiniSparkline(
                                  data: crop.history,
                                  color: rising
                                      ? const Color(0xFF52B788)
                                      : const Color(0xFFE76F51),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${crop.currentPrice.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF264653),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          rising
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_downward_rounded,
                                          color: rising
                                              ? const Color(0xFF52B788)
                                              : const Color(0xFFE76F51),
                                          size: 12,
                                        ),
                                        Text(
                                          '₹${crop.predictedPrice.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: rising
                                                ? const Color(0xFF52B788)
                                                : const Color(0xFFE76F51),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Cooperatives
                if (myCoops.isNotEmpty)
                  StaggeredEntrance(
                    index: 4,
                    child: DeepGlassCard(
                      padding: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t('cooperative'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF264653),
                                  fontSize: 16,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showCreateCoopDialog(context),
                                icon: const Icon(Icons.add, size: 14),
                                label: Text(
                                  t('create'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...myCoops
                              .take(3)
                              .map(
                                (coop) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: TappableGlassCard(
                                    padding: 12,
                                    onTap: () {
                                      appState.joinCooperative(coop.id);
                                      showMessage(
                                        context,
                                        'Joined ${coop.crop} cooperative!',
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF52B788,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.group_rounded,
                                            color: Color(0xFF52B788),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${coop.crop} Group',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF264653),
                                                ),
                                              ),
                                              Text(
                                                '${coop.farmerIds.length} farmers • ${coop.totalWeightKg}kg',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF52B788,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            coop.status,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF52B788),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateCoopDialog(BuildContext context) {
    String selectedCrop = _cropOptions.first;
    double weight = 100;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${appState.t('create')} Cooperative'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCrop,
                items: _cropOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCrop = v!),
                decoration: const InputDecoration(labelText: 'Crop'),
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                onChanged: (v) => weight = double.tryParse(v) ?? 100,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                appState.createCooperative(selectedCrop, weight);
                Navigator.pop(ctx);
                showMessage(context, 'Cooperative created!');
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MARKET SCREEN
// ==========================================
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedDistrict = 'Default';
  final _sellCropCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _sellQtyCtrl = TextEditingController();
  final _sellLocCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _selectedDistrict = appState.detectedDistrict;
    repo.loadLocalCropData(_selectedDistrict);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _sellCropCtrl.dispose();
    _sellPriceCtrl.dispose();
    _sellQtyCtrl.dispose();
    _sellLocCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final districts = _agmarknetData.keys.toList();

    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('market_prices'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF264653),
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedDistrict,
                        underline: const SizedBox(),
                        style: const TextStyle(
                          color: Color(0xFF2A9D8F),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        items: districts
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (d) {
                          if (d != null) {
                            setState(() => _selectedDistrict = d);
                            repo.loadLocalCropData(d);
                          }
                        },
                      ),
                    ],
                  ),
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: const Color(0xFF2A9D8F),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF2A9D8F),
                    tabs: [
                      Tab(text: t('prices')),
                      Tab(text: t('sell_board')),
                      Tab(text: t('cooperative')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Prices Tab
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: repo.crops.length,
                    itemBuilder: (_, i) {
                      final crop = repo.crops[i];
                      final rising = crop.predictedPrice >= crop.currentPrice;
                      final alertOn = appState.priceAlerts[crop.name] ?? false;
                      return StaggeredEntrance(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DeepGlassCard(
                            padding: 14,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            crop.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF264653),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (rising
                                                              ? const Color(
                                                                  0xFF52B788,
                                                                )
                                                              : const Color(
                                                                  0xFFE76F51,
                                                                ))
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  crop.demand,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: rising
                                                        ? const Color(
                                                            0xFF52B788,
                                                          )
                                                        : const Color(
                                                            0xFFE76F51,
                                                          ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    MiniSparkline(
                                      data: crop.history,
                                      color: rising
                                          ? const Color(0xFF52B788)
                                          : const Color(0xFFE76F51),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${crop.currentPrice.toStringAsFixed(1)}/kg',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            color: Color(0xFF264653),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              rising
                                                  ? Icons.trending_up_rounded
                                                  : Icons.trending_down_rounded,
                                              color: rising
                                                  ? const Color(0xFF52B788)
                                                  : const Color(0xFFE76F51),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '₹${crop.predictedPrice.toStringAsFixed(1)} predicted',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: rising
                                                    ? const Color(0xFF52B788)
                                                    : const Color(0xFFE76F51),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: (crop.currentPrice / 100).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        valueColor: AlwaysStoppedAnimation(
                                          rising
                                              ? const Color(0xFF52B788)
                                              : const Color(0xFFE76F51),
                                        ),
                                        backgroundColor: Colors.grey.shade200,
                                        minHeight: 4,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () =>
                                          appState.togglePriceAlert(crop.name),
                                      child: Icon(
                                        alertOn
                                            ? Icons.notifications_active_rounded
                                            : Icons.notifications_none_rounded,
                                        color: alertOn
                                            ? const Color(0xFFE9C46A)
                                            : Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Sell Board Tab
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TappableGlassCard(
                        padding: 14,
                        onTap: () => _showSellDialog(context),
                        color: const Color(0xFF52B788).withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFF52B788),
                          width: 1.5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_rounded,
                              color: Color(0xFF52B788),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t('post_listing'),
                              style: const TextStyle(
                                color: Color(0xFF52B788),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...appState.cropListings.asMap().entries.map((entry) {
                        final i = entry.key;
                        final listing = entry.value;
                        return StaggeredEntrance(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DeepGlassCard(
                              padding: 14,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF52B788,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.agriculture_rounded,
                                      color: Color(0xFF52B788),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          listing.crop,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF264653),
                                          ),
                                        ),
                                        Text(
                                          '${listing.farmerName} • ${listing.location}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '${listing.quantityKg}kg available',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(
                                              0xFF264653,
                                            ).withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${listing.pricePerKg}/kg',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: Color(0xFF52B788),
                                        ),
                                      ),
                                      Text(
                                        _timeAgo(listing.createdAt),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  // Cooperatives Tab
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TappableGlassCard(
                        padding: 14,
                        color: const Color(0xFF457B9D).withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFF457B9D),
                          width: 1.5,
                        ),
                        onTap: () => _showCreateCoopDialog(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.group_add_rounded,
                              color: Color(0xFF457B9D),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${t('create')} Group',
                              style: const TextStyle(
                                color: Color(0xFF457B9D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...appState.cooperatives.asMap().entries.map((entry) {
                        final i = entry.key;
                        final coop = entry.value;
                        final isMember = coop.farmerIds.contains(
                          appState.currentUser?.uid,
                        );
                        return StaggeredEntrance(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DeepGlassCard(
                              padding: 14,
                              color: isMember
                                  ? const Color(
                                      0xFF52B788,
                                    ).withValues(alpha: 0.08)
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF457B9D,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.group_rounded,
                                          color: Color(0xFF457B9D),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${coop.crop} Cooperative',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF264653),
                                              ),
                                            ),
                                            Text(
                                              _wardNameFromId(coop.wardId) ??
                                                  coop.wardId,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isMember)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF52B788,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Member',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF52B788),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people_rounded,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        coop.farmerNames.take(2).join(', ') +
                                            (coop.farmerNames.length > 2
                                                ? ' +${coop.farmerNames.length - 2}'
                                                : ''),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF264653),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${coop.totalWeightKg}kg total',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF457B9D),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isMember) ...[
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          appState.joinCooperative(coop.id);
                                          showMessage(
                                            context,
                                            'Joined ${coop.crop} cooperative!',
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF457B9D,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Join Group',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context) {
    String selectedCrop = _cropOptions.first;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Post Crop Listing'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCrop,
                  items: _cropOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedCrop = v);
                    _sellCropCtrl.text = v ?? '';
                  },
                  decoration: const InputDecoration(labelText: 'Crop'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sellPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price per kg (₹)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sellQtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity (kg)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sellLocCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location/Village',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final listing = CropListing(
                  id: 'cl_${DateTime.now().millisecondsSinceEpoch}',
                  farmerId: appState.currentUser?.uid ?? '',
                  farmerName: appState.currentUser?.name ?? '',
                  crop: selectedCrop,
                  pricePerKg: double.tryParse(_sellPriceCtrl.text) ?? 0,
                  quantityKg: double.tryParse(_sellQtyCtrl.text) ?? 0,
                  location: _sellLocCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                appState.cropListings.insert(0, listing);
                appState.refreshProfile();
                _sellPriceCtrl.clear();
                _sellQtyCtrl.clear();
                _sellLocCtrl.clear();
                Navigator.pop(ctx);
                showMessage(context, 'Listing posted!');
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCoopDialog(BuildContext context) {
    String selectedCrop = _cropOptions.first;
    final weightCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Cooperative Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCrop,
                items: _cropOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedCrop = v ?? selectedCrop),
                decoration: const InputDecoration(labelText: 'Crop'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your quantity (kg)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final weight = double.tryParse(weightCtrl.text) ?? 100;
                appState.createCooperative(selectedCrop, weight);
                weightCtrl.dispose();
                Navigator.pop(ctx);
                showMessage(context, 'Cooperative group created!');
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
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

class _CropDoctorScreenState extends State<CropDoctorScreen> {
  XFile? _image;
  String? _diagnosis;
  bool _analyzing = false;
  String _selectedCrop = 'Tomato';

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StaggeredEntrance(
              index: 0,
              child: Text(
                t('crop_doctor'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF264653),
                ),
              ),
            ),
            const SizedBox(height: 4),
            StaggeredEntrance(
              index: 0,
              child: Text(
                t('ai_powered'),
                style: TextStyle(
                  color: const Color(0xFF264653).withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Crop selector
            StaggeredEntrance(
              index: 1,
              child: DeepGlassCard(
                padding: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('select_crop'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF264653),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _cropOptions.map((crop) {
                        final selected = _selectedCrop == crop;
                        final displayName = appState.lang == 'ta'
                            ? (_cropOptionsTamil[crop] ?? crop)
                            : crop;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCrop = crop),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF52B788)
                                  : const Color(
                                      0xFF52B788,
                                    ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF52B788),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Image capture
            StaggeredEntrance(
              index: 2,
              child: TappableGlassCard(
                padding: 16,
                onTap: _captureImage,
                child: Column(
                  children: [
                    if (_image != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(
                                _image!.path,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                io.File(_image!.path),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Retake Photo'),
                      ),
                    ] else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF52B788,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Color(0xFF52B788),
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('take_photo'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF264653),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            t('photo_hint'),
                            style: TextStyle(
                              color: const Color(
                                0xFF264653,
                              ).withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_image != null)
              StaggeredEntrance(
                index: 3,
                child: ElevatedButton(
                  onPressed: _analyzing ? null : _analyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52B788),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _analyzing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(t('analyzing')),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.biotech_rounded),
                            const SizedBox(width: 8),
                            Text(
                              t('analyze'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            if (_diagnosis != null) ...[
              const SizedBox(height: 16),
              StaggeredEntrance(
                index: 4,
                child: RevealCard(
                  child: DeepGlassCard(
                    padding: 16,
                    color: const Color(0xFF52B788).withValues(alpha: 0.08),
                    border: Border.all(
                      color: const Color(0xFF52B788).withValues(alpha: 0.4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.biotech_rounded,
                              color: Color(0xFF52B788),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t('diagnosis'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF52B788),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          _diagnosis!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF264653),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (appState.diagnosisHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              StaggeredEntrance(
                index: 5,
                child: DeepGlassCard(
                  padding: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('history'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF264653),
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: appState.clearDiagnosisHistory,
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                color: Color(0xFFE76F51),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...appState.diagnosisHistory.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.network(
                                        entry.imagePath,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        io.File(entry.imagePath),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.diagnosis.length > 80
                                          ? '${entry.diagnosis.substring(0, 80)}...'
                                          : entry.diagnosis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF264653),
                                      ),
                                    ),
                                    Text(
                                      _timeAgo(entry.timestamp),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (img != null) {
      setState(() {
        _image = img;
        _diagnosis = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _analyzing = true);
    try {
      if (groqApiKey.isEmpty || groqApiKey.startsWith('GROQ')) {
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _diagnosis = _mockDiagnosis(_selectedCrop);
          _analyzing = false;
        });
        appState.addDiagnosis(
          DiagnosisEntry(
            imagePath: _image!.path,
            diagnosis: _diagnosis!,
            timestamp: DateTime.now(),
          ),
        );
        return;
      }
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $groqApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text':
                          'You are an expert agricultural pathologist. Analyze this image of a $_selectedCrop plant. Identify any diseases, pests, or deficiencies visible. Provide: 1) Diagnosis 2) Severity (Low/Medium/High) 3) Treatment recommendations in simple farmer-friendly language. Keep response under 150 words.',
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,$base64Image',
                      },
                    },
                  ],
                },
              ],
              'max_tokens': 300,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['choices'][0]['message']['content'] as String;
        setState(() => _diagnosis = result);
        appState.addDiagnosis(
          DiagnosisEntry(
            imagePath: _image!.path,
            diagnosis: result,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        setState(() => _diagnosis = _mockDiagnosis(_selectedCrop));
        appState.addDiagnosis(
          DiagnosisEntry(
            imagePath: _image!.path,
            diagnosis: _diagnosis!,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _diagnosis = _mockDiagnosis(_selectedCrop));
        appState.addDiagnosis(
          DiagnosisEntry(
            imagePath: _image!.path,
            diagnosis: _diagnosis!,
            timestamp: DateTime.now(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  String _mockDiagnosis(String crop) {
    final diagnoses = {
      'Tomato':
          '🔴 Diagnosis: Early Blight (Alternaria solani)\nSeverity: Medium\n\nSymptoms: Dark brown spots with concentric rings on lower leaves.\n\nTreatment:\n• Remove affected leaves immediately\n• Apply copper-based fungicide (Mancozeb)\n• Ensure proper spacing for air circulation\n• Water at base, avoid wetting leaves\n• Repeat spray every 7 days',
      'Onion':
          '🟡 Diagnosis: Purple Blotch (Alternaria porri)\nSeverity: Medium\n\nSymptoms: Purple-centered lesions with yellow borders.\n\nTreatment:\n• Apply Iprodione or Mancozeb fungicide\n• Reduce irrigation frequency\n• Ensure field drainage\n• Remove crop debris after harvest',
      'Potato':
          '🟠 Diagnosis: Late Blight (Phytophthora infestans)\nSeverity: High\n\nSymptoms: Water-soaked lesions turning brown/black.\n\nTreatment:\n• Apply Metalaxyl + Mancozeb immediately\n• Destroy infected plants\n• Avoid overhead irrigation\n• Monitor weather — spray preventively in humid conditions',
      'Banana':
          '🟢 Diagnosis: Sigatoka Leaf Spot\nSeverity: Low\n\nSymptoms: Yellow streaks developing into brown necrotic patches.\n\nTreatment:\n• Apply Propiconazole fungicide\n• Remove and destroy infected leaves\n• Improve drainage\n• Apply potassium fertilizer to improve resistance',
    };
    return diagnoses[crop] ??
        '✅ Diagnosis: Plant appears healthy!\nNo significant disease or pest damage detected.\n\nRecommendations:\n• Continue current care practices\n• Monitor weekly for early signs\n• Ensure balanced fertilization\n• Maintain proper irrigation schedule';
  }
}

// ==========================================
// FARMER LOGISTICS SCREEN
// ==========================================
class FarmerLogisticsScreen extends StatefulWidget {
  const FarmerLogisticsScreen({super.key});

  @override
  State<FarmerLogisticsScreen> createState() => _FarmerLogisticsScreenState();
}

class _FarmerLogisticsScreenState extends State<FarmerLogisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCrop = 'Tomato';
  final _weightCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _selectedWarehouse;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _weightCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final user = appState.currentUser!;
    final myRequests = repo.logistics
        .where((l) => l.farmerId == user.uid)
        .toList();

    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('logistics'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF264653),
                    ),
                  ),
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: const Color(0xFF2A9D8F),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF2A9D8F),
                    tabs: [
                      Tab(text: t('book_pickup')),
                      Tab(text: t('my_requests')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Book Pickup Tab
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      StaggeredEntrance(
                        index: 0,
                        child: DeepGlassCard(
                          padding: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('select_crop'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF264653),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _cropOptions.map((crop) {
                                  final sel = _selectedCrop == crop;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedCrop = crop),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(0xFF457B9D)
                                            : const Color(
                                                0xFF457B9D,
                                              ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        crop,
                                        style: TextStyle(
                                          color: sel
                                              ? Colors.white
                                              : const Color(0xFF457B9D),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StaggeredEntrance(
                        index: 1,
                        child: DeepGlassCard(
                          padding: 16,
                          child: Column(
                            children: [
                              TextField(
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: t('weight'),
                                  prefixIcon: const Icon(Icons.scale_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _addressCtrl,
                                decoration: InputDecoration(
                                  labelText: t('pickup_address'),
                                  prefixIcon: const Icon(
                                    Icons.location_on_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StaggeredEntrance(
                        index: 2,
                        child: DeepGlassCard(
                          padding: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('select_warehouse'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF264653),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._warehouseData.map((w) {
                                final sel = _selectedWarehouse == w['id'];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedWarehouse =
                                          w['id'] as String,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(
                                                0xFF457B9D,
                                              ).withValues(alpha: 0.15)
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: sel
                                            ? Border.all(
                                                color: const Color(0xFF457B9D),
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warehouse_rounded,
                                            color: Color(0xFF457B9D),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  w['name'] as String,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF264653),
                                                  ),
                                                ),
                                                Text(
                                                  '${w['distance']} • ${w['used']}/${w['capacity']} tons used',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            (w['crops'] as List).join(', '),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF457B9D),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      StaggeredEntrance(
                        index: 3,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF457B9D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.local_shipping_rounded),
                                    const SizedBox(width: 8),
                                    Text(
                                      t('book_pickup'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                  // My Requests Tab
                  myRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_shipping_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t('no_requests'),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: myRequests.length,
                          itemBuilder: (_, i) {
                            final req = myRequests[i];
                            return StaggeredEntrance(
                              index: i,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: DeepGlassCard(
                                  padding: 16,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF457B9D,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.local_shipping_rounded,
                                              color: Color(0xFF457B9D),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${req.crop} • ${req.weightKg}kg',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF264653),
                                                  ),
                                                ),
                                                Text(
                                                  req.pickupAddress,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _logisticsStatusColor(
                                                req.status,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              req.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _logisticsStatusColor(
                                                  req.status,
                                                ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (req.scheduledTime != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '⏰ Pickup: ${req.scheduledTime}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2A9D8F),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      TransportTimeline(
                                        currentStatus: req.status,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    final t = appState.t;
    if (_weightCtrl.text.isEmpty || _addressCtrl.text.isEmpty) {
      showMessage(context, t('fill_all_fields'), isError: true);
      return;
    }
    setState(() => _submitting = true);
    final user = appState.currentUser!;
    final req = LogisticsRequest(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      farmerId: user.uid,
      farmerName: user.name,
      crop: _selectedCrop,
      weightKg: double.tryParse(_weightCtrl.text) ?? 0,
      pickupAddress: _addressCtrl.text.trim(),
      pickupLoc: appState.userLocation,
      warehouseId: _selectedWarehouse,
    );
    final success = await repo.submitLogisticsRequest(req);
    if (!mounted) return;
    if (success) {
      showMessage(context, t('request_submitted'));
      _weightCtrl.clear();
      _addressCtrl.clear();
      setState(() {
        _selectedWarehouse = null;
        _submitting = false;
      });
      _tabCtrl.animateTo(1);
    } else {
      showMessage(context, t('error_generic'), isError: true);
      setState(() => _submitting = false);
    }
  }
}

Color _logisticsStatusColor(String status) {
  switch (status) {
    case 'Confirmed':
      return const Color(0xFF2A9D8F);
    case 'Scheduled':
      return const Color(0xFF457B9D);
    case 'Picked Up':
      return const Color(0xFF52B788);
    case 'Delivered':
      return const Color(0xFF52B788);
    default:
      return Colors.orange;
  }
}

// ==========================================
// ADMIN DASHBOARD SCREEN
// ==========================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _broadcastMsg = '';

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return AnimatedBuilder(
      animation: Listenable.merge([appState, repo]),
      builder: (context, _) {
        final reports = repo.reports;
        final pending = reports.where((r) => r.status == 'Pending').toList();
        final assigned = reports.where((r) => r.status == 'Assigned').toList();
        final resolved = reports.where((r) => r.status == 'Resolved').toList();
        final breached = reports.where((r) => r.isSlaBreached).toList();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StaggeredEntrance(
                index: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('admin_dashboard'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ),
                    const _NotifBell(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Stats Grid
              StaggeredEntrance(
                index: 1,
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _AdminStatCard(
                      label: t('total_reports'),
                      value: reports.length,
                      color: const Color(0xFF2A9D8F),
                      icon: Icons.report_problem_rounded,
                    ),
                    _AdminStatCard(
                      label: t('pending'),
                      value: pending.length,
                      color: Colors.orange,
                      icon: Icons.hourglass_empty_rounded,
                    ),
                    _AdminStatCard(
                      label: t('resolved'),
                      value: resolved.length,
                      color: const Color(0xFF52B788),
                      icon: Icons.check_circle_rounded,
                    ),
                    _AdminStatCard(
                      label: t('sla_breached'),
                      value: breached.length,
                      color: const Color(0xFFE76F51),
                      icon: Icons.warning_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Broadcast
              StaggeredEntrance(
                index: 2,
                child: DeepGlassCard(
                  padding: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('broadcast'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: t('broadcast_hint'),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (v) => _broadcastMsg = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_broadcastMsg.trim().isNotEmpty) {
                                appState.setBroadcast(_broadcastMsg.trim());
                                showMessage(context, t('broadcast_sent'));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE76F51),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.campaign_rounded, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // SLA Breached
              if (breached.isNotEmpty)
                StaggeredEntrance(
                  index: 3,
                  child: DeepGlassCard(
                    padding: 14,
                    color: const Color(0xFFE76F51).withValues(alpha: 0.05),
                    border: Border.all(
                      color: const Color(0xFFE76F51).withValues(alpha: 0.3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              color: Color(0xFFE76F51),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t('sla_flag'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE76F51),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...breached
                            .take(3)
                            .map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '• ${r.title} (${r.category}) — ${DateTime.now().difference(r.createdAt).inDays}d old',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF264653),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // Pending Reports
              if (pending.isNotEmpty)
                StaggeredEntrance(
                  index: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t('pending')} ${t('total_reports')} (${pending.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pending
                          .take(5)
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AdminReportCard(r: r),
                            ),
                          ),
                    ],
                  ),
                ),
              // Assigned Reports
              if (assigned.isNotEmpty) ...[
                const SizedBox(height: 12),
                StaggeredEntrance(
                  index: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t('assigned')} (${assigned.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...assigned
                          .take(3)
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AdminReportCard(r: r),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
              // Logistics requests
              StaggeredEntrance(
                index: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      '${t('logistics')} (${repo.logistics.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF264653),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...repo.logistics
                        .take(5)
                        .map(
                          (req) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DeepGlassCard(
                              padding: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _logisticsStatusColor(
                                            req.status,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.local_shipping_rounded,
                                          color: _logisticsStatusColor(
                                            req.status,
                                          ),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${req.farmerName} — ${req.crop} ${req.weightKg}kg',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF264653),
                                              ),
                                            ),
                                            Text(
                                              req.pickupAddress,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _logisticsStatusColor(
                                            req.status,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          req.status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _logisticsStatusColor(
                                              req.status,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (req.status == 'Requested') ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _schedulePickup(
                                              context,
                                              req.id,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF457B9D,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'Schedule',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _schedulePickup(BuildContext context, String id) {
    final timeCtrl = TextEditingController(text: 'Tomorrow 8:00 AM');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Schedule Pickup'),
        content: TextField(
          controller: timeCtrl,
          decoration: const InputDecoration(labelText: 'Scheduled Time'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              repo.updateLogisticsStatus(
                id,
                'Scheduled',
                scheduledTime: timeCtrl.text,
              );
              timeCtrl.dispose();
              Navigator.pop(context);
              showMessage(context, 'Pickup scheduled!');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DeepGlassCard(
      padding: 12,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedCounterText(
                  value: value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final CivicReport r;
  const _AdminReportCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return DeepGlassCard(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _statusColor(r.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.report_problem_rounded,
                  color: _statusColor(r.status),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF264653),
                      ),
                    ),
                    Text(
                      '${r.category} • ${r.wardName ?? r.wardId ?? 'Unknown Ward'}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (r.isSlaBreached)
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.orange,
                  size: 16,
                ),
            ],
          ),
          if (r.status == 'Pending') ...[
            const SizedBox(height: 8),
            Row(
              children: _departments.map((dept) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: () {
                        repo.acceptAndAssignReport(r.id, dept);
                        showMessage(context, '${t('assigned')} to $dept');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF2A9D8F,
                        ).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF2A9D8F),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        dept,
                        style: const TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (r.status == 'Assigned') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      repo.updateReportStatus(r.id, 'In Progress');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFE9C46A,
                      ).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFFE9C46A),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'In Progress',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      repo.updateReportStatus(r.id, 'Resolved');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF52B788,
                      ).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFF52B788),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Resolve',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      repo.updateReportStatus(r.id, 'Rejected');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFE76F51,
                      ).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFFE76F51),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
void _showEditProfileDialog(BuildContext context, AppUser user) {
  final nameCtrl = TextEditingController(text: user.name);
  final addrCtrl = TextEditingController(text: user.address);
  final emailCtrl = TextEditingController(text: user.email);
  final passCtrl = TextEditingController(text: user.password);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(appState.t('edit_profile')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: appState.t('full_name'))),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, decoration: InputDecoration(labelText: appState.t('city_village'))),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: appState.t('email_optional'))),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, decoration: InputDecoration(labelText: appState.t('password'))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(appState.t('cancel'))),
        ElevatedButton(
          onPressed: () async {
            user.name = nameCtrl.text.trim();
            user.address = addrCtrl.text.trim();
            user.email = emailCtrl.text.trim();
            user.password = passCtrl.text.trim();
            appState.refreshProfile();
            try {
              if (Firebase.apps.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'name': user.name,
                  'address': user.address,
                  'email': user.email,
                  'password': user.password,
                });
              }
            } catch (e) {
              debugPrint('Edit profile error: $e');
            }
            nameCtrl.dispose(); addrCtrl.dispose();
            emailCtrl.dispose(); passCtrl.dispose();
            if (context.mounted) {
              Navigator.pop(context);
              showMessage(context, appState.t('profile_updated'));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A9D8F),
            foregroundColor: Colors.white,
          ),
          child: Text(appState.t('save')),
        ),
      ],
    ),
  );
}
// ==========================================
// ADMIN ANALYTICS SCREEN
// ==========================================
class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return AnimatedBuilder(
      animation: Listenable.merge([appState, repo]),
      builder: (context, _) {
        final reports = repo.reports;
        final catCounts = <String, int>{};
        for (final r in reports) {
          catCounts[r.category] = (catCounts[r.category] ?? 0) + 1;
        }
        final wardCounts = <String, int>{};
        for (final r in reports) {
          final wn = r.wardName ?? 'Unknown';
          wardCounts[wn] = (wardCounts[wn] ?? 0) + 1;
        }
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StaggeredEntrance(
                index: 0,
                child: Text(
                  t('analytics'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF264653),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Category breakdown
              StaggeredEntrance(
                index: 1,
                child: DeepGlassCard(
                  padding: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('by_category'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (catCounts.isEmpty)
                        const Text(
                          'No data yet',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...catCounts.entries.map((e) {
                          final maxCount = catCounts.values.reduce(
                            (a, b) => a > b ? a : b,
                          );
                          final ratio = e.value / maxCount;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      e.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF264653),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${e.value}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2A9D8F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF2A9D8F),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Ward breakdown
              StaggeredEntrance(
                index: 2,
                child: DeepGlassCard(
                  padding: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('by_ward'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...wardCounts.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF264653),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        (e.value /
                                                (wardCounts.values.reduce(
                                                  (a, b) => a > b ? a : b,
                                                )))
                                            .clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF457B9D),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${e.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF457B9D),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Budget Tracker
              StaggeredEntrance(
                index: 3,
                child: DeepGlassCard(
                  padding: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('budget_tracker'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...appState.wardBudget.entries.map((e) {
                        final allocated = e.value['allocated'] as int;
                        final spent = e.value['spent'] as int;
                        final ratio = spent / allocated;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF264653),
                                    ),
                                  ),
                                  Text(
                                    '₹${(spent / 1000).toStringAsFixed(0)}K / ₹${(allocated / 1000).toStringAsFixed(0)}K',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ratio > 0.85
                                          ? const Color(0xFFE76F51)
                                          : const Color(0xFF52B788),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ratio > 0.85
                                        ? const Color(0xFFE76F51)
                                        : const Color(0xFF52B788),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Community Polls
              StaggeredEntrance(
                index: 4,
                child: DeepGlassCard(
                  padding: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('community_polls'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...appState.polls.asMap().entries.map((pollEntry) {
                        final pi = pollEntry.key;
                        final poll = pollEntry.value;
                        final options = poll['options'] as List<PollOption>;
                        final totalVotes = options.fold(
                          0,
                          (s, o) => s + o.votes,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                poll['question'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF264653),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...options.asMap().entries.map((optEntry) {
                                final oi = optEntry.key;
                                final opt = optEntry.value;
                                final pct = totalVotes == 0
                                    ? 0.0
                                    : opt.votes / totalVotes;
                                final alreadyVoted =
                                    (poll['votedBy'] as Set<String>).contains(
                                      appState.currentUser?.uid ?? '',
                                    );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: GestureDetector(
                                    onTap: alreadyVoted
                                        ? null
                                        : () => appState.votePoll(pi, oi),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2A9D8F,
                                        ).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                FractionallySizedBox(
                                                  widthFactor: pct.clamp(
                                                    0.0,
                                                    1.0,
                                                  ),
                                                  child: Container(
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF2A9D8F,
                                                      ).withValues(alpha: 0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 3,
                                                      ),
                                                  child: Text(
                                                    opt.label,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                      color: Color(0xFF264653),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${(pct * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2A9D8F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Ward Notices
              StaggeredEntrance(
                index: 5,
                child: DeepGlassCard(
                  padding: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('ward_notices'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF264653),
                              fontSize: 16,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddNoticeDialog(context),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text(
                              'Add',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...appState.wardNotices
                          .take(4)
                          .map(
                            (notice) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF457B9D,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notice.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF264653),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      notice.body,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: const Color(
                                          0xFF264653,
                                        ).withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _wardNameFromId(notice.wardId) ??
                                              notice.wardId,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF457B9D),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _timeAgo(notice.createdAt),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _showAddNoticeDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedWard = _wardData.first['id'] as String;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Ward Notice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedWard,
                items: _wardData
                    .map(
                      (w) => DropdownMenuItem(
                        value: w['id'] as String,
                        child: Text(w['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedWard = v ?? selectedWard),
                decoration: const InputDecoration(labelText: 'Ward'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  appState.addWardNotice(
                    WardNotice(
                      id: 'wn_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim(),
                      wardId: selectedWard,
                      createdAt: DateTime.now(),
                    ),
                  );
                  titleCtrl.dispose();
                  bodyCtrl.dispose();
                  Navigator.pop(ctx);
                  showMessage(context, 'Notice posted!');
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ADMIN USERS SCREEN
// ==========================================
// ==========================================
// ADMIN USERS SCREEN
// ==========================================
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _sortBy = 'reports';
  String _roleFilter = 'All';
  List<AppUser> _firestoreUsers = [];
  bool _loadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      if (Firebase.apps.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .get();
        _firestoreUsers = snap.docs
            .map((d) => AppUser.fromMap(d.data()))
            .toList();
      }
    } catch (e) {
      debugPrint('Load users error: $e');
    }
    if (mounted) setState(() => _loadingUsers = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return SafeArea(
      child: AnimatedBuilder(
        animation: repo,
        builder: (context, _) {
          final allReports = repo.reports;

          // Merge Firestore users with report-only users
          final reportUserIds = allReports.map((r) => r.userId).toSet();
          final firestoreIds = _firestoreUsers.map((u) => u.uid).toSet();
          // Users only in reports (no Firestore record)
          final reportOnlyIds = reportUserIds.difference(firestoreIds);
          final reportOnlyUsers = reportOnlyIds.map((uid) => AppUser(
                uid: uid,
                role: 'Public',
                name: uid,
                phone: '',
                address: '',
                email: '',
                password: '',
              )).toList();

          List<AppUser> allUsers = [..._firestoreUsers, ...reportOnlyUsers];

          // Role filter
          if (_roleFilter != 'All') {
            allUsers = allUsers.where((u) => u.role == _roleFilter).toList();
          }

          // Search
          if (_searchQuery.isNotEmpty) {
            allUsers = allUsers.where((u) =>
              u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              u.phone.contains(_searchQuery) ||
              u.uid.toLowerCase().contains(_searchQuery.toLowerCase())
            ).toList();
          }

          // Sort
          allUsers.sort((a, b) {
            final aReports = allReports.where((r) => r.userId == a.uid).length;
            final bReports = allReports.where((r) => r.userId == b.uid).length;
            if (_sortBy == 'resolved') {
              final aRes = allReports.where((r) => r.userId == a.uid && r.status == 'Resolved').length;
              final bRes = allReports.where((r) => r.userId == b.uid && r.status == 'Resolved').length;
              return bRes.compareTo(aRes);
            }
            if (_sortBy == 'name') return a.name.compareTo(b.name);
            return bReports.compareTo(aReports);
          });

          final publicCount = _firestoreUsers.where((u) => u.role == 'Public').length;
          final farmerCount = _firestoreUsers.where((u) => u.role == 'Farmer').length;
          final adminCount = _firestoreUsers.where((u) => u.role == 'Admin').length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t('users'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF264653),
                            ),
                          ),
                        ),
                        // Create user button
                        ElevatedButton.icon(
                          onPressed: () => _showCreateUserDialog(context),
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text('Create', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A9D8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Refresh button
                        IconButton(
                          onPressed: _loadUsers,
                          icon: _loadingUsers
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, color: Color(0xFF2A9D8F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Role summary chips
                    Row(
                      children: [
                        _RoleCountChip(label: 'All', count: _firestoreUsers.length, color: const Color(0xFF264653), active: _roleFilter == 'All', onTap: () => setState(() => _roleFilter = 'All')),
                        const SizedBox(width: 6),
                        _RoleCountChip(label: 'Public', count: publicCount, color: const Color(0xFF2A9D8F), active: _roleFilter == 'Public', onTap: () => setState(() => _roleFilter = 'Public')),
                        const SizedBox(width: 6),
                        _RoleCountChip(label: 'Farmer', count: farmerCount, color: const Color(0xFF52B788), active: _roleFilter == 'Farmer', onTap: () => setState(() => _roleFilter = 'Farmer')),
                        const SizedBox(width: 6),
                        _RoleCountChip(label: 'Admin', count: adminCount, color: const Color(0xFFE76F51), active: _roleFilter == 'Admin', onTap: () => setState(() => _roleFilter = 'Admin')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search name, phone, ID...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Sort: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        _SortChip(label: 'Reports', active: _sortBy == 'reports', onTap: () => setState(() => _sortBy = 'reports')),
                        const SizedBox(width: 6),
                        _SortChip(label: 'Resolved', active: _sortBy == 'resolved', onTap: () => setState(() => _sortBy = 'resolved')),
                        const SizedBox(width: 6),
                        _SortChip(label: 'Name', active: _sortBy == 'name', onTap: () => setState(() => _sortBy = 'name')),
                      ],
                    ),
                  ],
                ),
              ),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _AdminMiniStat(label: 'Total Reports', value: allReports.length, color: const Color(0xFF2A9D8F))),
                    const SizedBox(width: 8),
                    Expanded(child: _AdminMiniStat(label: 'Resolved', value: allReports.where((r) => r.status == 'Resolved').length, color: const Color(0xFF52B788))),
                    const SizedBox(width: 8),
                    Expanded(child: _AdminMiniStat(label: 'Pending', value: allReports.where((r) => r.status == 'Pending').length, color: Colors.orange)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _loadingUsers
                    ? const Center(child: CircularProgressIndicator())
                    : allUsers.isEmpty
                        ? const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: allUsers.length,
                            itemBuilder: (_, i) {
                              final user = allUsers[i];
                              final userReports = allReports.where((r) => r.userId == user.uid).toList();
                              final resolved = userReports.where((r) => r.status == 'Resolved').length;
                              final pending = userReports.where((r) => r.status == 'Pending').length;
                              final resolutionPct = userReports.isEmpty ? 0.0 : resolved / userReports.length;
                              final roleColor = user.role == 'Farmer'
                                  ? const Color(0xFF52B788)
                                  : user.role == 'Admin'
                                      ? const Color(0xFFE76F51)
                                      : const Color(0xFF2A9D8F);

                              return StaggeredEntrance(
                                index: i,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TappableGlassCard(
                                    padding: 14,
                                    onTap: () => _showUserDetail(context, user, userReports, resolved, pending),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: roleColor.withValues(alpha: 0.2),
                                            border: Border.all(color: roleColor, width: 1.5),
                                          ),
                                          child: Center(
                                            child: Text(
                                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      user.name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653), fontSize: 13),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: roleColor.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(user.role, style: TextStyle(fontSize: 9, color: roleColor, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                              if (user.phone.isNotEmpty)
                                                Text(user.phone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Text('${userReports.length} reports', style: TextStyle(fontSize: 11, color: const Color(0xFF264653).withValues(alpha: 0.6))),
                                                  if (resolved > 0) ...[
                                                    const SizedBox(width: 6),
                                                    Text('$resolved resolved', style: const TextStyle(fontSize: 11, color: Color(0xFF52B788), fontWeight: FontWeight.w600)),
                                                  ],
                                                  if (pending > 0) ...[
                                                    const SizedBox(width: 6),
                                                    Text('$pending pending', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
                                                  ],
                                                ],
                                              ),
                                              if (userReports.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: resolutionPct,
                                                    minHeight: 4,
                                                    backgroundColor: Colors.grey.shade200,
                                                    valueColor: const AlwaysStoppedAnimation(Color(0xFF52B788)),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserDetail(BuildContext context, AppUser user, List<CivicReport> userReports, int resolved, int pending) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          margin: const EdgeInsets.all(12),
          child: DeepGlassCard(
            padding: 20,
            child: ListView(
              controller: scrollCtrl,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF2A9D8F), Color(0xFF52B788)]),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF264653))),
                          Text(user.role, style: const TextStyle(fontSize: 12, color: Color(0xFF2A9D8F), fontWeight: FontWeight.w600)),
                          if (user.phone.isNotEmpty)
                            Text(user.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    // Edit button
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditUserDialog(context, user);
                      },
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF2A9D8F)),
                    ),
                    // Delete button
                    IconButton(
                      onPressed: () => _confirmDeleteUser(context, user),
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE76F51)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Promote role section
                DeepGlassCard(
                  padding: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Role / Promote', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653), fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Public', 'Farmer', 'Admin'].map((role) {
                          final isActive = user.role == role;
                          final roleColor = role == 'Farmer' ? const Color(0xFF52B788) : role == 'Admin' ? const Color(0xFFE76F51) : const Color(0xFF2A9D8F);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: isActive ? null : () => _promoteUser(context, user, role),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive ? roleColor : roleColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: isActive ? null : Border.all(color: roleColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    role,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? Colors.white : roleColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Stats
                Row(
                  children: [
                    Expanded(child: _AdminMiniStat(label: 'Total', value: userReports.length, color: const Color(0xFF2A9D8F))),
                    const SizedBox(width: 8),
                    Expanded(child: _AdminMiniStat(label: 'Resolved', value: resolved, color: const Color(0xFF52B788))),
                    const SizedBox(width: 8),
                    Expanded(child: _AdminMiniStat(label: 'Pending', value: pending, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 16),
                // User info
                if (user.address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF2A9D8F)),
                        const SizedBox(width: 6),
                        Text(user.address, style: const TextStyle(fontSize: 12, color: Color(0xFF264653))),
                      ],
                    ),
                  ),
                if (user.email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.email_rounded, size: 14, color: Color(0xFF2A9D8F)),
                        const SizedBox(width: 6),
                        Text(user.email, style: const TextStyle(fontSize: 12, color: Color(0xFF264653))),
                      ],
                    ),
                  ),
                // Reports list
                if (userReports.isNotEmpty) ...[
                  const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653), fontSize: 15)),
                  const SizedBox(height: 8),
                  ...userReports.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusColor(r.status).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusColor(r.status).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor(r.status))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF264653))),
                                Text('${r.category} • ${r.wardName ?? 'Unknown'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(r.status, style: TextStyle(fontSize: 11, color: _statusColor(r.status), fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () async {
                                  await repo.deleteReport(r.id);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    showMessage(context, 'Report deleted.');
                                  }
                                },
                                child: const Text('Delete', style: TextStyle(fontSize: 10, color: Color(0xFFE76F51), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, AppUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final addrCtrl = TextEditingController(text: user.address);
    final emailCtrl = TextEditingController(text: user.email);
    final passCtrl = TextEditingController(text: user.password);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 8),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 8),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['Public', 'Farmer', 'Admin']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRole = v ?? selectedRole),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final updates = {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'address': addrCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'password': passCtrl.text.trim(),
                  'role': selectedRole,
                };
                try {
                  if (Firebase.apps.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);
                  }
                } catch (e) {
                  debugPrint('Edit user error: $e');
                }
                nameCtrl.dispose(); phoneCtrl.dispose(); addrCtrl.dispose();
                emailCtrl.dispose(); passCtrl.dispose();
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadUsers();
                if (mounted) showMessage(this.context, 'User created successfully!');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Public';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['Public', 'Farmer', 'Admin']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRole = v ?? selectedRole),
                ),
                const SizedBox(height: 8),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone *')),
                const SizedBox(height: 8),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 8),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password *')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  showMessage(context, 'Name, phone and password are required.', isError: true);
                  return;
                }
                final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
                final newUser = AppUser(
                  uid: uid,
                  role: selectedRole,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  civicPoints: 0,
                );
                try {
                  if (Firebase.apps.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser.toMap());
                  }
                } catch (e) {
                  debugPrint('Create user error: $e');
                }
                nameCtrl.dispose(); phoneCtrl.dispose(); addrCtrl.dispose();
                emailCtrl.dispose(); passCtrl.dispose();
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadUsers();
                if (mounted) showMessage(this.context, 'User updated successfully!');
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promoteUser(BuildContext context, AppUser user, String newRole) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Promote to $newRole?'),
        content: Text('Change ${user.name}\'s role from ${user.role} to $newRole?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': newRole});
      }
    } catch (e) {
      debugPrint('Promote user error: $e');
    }
    await _loadUsers();
    if (context.mounted) {
      Navigator.pop(context);
      showMessage(context, '${user.name} promoted to $newRole!');
    }
  }

  void _confirmDeleteUser(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Remove ${user.name} and all their reports? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reports = repo.reports.where((r) => r.userId == user.uid).toList();
              for (final r in reports) {await repo.deleteReport(r.id); }
              try {
                if (Firebase.apps.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                }
              } catch (_) {}
              await _loadUsers();
              if (context.mounted) {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // bottom sheet
                showMessage(context, 'User deleted successfully.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE76F51), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Helper widgets for AdminUsersScreen
class _RoleCountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _RoleCountChip({required this.label, required this.count, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.white : color),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A9D8F) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.grey)),
      ),
    );
  }
}

class _AdminMiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AdminMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ==========================================
// ADMIN WAREHOUSE SCREEN
// ==========================================
class AdminWarehouseScreen extends StatelessWidget {
  const AdminWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final logistics = repo.logistics;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                t('warehouse'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF264653),
                ),
              ),
              const SizedBox(height: 16),
              // Warehouse cards
              ..._warehouseData.asMap().entries.map((entry) {
                final i = entry.key;
                final w = entry.value;
                final assigned = logistics
                    .where((l) => l.warehouseId == w['id'])
                    .toList();
                return StaggeredEntrance(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DeepGlassCard(
                      padding: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF457B9D,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.warehouse_rounded,
                                  color: Color(0xFF457B9D),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF264653),
                                      ),
                                    ),
                                    Text(
                                      '${w['distance']} away',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (w['crops'] as List).join(', '),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF457B9D),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${w['used']}/${w['capacity']} tons',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF457B9D),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _WarehouseStatChip(
                                label: 'Assigned',
                                value: assigned.length,
                                color: const Color(0xFF2A9D8F),
                              ),
                              const SizedBox(width: 8),
                              _WarehouseStatChip(
                                label: 'Pending',
                                value: assigned
                                    .where((l) => l.status == 'Requested')
                                    .length,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              _WarehouseStatChip(
                                label: 'Delivered',
                                value: assigned
                                    .where((l) => l.status == 'Delivered')
                                    .length,
                                color: const Color(0xFF52B788),
                              ),
                            ],
                          ),
                          if (assigned.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            ...assigned
                                .take(2)
                                .map(
                                  (req) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.local_shipping_rounded,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${req.farmerName}: ${req.crop} ${req.weightKg}kg',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF264653),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (req.status == 'Scheduled' ||
                                            req.status == 'Confirmed')
                                          GestureDetector(
                                            onTap: () =>
                                                repo.updateLogisticsStatus(
                                                  req.id,
                                                  'Picked Up',
                                                ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF52B788,
                                                ).withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Mark Picked Up',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Color(0xFF52B788),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _WarehouseStatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _WarehouseStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
