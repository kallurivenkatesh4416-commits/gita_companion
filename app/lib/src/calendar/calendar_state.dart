import 'package:flutter/foundation.dart';

import 'calendar_service.dart';
import 'festival.dart';

/// ChangeNotifier for the Hindu festival calendar.
///
/// Intentionally separate from [AppState] — calendar concerns are unrelated
/// to verse/chat/auth state.  Inject via a second [ChangeNotifierProvider]
/// in main.dart.
class CalendarState extends ChangeNotifier {
  CalendarState({CalendarService? service})
      : _service = service ?? const CalendarService();

  final CalendarService _service;

  List<Festival> _upcoming = const [];
  List<Festival> _all      = const [];

  /// Up to 6 upcoming festivals (today inclusive), sorted by date.
  List<Festival> get upcoming => _upcoming;

  /// All festivals in the dataset, sorted by date.
  List<Festival> get all => _all;

  /// The single next festival, or null.
  Festival? get nextFestival => _upcoming.isEmpty ? null : _upcoming.first;

  /// Call once after construction (inside ChangeNotifierProvider.create).
  void initialize() {
    _upcoming = _service.upcomingFestivals(limit: 6);
    _all      = _service.allFestivals();
    notifyListeners();
  }
}
