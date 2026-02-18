import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Brahma Muhurta themed background with radial gradient,
/// floating golden dust motes, and soft mandala patterns.
class SpiritualBackground extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool animate;
  final ScrollController? parallaxController;
  final bool enableParallax;

  const SpiritualBackground({
    super.key,
    required this.child,
    this.padding,
    this.animate = true,
    this.parallaxController,
    this.enableParallax = false,
  });

  @override
  State<SpiritualBackground> createState() => _SpiritualBackgroundState();
}

class _SpiritualBackgroundState extends State<SpiritualBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  final ValueNotifier<double> _parallaxOffset = ValueNotifier<double>(0);
  Timer? _timePhaseTimer;
  int _timeBucket = -1;
  List<Color> _lightGradient = const <Color>[
    Color(0xFFF8F1E7),
    Color(0xFFF3E8D6),
    Color(0xFFEEE3D3),
  ];
  List<Color> _darkGradient = const <Color>[
    Color(0xFF1A1410),
    Color(0xFF231B14),
    Color(0xFF2A221A),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    );
    if (widget.animate) {
      _controller.repeat();
    }
    _attachParallaxController();
    _refreshTimeAwareGradients(force: true);
    _timePhaseTimer = Timer.periodic(
      const Duration(minutes: 12),
      (_) => _refreshTimeAwareGradients(),
    );
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
    if (oldWidget.parallaxController != widget.parallaxController ||
        oldWidget.enableParallax != widget.enableParallax) {
      _detachParallaxController(oldWidget.parallaxController);
      _attachParallaxController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTimeAwareGradients(force: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timePhaseTimer?.cancel();
    _detachParallaxController(widget.parallaxController);
    _parallaxOffset.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark ? _darkGradient : _lightGradient;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_controller, _parallaxOffset]),
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: widget.child,
      ),
      builder: (context, child) {
        final parallax = widget.enableParallax ? _parallaxOffset.value : 0;

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: gradientColors,
              stops: const <double>[0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -100,
                right: -30,
                child: Transform.translate(
                  offset: Offset(parallax * 0.02, -parallax * 0.06),
                  child: _GlowOrb(
                    size: 260,
                    color:
                        (isDark ? const Color(0xFFD4915A) : const Color(0xFFE7B86D))
                            .withValues(alpha: isDark ? 0.16 : 0.22),
                  ),
                ),
              ),
              Positioned(
                bottom: -130,
                left: -40,
                child: Transform.translate(
                  offset: Offset(-parallax * 0.015, -parallax * 0.1),
                  child: _GlowOrb(
                    size: 280,
                    color:
                        (isDark ? const Color(0xFFA5653F) : const Color(0xFFB95A33))
                            .withValues(alpha: isDark ? 0.1 : 0.12),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, -parallax * 0.16),
                    child: Transform.rotate(
                      angle: _controller.value * 2 * pi,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _MandalaPainter(dark: isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _DustMotePainter(
                        progress: widget.animate ? _controller.value : 0,
                        dark: isDark,
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
    );
  }

  void _attachParallaxController() {
    if (!widget.enableParallax || widget.parallaxController == null) {
      _parallaxOffset.value = 0;
      return;
    }
    widget.parallaxController!.addListener(_handleParallaxScroll);
    _handleParallaxScroll();
  }

  void _detachParallaxController(ScrollController? controller) {
    controller?.removeListener(_handleParallaxScroll);
  }

  void _handleParallaxScroll() {
    final controller = widget.parallaxController;
    if (!widget.enableParallax || controller == null || !controller.hasClients) {
      if (_parallaxOffset.value != 0) {
        _parallaxOffset.value = 0;
      }
      return;
    }
    final next = controller.offset;
    if ((next - _parallaxOffset.value).abs() > 0.4) {
      _parallaxOffset.value = next;
    }
  }

  void _refreshTimeAwareGradients({bool force = false}) {
    final now = DateTime.now();
    final bucket = now.hour * 2 + (now.minute ~/ 30);
    if (!force && bucket == _timeBucket) {
      return;
    }
    _timeBucket = bucket;
    final decimalHour = now.hour + (now.minute / 60.0);
    final light = _paletteForHour(decimalHour, dark: false);
    final dark = _paletteForHour(decimalHour, dark: true);
    if (!mounted) {
      _lightGradient = light;
      _darkGradient = dark;
      return;
    }
    setState(() {
      _lightGradient = light;
      _darkGradient = dark;
    });
  }

  List<Color> _paletteForHour(double hour, {required bool dark}) {
    final anchors = dark ? _darkAnchors : _lightAnchors;
    final normalizedHour = hour.clamp(0.0, 23.99);

    _PaletteAnchor start = anchors.first;
    _PaletteAnchor end = anchors.last;

    for (var i = 0; i < anchors.length - 1; i++) {
      final a = anchors[i];
      final b = anchors[i + 1];
      if (normalizedHour >= a.hour && normalizedHour < b.hour) {
        start = a;
        end = b;
        break;
      }
    }

    final span = (end.hour - start.hour).clamp(0.01, 24.0);
    final t = ((normalizedHour - start.hour) / span).clamp(0.0, 1.0);
    return List<Color>.generate(
      3,
      (index) => Color.lerp(start.colors[index], end.colors[index], t)!,
      growable: false,
    );
  }

  static const List<_PaletteAnchor> _lightAnchors = <_PaletteAnchor>[
    _PaletteAnchor(
      hour: 0,
      colors: <Color>[
        Color(0xFFE7DFD5),
        Color(0xFFD9CFC3),
        Color(0xFFCDC0B3),
      ],
    ),
    _PaletteAnchor(
      hour: 5,
      colors: <Color>[
        Color(0xFFBBAAA0),
        Color(0xFFCCB59D),
        Color(0xFFE1CCB3),
      ],
    ),
    _PaletteAnchor(
      hour: 7,
      colors: <Color>[
        Color(0xFFF6EBDD),
        Color(0xFFF2E3CC),
        Color(0xFFECDABF),
      ],
    ),
    _PaletteAnchor(
      hour: 11,
      colors: <Color>[
        Color(0xFFF8F1E7),
        Color(0xFFF3E8D6),
        Color(0xFFEEE3D3),
      ],
    ),
    _PaletteAnchor(
      hour: 17,
      colors: <Color>[
        Color(0xFFF2E3D1),
        Color(0xFFE7D0BA),
        Color(0xFFD9B89A),
      ],
    ),
    _PaletteAnchor(
      hour: 20,
      colors: <Color>[
        Color(0xFFE5D2C5),
        Color(0xFFD5BCB0),
        Color(0xFFC7AEA3),
      ],
    ),
    _PaletteAnchor(
      hour: 24,
      colors: <Color>[
        Color(0xFFE7DFD5),
        Color(0xFFD9CFC3),
        Color(0xFFCDC0B3),
      ],
    ),
  ];

  static const List<_PaletteAnchor> _darkAnchors = <_PaletteAnchor>[
    _PaletteAnchor(
      hour: 0,
      colors: <Color>[
        Color(0xFF111725),
        Color(0xFF181F2D),
        Color(0xFF1F2634),
      ],
    ),
    _PaletteAnchor(
      hour: 5,
      colors: <Color>[
        Color(0xFF1E2430),
        Color(0xFF2A2D33),
        Color(0xFF353036),
      ],
    ),
    _PaletteAnchor(
      hour: 7,
      colors: <Color>[
        Color(0xFF2A2627),
        Color(0xFF352D2A),
        Color(0xFF423630),
      ],
    ),
    _PaletteAnchor(
      hour: 11,
      colors: <Color>[
        Color(0xFF1A1410),
        Color(0xFF231B14),
        Color(0xFF2A221A),
      ],
    ),
    _PaletteAnchor(
      hour: 17,
      colors: <Color>[
        Color(0xFF221A15),
        Color(0xFF2A2019),
        Color(0xFF34271E),
      ],
    ),
    _PaletteAnchor(
      hour: 20,
      colors: <Color>[
        Color(0xFF1C1A22),
        Color(0xFF22202A),
        Color(0xFF292731),
      ],
    ),
    _PaletteAnchor(
      hour: 24,
      colors: <Color>[
        Color(0xFF111725),
        Color(0xFF181F2D),
        Color(0xFF1F2634),
      ],
    ),
  ];
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

class _PaletteAnchor {
  final double hour;
  final List<Color> colors;

  const _PaletteAnchor({
    required this.hour,
    required this.colors,
  });
}
