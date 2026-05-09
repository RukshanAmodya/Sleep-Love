import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants.dart';
import 'services/firebase_service.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';
import 'providers/audio_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.init();
  await AdService().initialize();
  await NotificationService.init();
  runApp(const ProviderScope(child: SleepLoveApp()));
}

class SleepLoveApp extends StatelessWidget {
  const SleepLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthWrapper()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/sleepie_background.png',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: AppColors.bgDark),
          ),
          Container(color: Colors.black.withValues(alpha: 0.2)),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Sleep Love",
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 20, color: Colors.black45)],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Try bedtime stories, sleep sounds &\nmeditations to help you fall asleep fast.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              Container(
                width: 200,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(seconds: 4),
                      builder: (c, val, child) => Container(
                        width: 200 * val,
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ],
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // If setup is not complete OR Pro setup is needed
          if (!audioState.isSetupComplete || audioState.isProSetupNeeded) {
            return const SetupScreen();
          }
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
