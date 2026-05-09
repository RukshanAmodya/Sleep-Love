import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AtmosphericOverlay extends StatefulWidget {
  final bool showRain;
  final bool showThunder;
  final Widget child;

  const AtmosphericOverlay({
    super.key,
    required this.child,
    this.showRain = false,
    this.showThunder = false,
  });

  @override
  State<AtmosphericOverlay> createState() => _AtmosphericOverlayState();
}

class _AtmosphericOverlayState extends State<AtmosphericOverlay> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  bool _isFlashing = false;
  late AnimationController _rainController;
  final List<Droplet> _droplets = [];

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initDroplets();

    if (widget.showThunder) {
      _startThunderCycle();
    }
  }

  void _initDroplets() {
    for (int i = 0; i < 50; i++) {
      _droplets.add(Droplet(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        isMoving: _random.nextDouble() > 0.7,
        speed: 0.002 + _random.nextDouble() * 0.005,
      ));
    }
  }

  void _startThunderCycle() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 10 + _random.nextInt(15)));
      if (widget.showThunder && mounted) {
        setState(() => _isFlashing = true);
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _isFlashing = false);
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _isFlashing = true);
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() => _isFlashing = false);
      }
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Static Background (Removed Parallax)
        Positioned.fill(child: widget.child),
        
        // Advanced Rain on Glass
        if (widget.showRain)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rainController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AdvancedRainPainter(_droplets, _rainController.value),
                );
              },
            ),
          ),

        // Thunder Flash
        if (_isFlashing)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
      ],
    );
  }
}

class Droplet {
  double x;
  double y;
  double size;
  bool isMoving;
  double speed;

  Droplet({required this.x, required this.y, required this.size, this.isMoving = false, this.speed = 0});
}

class AdvancedRainPainter extends CustomPainter {
  final List<Droplet> droplets;
  final double animationValue;
  final Random random = Random();

  AdvancedRainPainter(this.droplets, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var droplet in droplets) {
      if (droplet.isMoving) {
        droplet.y += droplet.speed;
        if (droplet.y > 1.0) {
          droplet.y = -0.1;
          droplet.x = random.nextDouble();
        }
      }

      final pos = Offset(droplet.x * size.width, droplet.y * size.height);
      
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          pos,
          droplet.size,
          [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.05),
          ],
        );
      
      canvas.drawCircle(pos, droplet.size, paint);

      final glarePaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
      canvas.drawCircle(pos.translate(-droplet.size * 0.3, -droplet.size * 0.3), droplet.size * 0.2, glarePaint);

      if (droplet.isMoving) {
        final trailPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = droplet.size * 0.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(pos, pos.translate(0, -20), trailPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
