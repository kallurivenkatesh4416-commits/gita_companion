import 'dart:math';

import 'package:flutter/material.dart';

/// Brahma Muhurta themed background with radial gradient,
/// floating golden dust motes, and soft mandala patterns.
class SpiritualBackground extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SpiritualBackground({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  State<SpiritualBackground> createState() => _SpiritualBackgroundState();
}

class _SpiritualBackgroundState extends State<SpiritualBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: <Color>[
            Color(0xFFF8F1E7), // center - warm parchment
            Color(0xFFF3E8D6), // mid
            Color(0xFFEEE3D3), // outer edge
          ],
          stops: <double>[0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Soft glow orbs
          Positioned(
            top: -100,
            right: -30,
            child: _GlowOrb(
              size: 260,
              color: const Color(0xFFE7B86D).withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -40,
            child: _GlowOrb(
              size: 280,
              color: const Color(0xFFB95A33).withValues(alpha: 0.12),
            ),
          ),
          // Mandala rings
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _MandalaPainter()),
            ),
          ),
          // Floating dust motes
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DustMotePainter(progress: _controller.value),
                  );
                },
              ),
            ),
          ),
          // Content
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color,
            color.withValues(alpha: 0.02),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _MandalaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.22);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF92522F).withValues(alpha: 0.12);

    for (var i = 1; i <= 6; i++) {
      canvas.drawCircle(center, 22.0 * i, paint);
    }

    final secondary = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF88503F).withValues(alpha: 0.07);

    final lowerCenter = Offset(size.width * 0.18, size.height * 0.86);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(lowerCenter, 20.0 * i, secondary);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws 8 golden dust motes drifting slowly across the screen.
class _DustMotePainter extends CustomPainter {
  final double progress;

  _DustMotePainter({required this.progress});

  static final List<_Mote> _motes = List.generate(8, (i) {
    final rng = Random(i * 37 + 7);
    return _Mote(
      startX: rng.nextDouble(),
      startY: rng.nextDouble(),
      driftX: (rng.nextDouble() - 0.5) * 0.25,
      driftY: (rng.nextDouble() - 0.5) * 0.18,
      size: 2.0 + rng.nextDouble() * 3.5,
      opacity: 0.10 + rng.nextDouble() * 0.20,
      phaseOffset: rng.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final mote in _motes) {
      final t = (progress + mote.phaseOffset) % 1.0;
      final x = (mote.startX + mote.driftX * t) % 1.0 * size.width;
      final y = (mote.startY + mote.driftY * t) % 1.0 * size.height;
      // Fade in/out at edges of cycle
      final fade = sin(t * pi);
      final alpha = (mote.opacity * fade).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = Color(0xFFDAA520).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(Offset(x, y), mote.size, paint);
    }
  }

  @override
  bool shouldRepaint(_DustMotePainter old) => old.progress != progress;
}

class _Mote {
  final double startX, startY, driftX, driftY, size, opacity, phaseOffset;

  const _Mote({
    required this.startX,
    required this.startY,
    required this.driftX,
    required this.driftY,
    required this.size,
    required this.opacity,
    required this.phaseOffset,
  });
}
