# One Smart Era (OneNation Hub) 🇮🇳🌾🏛️
> **Next-Generation Smart City Civic Grievance & Farmer Assistance Platform**  
> Empowering Citizens, Farmers, and Municipal Administrators across Tamil Nadu with real-time incident tracking, AI crop diagnostics, live APMC Mandi price discovery, cold storage logistics, and automated welfare scheme eligibility.

---

## 🌟 Key Features

### 👤 1. Public Citizen Hub
- **Instant Civic Issue Reporting**: Geo-tagged grievance filing with Camera/Gallery photo attachments, GPS auto-detection, and street reverse geocoding.
- **Interactive Civic Map**: Live OpenStreetMap canvas rendering municipal complaints with category filters (Roads, Water, Sanitation, Street Lights, Health) and SLA breach indicators.
- **Civic Rewards System**: Earn Civic Points for filing verified reports and tracking repair progress to unlock badges (Active Citizen, Silver Citizen, Gold Champion, Platinum Champion).
- **Emergency SOS Broadcast**: 3-second hold emergency trigger with expanding pulse ripple, haptic vibration, and immediate dispatch to municipal ward officers.
- **Welfare Schemes & Eligibility Calculator**: Interactive wizard matching citizens to central and state schemes (PM-Kisan, Kalaignar Magalir Urimai Thittam, CMCHIS, PMAY) based on age, income, and land ownership.
- **Ward Announcements & Decision Polls**: Live community voting on municipal priority projects with instant percentage bars.

### 🌾 2. Farmer Hub
- **Live APMC Mandi Price Discovery**: Real-time market rates across Tamil Nadu districts (Erode, Sathyamangalam, Gobichettipalayam, Coimbatore, Salem) with 7-day sparkline charts, predicted price trends, and demand ratings.
- **Price Alert Subscriptions**: 1-tap alerts on price spikes and drops for major crops (Tomato, Onion, Banana, Turmeric, Coconut, Sugarcane).
- **AI Crop Doctor (Plant Pathology)**: Upload or photograph infected crop leaves for instant disease diagnosis, severity grading, organic bio-remedies, chemical spray prescriptions, and field prevention strategies.
- **Cold Storage & Logistics Booking**: Monitor storage occupancy meters (e.g. Sathy Cold Storage 320/500 MT) and book farm-to-mandi pickup trucks with status tracking (Requested -> Scheduled -> Picked Up -> Delivered).
- **Cooperative Freight Pooling**: Combine produce loads with neighboring ward farmers to minimize freight transport costs.
- **Direct Farmer Marketplace**: List harvest produce directly to APMC wholesale buyers without middleman overhead.

### 🏛️ 3. City Official & Admin Operations
- **Live KPI Command Center**: Real-time metrics on Total Reports, Resolution Rate (%), Average Days to Resolution, and Active Emergency SOS alerts.
- **Incident Triage & Department Dispatch**: 1-click assignment to municipal departments (*Roads & Bridges, Water Supply, Sanitation & Solid Waste, TANGEDCO Electricity, Public Health*).
- **SLA Breach Monitoring**: Automated alerts for grievances pending > 7 days.
- **City Grievance Heatmaps & Analytics**: Department workload distribution and ward-by-ward grievance density charts.
- **User Role Administration**: Verified user directory with search, role modification, and account verification toggles.

---

## 🔒 Security & Architecture Remediation

| Previous Vulnerability | Remediated Architecture |
|---|---|
| **Plaintext Passwords in Firestore** | Replaced with **SHA-256 Hashing + Pepper**; passwords are never stored in raw text. |
| **Password Leak in Forgot Password** | Eliminated credential exposure; implemented **Secure 6-Digit OTP Verification** reset flow. |
| **Hardcoded Admin Master Code** | Removed backdoor bypass (`adminMasterCode`); implemented role-based permissions. |
| **12,332-Line Monolith File** | Refactored into **25 clean modular files** across `core/`, `models/`, `providers/`, `widgets/`, `screens/`. |
| **Firebase Initialization Crashes** | Implemented **Graceful Dual-Mode**: Seamlessly operates in offline mode with local caching (`SharedPreferences`). |

---

