import 'dart:ui';

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A reusable glassmorphism card.
///
/// Wraps [child] in a BackdropFilter blur + semi-transparent fill +
/// 0.5 px hairline border.  The entire widget is isolated in a
/// [RepaintBoundary] so the expensive blur pass does not invalidate
/// surrounding layers on rebuild.
///
/// Avoid nesting multiple [GlassCard]s — BackdropFilter is O(screen-pixels)
/// and nesting compounds the cost.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color fillColor;
  final Color borderColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius  = 20,
    this.blurSigma     = GlassTokens.blurCard,
    this.fillColor     = const Color(0x26FFFFFF), // white @ 15 %
    this.borderColor   = GlassTokens.borderLight,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: _GlassSurface(
            fillColor:    fillColor,
            borderColor:  borderColor,
            borderRadius: borderRadius,
            padding:      padding,
            onTap:        onTap,
            child:        child,
          ),
        ),
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  final Widget child;
  final Color fillColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const _GlassSurface({
    required this.child,
    required this.fillColor,
    required this.borderColor,
    required this.borderRadius,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    if (onTap != null) {
      content = Material(
        type:  MaterialType.transparency,
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child:        content,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color:        fillColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border:       Border.all(color: borderColor, width: GlassTokens.borderWidth),
      ),
      child: content,
    );
  }
}
