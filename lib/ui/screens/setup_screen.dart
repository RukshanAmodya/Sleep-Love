import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../providers/audio_provider.dart';
import 'home_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _setupStarted = false;

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);

    // Use a post-frame callback to safely trigger setup
    if (!_setupStarted && audioState.availableSounds.isNotEmpty) {
      _setupStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(audioProvider.notifier).startInitialSetup();
      });
    }

    // Auto-navigate when complete
    if (audioState.isSetupComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 80, color: AppColors.primary)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 2.seconds)
                  .scale(duration: 1.seconds, curve: Curves.easeInOut),
              const SizedBox(height: 40),
              Text(
                "Setting up your Experience",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "We're preparing high-quality sounds for instant playback. Please wait...",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 60),
              
              // Progress Bar
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: audioState.setupProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.purpleGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10)],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),
              
              const SizedBox(height: 20),
              Text(
                "${(audioState.setupProgress * 100).toInt()}% Complete",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