## 📁 Modular Directory Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Cohesive design system palette & glass tokens
│   │   ├── app_constants.dart      # Global settings, keys, and SLA configurations
│   │   └── mock_data.dart          # Pre-seeded Tamil Nadu APMC mandis, wards, warehouses
│   ├── localization/
│   │   └── app_translations.dart   # Full bilingual dictionary (English & தமிழ்)
│   ├── theme/
│   │   └── app_theme.dart          # Material 3 dark glassmorphic theme
│   └── services/
│       ├── auth_service.dart       # SHA-256 password hashing, OTP verification, sessions
│       ├── storage_service.dart    # Cloud Storage + Base64 offline fallback
│       ├── weather_service.dart    # OpenWeather API with agro-meteorological fallback
│       └── ai_doctor_service.dart  # Groq/Llama Vision API + 8-Crop pathology knowledge base
├── models/
│   ├── user_model.dart             # AppUser with role properties and champion badges
│   ├── civic_report_model.dart     # CivicReport with coordinates and SLA tracking
│   ├── crop_model.dart             # CropItem, CropListing, Cooperative, PollOption
│   ├── logistics_model.dart        # LogisticsRequest & status timeline
│   ├── diagnosis_model.dart        # DiagnosisEntry & pathology remedies
│   ├── notification_model.dart     # AppNotification & WardNotice
│   └── scheme_model.dart           # SchemeModel & eligibility evaluation
├── providers/
│   ├── app_state.dart              # Global UI state, language, active user, weather, SOS
│   └── data_repository.dart        # Real-time Firestore streams & offline data cache
├── widgets/
│   ├── animated_mesh_background.dart # 60fps dynamic mesh background
│   ├── glass_card.dart             # Frosted glass card with border gradient & glow
│   ├── sos_button.dart             # 3-second hold emergency SOS button
│   ├── sparkline_chart.dart        # 7-day Mandi price trend graph
│   ├── staggered_entrance.dart     # Micro-animation entrance wrappers
│   ├── shimmer_box.dart            # Smooth loading skeletons
│   └── common_widgets.dart         # Status chips, KPI cards, custom app bars
├── screens/
│   ├── auth/
│   │   ├── role_selection_screen.dart # Role portal (Citizen, Farmer, Admin)
│   │   ├── login_screen.dart          # Sign In with demo 1-click access
│   │   ├── register_screen.dart       # Account creation with validation
│   │   └── forgot_password_screen.dart# Secure OTP password reset
│   ├── citizen/
│   │   ├── public_home_screen.dart    # Citizen dashboard & civic points
│   │   ├── report_screen.dart         # Issue filing with Camera & GPS
│   │   ├── civic_map_screen.dart      # Interactive OpenStreetMap canvas
│   │   ├── news_feed_screen.dart      # Ward notices & community polls
│   │   ├── schemes_screen.dart        # Welfare programs directory
│   │   ├── eligibility_screen.dart    # Welfare eligibility calculator
│   │   ├── profile_screen.dart        # Citizen profile & champion badge
│   │   └── notifications_screen.dart  # Live notification inbox
│   ├── farmer/
│   │   ├── farmer_home_screen.dart    # Farmer hub & agro advisory
│   │   ├── market_screen.dart         # APMC Mandi rates & marketplace
│   │   ├── crop_doctor_screen.dart    # AI plant pathology scanner
│   │   └── farmer_logistics_screen.dart # Cold storage & freight booking
│   └── admin/
│       ├── admin_dashboard_screen.dart# Live KPIs & incident triage
│       ├── admin_analytics_screen.dart# SLA metrics & ward density
│       ├── admin_users_screen.dart    # User directory & verification
│       └── admin_warehouse_screen.dart# Cold storage oversight
├── screens/main_shell.dart         # Dynamic role-tailored bottom navigation
└── main.dart                       # App entry point (< 60 lines)
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0` or higher)
- Android Studio / VS Code with Flutter extension
- Firebase project (configured via `firebase_options.dart`)

### Installation
```bash
# Clone the repository
git clone https://github.com/sugan0025/one-smart-era.git
cd one-smart-era

# Get dependencies
flutter pub get

# Run on Chrome / Connected Device
flutter run
```

---

## 🎨 Design System & Aesthetics
- **Primary Emerald**: `#10B981` (Growth, Sustainability, Civic Progress)
- **Deep Forest Teal**: `#0F766E` (Structure, Municipal Governance)
- **Amber Gold**: `#F59E0B` (Harvest, Mandi Commerce, Agricultural Vitality)
- **Ocean Blue**: `#0EA5E9` (Infrastructure, Water, Logistics)
- **Crimson Red**: `#EF4444` (Emergency SOS & SLA Alert)
- **Ultra Dark Slate**: `#0A1118` & `#0F172A` (High-contrast glassmorphism with 60fps radial mesh gradients)

---

## 🌐 Localization
Built-in bilingual dictionary with instant 1-tap switching:
- **English (`en`)**
- **தமிழ் / Tamil (`ta`)**

---

## 📄 License
This project is licensed under the MIT License.
