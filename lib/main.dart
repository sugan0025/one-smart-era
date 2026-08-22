import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_state.dart';
import 'providers/data_repository.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientations to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system navigation overlay styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase with graceful offline error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase Initialized Successfully!');
  } catch (e) {
    debugPrint('Firebase connection bypassed. Running in offline mode. Error: $e');
  }

  runApp(const OneNationApp());
}

/// Root Application Widget for One Smart Era (OneNation Hub)
class OneNationApp extends StatelessWidget {
  const OneNationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: appState.isLoggedIn ? const MainShell() : const RoleSelectionScreen(),
        );
      },
    );
  }
}
