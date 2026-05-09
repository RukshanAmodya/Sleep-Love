import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer.clearGlass(
      height: double.infinity,
      width: double.infinity,
      borderRadius: BorderRadius.circular(borderRadius),
      borderWidth: 1,
      color: Colors.white.withOpacity(0.05),
      borderColor: Colors.white.withOpacity(0.1),
      padding: padding,
      child: child,
    );
  }
}
