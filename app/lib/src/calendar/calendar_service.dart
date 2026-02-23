import 'festival.dart';

/// Provides the Hindu festival calendar dataset for 2025–2026.
///
/// All dates are widely-observed Gregorian approximations.
/// No network calls — purely static, synchronous data.
class CalendarService {
  const CalendarService();

  // ── Static dataset ─────────────────────────────────────────────────────────

  static final List<Festival> _festivals = [
    // ── 2025 ─────────────────────────────────────────────────────────────────
    Festival(
      id:           'makar_sankranti',
      name:         'Makar Sankranti',
      nameHi:       'मकर संक्रान्ति',
      date:         DateTime(2025, 1, 14),
      significance: 'The sun enters Capricorn, marking the harvest season and the end of winter.',
    ),
    Festival(
      id:           'maha_shivaratri',
      name:         'Maha Shivaratri',
      nameHi:       'महाशिवरात्रि',
      date:         DateTime(2025, 2, 26),
      significance: 'The great night of Shiva — a vigil of devotion, fasting, and inner awakening.',
    ),
    Festival(
      id:           'holi',
      name:         'Holi',
      nameHi:       'होली',
      date:         DateTime(2025, 3, 14),
      significance: 'The festival of colours celebrates the triumph of good over evil and the arrival of spring.',
    ),
    Festival(
      id:           'ram_navami',
      name:         'Ram Navami',
      nameHi:       'राम नवमी',
      date:         DateTime(2025, 4, 6),
      significance: 'Celebrates the birth of Lord Rama, the seventh avatar of Vishnu and embodiment of dharma.',
    ),
    Festival(
      id:           'hanuman_jayanti',
      name:         'Hanuman Jayanti',
      nameHi:       'हनुमान जयंती',
      date:         DateTime(2025, 4, 12),
      significance: 'Marks the birth of Hanuman — the supreme devotee embodying strength and selfless service.',
    ),
    Festival(
      id:           'akshaya_tritiya',
      name:         'Akshaya Tritiya',
      nameHi:       'अक्षय तृतीया',
      date:         DateTime(2025, 4, 30),
      significance: 'An auspicious day of eternal prosperity; any virtuous act performed today never diminishes.',
    ),
    Festival(
      id:           'rath_yatra',
      name:         'Rath Yatra',
      nameHi:       'रथ यात्रा',
      date:         DateTime(2025, 6, 27),
      significance: "Lord Jagannath's chariot procession — the divine descending to be with all people.",
    ),
    Festival(
      id:           'guru_purnima',
      name:         'Guru Purnima',
      nameHi:       'गुरु पूर्णिमा',
      date:         DateTime(2025, 7, 10),
      significance: 'A day to honour the Guru — the radiant lamp that dispels the darkness of ignorance.',
    ),
    Festival(
      id:           'raksha_bandhan',
      name:         'Raksha Bandhan',
      nameHi:       'रक्षा बन्धन',
      date:         DateTime(2025, 8, 9),
      significance: 'A sacred thread ties the eternal bond of protection and love between siblings.',
    ),
    Festival(
      id:           'krishna_janmashtami',
      name:         'Krishna Janmashtami',
      nameHi:       'कृष्ण जन्माष्टमी',
      date:         DateTime(2025, 8, 16),
      significance: 'The birth of Lord Krishna — the divine teacher of the Bhagavad Gita, love and wisdom incarnate.',
    ),
    Festival(
      id:           'ganesh_chaturthi',
      name:         'Ganesh Chaturthi',
      nameHi:       'गणेश चतुर्थी',
      date:         DateTime(2025, 8, 27),
      significance: 'Welcoming Ganesha, the remover of obstacles, who blesses every new beginning with joy.',
    ),
    Festival(
      id:           'navratri',
      name:         'Navratri',
      nameHi:       'नवरात्रि',
      date:         DateTime(2025, 9, 22),
      significance: 'Nine nights of worship of the divine feminine — Shakti in her nine glorious forms.',
    ),
    Festival(
      id:           'dussehra',
      name:         'Dussehra',
      nameHi:       'दशहरा',
      date:         DateTime(2025, 10, 2),
      significance: "The victory of Rama over Ravana — good always triumphs over evil when dharma is upheld.",
    ),
    Festival(
      id:           'diwali',
      name:         'Diwali',
      nameHi:       'दीपावली',
      date:         DateTime(2025, 10, 20),
      significance: 'The festival of lights — rows of lamps declaring that light is mightier than darkness.',
    ),
    Festival(
      id:           'kartik_purnima',
      name:         'Kartik Purnima',
      nameHi:       'कार्तिक पूर्णिमा',
      date:         DateTime(2025, 11, 5),
      significance: 'A sacred full moon for offering lamps on holy rivers and honouring ancestors.',
    ),
    Festival(
      id:           'gita_jayanti',
      name:         'Gita Jayanti',
      nameHi:       'गीता जयंती',
      date:         DateTime(2025, 12, 1),
      significance: 'The day Krishna revealed the Bhagavad Gita to Arjuna — the birth of eternal wisdom.',
    ),

    // ── 2026 ─────────────────────────────────────────────────────────────────
    Festival(
      id:           'makar_sankranti',
      name:         'Makar Sankranti',
      nameHi:       'मकर संक्रान्ति',
      date:         DateTime(2026, 1, 14),
      significance: 'The sun enters Capricorn, marking the harvest season and the end of winter.',
    ),
    Festival(
      id:           'maha_shivaratri',
      name:         'Maha Shivaratri',
      nameHi:       'महाशिवरात्रि',
      date:         DateTime(2026, 2, 15),
      significance: 'The great night of Shiva — a vigil of devotion, fasting, and inner awakening.',
    ),
    Festival(
      id:           'holi',
      name:         'Holi',
      nameHi:       'होली',
      date:         DateTime(2026, 3, 3),
      significance: 'The festival of colours celebrates the triumph of good over evil and the arrival of spring.',
    ),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// All festivals sorted by date.
  List<Festival> allFestivals() {
    final sorted = List<Festival>.from(_festivals)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  /// Upcoming festivals (today included), sorted by date, capped at [limit].
  List<Festival> upcomingFestivals({int limit = 10}) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    final result = _festivals.where((f) {
      final d = DateTime(f.date.year, f.date.month, f.date.day);
      return !d.isBefore(todayMidnight);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return result.take(limit).toList();
  }

  /// The single next upcoming festival, or null when calendar data is exhausted.
  Festival? nextFestival() {
    final upcoming = upcomingFestivals(limit: 1);
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
