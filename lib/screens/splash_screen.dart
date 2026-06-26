import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/meditrack_theme.dart';
import '../core/database_helper.dart';
import 'package:lottie/lottie.dart';

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

    // 3. Check login status
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('logged_in') ?? false;

    if (mounted) {
      if (loggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
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
            SizedBox(
              width: 120,
              height: 120,
              child: Lottie.network(
                'https://lottie.host/8cd87532-68c3-4d43-a616-24e6503c1535/vA8T3iJplD.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      Icons.monitor_heart,
                      size: 100,
                      color: context.colors.primary,
                    ),
                  );
                },
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
