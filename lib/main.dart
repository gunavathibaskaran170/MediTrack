import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/vitals_logging.dart';
import 'screens/symptom_diary.dart';
import 'screens/doctor_visits.dart';
import 'screens/prescriptions_screen.dart';
import 'screens/health_report.dart';
import 'screens/emergency_sos.dart';
import 'screens/edit_profile_screen.dart';

import 'theme/meditrack_theme.dart';
import 'providers/user_provider.dart';
import 'providers/vitals_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/analytics_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  try {
    await NotificationService().initialize();
    await NotificationService().scheduleDailyVitalsReminder();
  } catch (e) {
    debugPrint("Failed to initialize notifications: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => VitalsProvider()..loadVitals()..loadTodayVitals()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()..loadMedicines()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()..loadAnalytics()),
      ],
      child: const MediTrackApp(),
    ),
  );
}

class MediTrackApp extends StatelessWidget {
  const MediTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediTrack',
      debugShowCheckedModeBanner: false,
      theme: MediTrackTheme.lightTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const NavigationShell(initialTab: 0),
        '/vitals/log': (context) => const VitalsLoggingScreen(),
        '/vitals/history': (context) => const NavigationShell(initialTab: 1),
        '/medicines': (context) => const NavigationShell(initialTab: 2),
        '/analytics': (context) => const NavigationShell(initialTab: 3),
        '/symptoms': (context) => const SymptomDiaryScreen(),
        '/doctor-visits': (context) => const DoctorVisitsScreen(),
        '/prescriptions': (context) => const PrescriptionsScreen(),
        '/reports': (context) => const HealthReportScreen(),
        '/emergency': (context) => const EmergencySosScreen(),
        '/profile': (context) => const NavigationShell(initialTab: 4),
        '/profile/edit': (context) => const EditProfileScreen(),
      },
    );
  }
}
