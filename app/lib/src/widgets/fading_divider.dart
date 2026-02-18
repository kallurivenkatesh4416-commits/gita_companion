import 'package:flutter/material.dart';

class FadingDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final EdgeInsetsGeometry margin;
  final Color? color;

  const FadingDivider({
    super.key,
    this.height = 16,
    this.thickness = 1,
    this.margin = EdgeInsets.zero,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ??
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);

    return Padding(
      padding: margin,
      child: SizedBox(
        height: height,
        child: Center(
          child: Container(
            height: thickness,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  baseColor.withValues(alpha: 0),
                  baseColor,
                  baseColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
