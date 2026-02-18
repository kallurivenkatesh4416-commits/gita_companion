import 'dart:math';

import 'package:flutter/material.dart';

/// Brahma Muhurta themed background with radial gradient,
/// floating golden dust motes, and soft mandala patterns.
class SpiritualBackground extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool animate;

  const SpiritualBackground({
    super.key,
    required this.child,
    this.padding,
    this.animate = true,
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
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpiritualBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate == widget.animate) {
      return;
    }
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: isDark
              ? const <Color>[
                  Color(0xFF1A1410),
                  Color(0xFF231B14),
                  Color(0xFF2A221A),
                ]
              : const <Color>[
                  Color(0xFFF8F1E7),
                  Color(0xFFF3E8D6),
                  Color(0xFFEEE3D3),
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
              color: (isDark ? const Color(0xFFD4915A) : const Color(0xFFE7B86D))
                  .withValues(alpha: isDark ? 0.16 : 0.22),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -40,
            child: _GlowOrb(
              size: 280,
              color: (isDark ? const Color(0xFFA5653F) : const Color(0xFFB95A33))
                  .withValues(alpha: isDark ? 0.1 : 0.12),
            ),
          ),
          // Mandala rings
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _MandalaPainter(dark: isDark)),
            ),
          ),
          // Floating dust motes
          if (widget.animate)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _DustMotePainter(
                        progress: _controller.value,
                        dark: isDark,
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DustMotePainter(
                    progress: 0,
                    dark: isDark,
                  ),
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
  final bool dark;

  _MandalaPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.22);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (dark ? const Color(0xFFD4915A) : const Color(0xFF92522F))
          .withValues(alpha: dark ? 0.14 : 0.12);

    for (var i = 1; i <= 6; i++) {
      canvas.drawCircle(center, 22.0 * i, paint);
    }

    final secondary = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = (dark ? const Color(0xFFB78054) : const Color(0xFF88503F))
          .withValues(alpha: dark ? 0.1 : 0.07);

    final lowerCenter = Offset(size.width * 0.18, size.height * 0.86);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(lowerCenter, 20.0 * i, secondary);
    }
  }

  @override
  bool shouldRepaint(covariant _MandalaPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

/// Draws 8 golden dust motes drifting slowly across the screen.
class _DustMotePainter extends CustomPainter {
  final double progress;
  final bool dark;

  _DustMotePainter({required this.progress, required this.dark});

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
        ..color = (dark ? const Color(0xFFD9A56F) : const Color(0xFFDAA520))
            .withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(Offset(x, y), mote.size, paint);
    }
  }

  @override
  bool shouldRepaint(_DustMotePainter old) =>
      old.progress != progress || old.dark != dark;
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
