import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reusable minimal eco-themed background wrapper with subtle floating leaf/circle animations
class EcoBackgroundWrapper extends StatefulWidget {
  final Widget child;
  const EcoBackgroundWrapper({super.key, required this.child});

  @override
  State<EcoBackgroundWrapper> createState() => _EcoBackgroundWrapperState();
}

class _EcoBackgroundWrapperState extends State<EcoBackgroundWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Subtle Animated Eco Background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _EcoBackgroundPatternPainter(progress: _controller.value),
              child: Container(),
            );
          },
        ),

        // 2. Foreground Content
        widget.child,
      ],
    );
  }
}

class _EcoBackgroundPatternPainter extends CustomPainter {
  final double progress;
  _EcoBackgroundPatternPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgGradient = LinearGradient(
      colors: [
        const Color(0xFFF8FAF8),
        const Color(0xFFF0FDF4).withValues(alpha: 0.95),
        const Color(0xFFE8F5E9).withValues(alpha: 0.75),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    canvas.drawRect(rect, Paint()..shader = bgGradient.createShader(rect));

    // Floating eco orbs with soft organic movement
    final orb1 = Paint()..color = const Color(0xFF22C55E).withValues(alpha: 0.055);
    final orb2 = Paint()..color = const Color(0xFF15803D).withValues(alpha: 0.045);
    final orb3 = Paint()..color = const Color(0xFF0284C7).withValues(alpha: 0.03);

    final x1 = size.width * (0.85 - 0.08 * math.sin(progress * math.pi));
    final y1 = size.height * (0.18 + 0.05 * math.cos(progress * math.pi));
    canvas.drawCircle(Offset(x1, y1), 140, orb1);

    final x2 = size.width * (0.12 + 0.1 * math.cos(progress * math.pi));
    final y2 = size.height * (0.75 - 0.06 * math.sin(progress * math.pi));
    canvas.drawCircle(Offset(x2, y2), 170, orb2);

    final x3 = size.width * (0.80 + 0.06 * math.cos(progress * math.pi));
    final y3 = size.height * (0.60 + 0.04 * math.sin(progress * math.pi));
    canvas.drawCircle(Offset(x3, y3), 110, orb3);
  }

  @override
  bool shouldRepaint(covariant _EcoBackgroundPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
