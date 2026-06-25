import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/meditrack_theme.dart';
import '../core/database_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_heartController);

    _navigateToNext();
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    // 1. Wait for 1800ms to allow a full heartbeat cycle to play
    await Future.delayed(const Duration(milliseconds: 1800));

    // 2. Initialize DB and seed demo data on first launch
    try {
      await DatabaseHelper.instance.seedDemoDataIfNeeded();
    } catch (e) {
      debugPrint("Error seeding database on splash: $e");
    }

    // 3. Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (mounted) {
      if (onboardingComplete) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                Icons.monitor_heart,
                size: 100,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: MediTrackSpacing.large),
            Text(
              'MediTrack',
              style: context.displayLarge,
            ),
            const SizedBox(height: MediTrackSpacing.small),
            Text(
              'Your health, tracked with care.',
              style: context.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
