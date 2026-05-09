import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final Alignment contentAlignment;

  TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.contentAlignment = Alignment.bottomCenter,
  });
}

class TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip; // Added skip callback

  const TourOverlay({
    super.key, 
    required this.steps, 
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  int currentStep = 0;

  void next() {
    setState(() {
      if (currentStep < widget.steps.length - 1) {
        currentStep++;
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[currentStep];
    
    final renderObject = step.targetKey.currentContext?.findRenderObject();
    Offset offset = Offset.zero;
    Size size = Size.zero;

    if (renderObject is RenderBox) {
      offset = renderObject.localToGlobal(Offset.zero);
      size = renderObject.size;
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Darkened background with hole
          GestureDetector(
            onTap: next,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.8),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  if (size != Size.zero)
                    Positioned(
                      top: offset.dy - 10,
                      left: offset.dx - 10,
                      child: Container(
                        width: size.width + 20,
                        height: size.height + 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          Positioned(
            top: offset.dy > MediaQuery.of(context).size.height / 2 ? offset.dy - 220 : offset.dy + size.height + 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20)],
                  ),
                  child: Column(
                    children: [
                      Text(
                        step.title,
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: widget.onSkip,
                            child: const Text("Skip Tour", style: TextStyle(color: Colors.white38)),
                          ),
                          ElevatedButton(
                            onPressed: next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              currentStep == widget.steps.length - 1 ? "Start" : "Next",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
