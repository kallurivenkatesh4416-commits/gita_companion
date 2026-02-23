import 'package:flutter/material.dart';

import '../ui/shared/design_tokens.dart';

/// A single Hindu festival entry.
@immutable
class Festival {
  final String id;

  /// English name
  final String name;

  /// Devanagari name
  final String nameHi;

  final DateTime date;

  /// One-sentence significance shown in the UI.
  final String significance;

  const Festival({
    required this.id,
    required this.name,
    required this.nameHi,
    required this.date,
    required this.significance,
  });

  /// Number of days until this festival (negative = already passed).
  int get daysUntil {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final festMidnight  = DateTime(date.year, date.month, date.day);
    return festMidnight.difference(todayMidnight).inDays;
  }

  bool get isToday    => daysUntil == 0;
  bool get isUpcoming => daysUntil >= 0;

  /// Festival colour resolved from [DesignColors.festival] by [id].
  Color get festivalColor =>
      DesignColors.festival[id] ?? DesignColors.festival['default']!;
}
