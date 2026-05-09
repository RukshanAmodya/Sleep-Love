import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';

class LiquidPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  const LiquidPlayButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 600.ms,
        curve: Curves.elasticOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.purpleGradient,
          borderRadius: BorderRadius.circular(isPlaying ? 20 : 35),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Center(
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ).animate(target: isPlaying ? 1 : 0).shake(hz: 2, curve: Curves.easeInOut),
    );
  }
}
