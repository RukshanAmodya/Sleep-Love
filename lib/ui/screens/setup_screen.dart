import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../providers/audio_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final audioState = ref.read(audioProvider);
      if (audioState.availableSounds.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(audioProvider.notifier).startInitialSetup(forPremium: audioState.isPremiumSetupNeeded);
        });
        _isInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/nature_background.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.5),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.downloading_rounded, size: 80, color: AppColors.primary)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2.seconds),
                const SizedBox(height: 40),
                Text(
                  audioState.isPremiumSetupNeeded ? "Setting up Premium Sounds" : "Initial Setup",
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  "Downloading high-quality atmospheric sounds for offline use...",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 60),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: audioState.setupProgress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleGradient,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10)],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "${(audioState.setupProgress * 100).toInt()}%",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
