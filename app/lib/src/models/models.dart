class Verse {
  final int id;
  final int chapter;
  final int verseNumber;
  final String ref;
  final String sanskrit;
  final String transliteration;
  final String translation;
  final List<String> tags;

  const Verse({
    required this.id,
    required this.chapter,
    required this.verseNumber,
    required this.ref,
    required this.sanskrit,
    required this.transliteration,
    required this.translation,
    required this.tags,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] as int,
      chapter: json['chapter'] as int,
      verseNumber: json['verse_number'] as int,
      ref: json['ref'] as String,
      sanskrit: json['sanskrit'] as String,
      transliteration: json['transliteration'] as String,
      translation: json['translation'] as String,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }
}

class ChapterSummary {
  final int chapter;
  final String name;
  final int verseCount;
  final String summary;

  const ChapterSummary({
    required this.chapter,
    required this.name,
    required this.verseCount,
    required this.summary,
  });

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    return ChapterSummary(
      chapter: json['chapter'] as int,
      name: json['name'] as String,
      verseCount: json['verse_count'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
    );
  }
}

class GuidanceVerse {
  final int? verseId;
  final String ref;
  final String sanskrit;
  final String transliteration;
  final String translation;
  final String whyThis;

  const GuidanceVerse({
    this.verseId,
    required this.ref,
    required this.sanskrit,
    required this.transliteration,
    required this.translation,
    required this.whyThis,
  });

  factory GuidanceVerse.fromJson(Map<String, dynamic> json) {
    return GuidanceVerse(
      verseId: json['verse_id'] as int?,
      ref: json['ref'] as String,
      sanskrit: json['sanskrit'] as String,
      transliteration: json['transliteration'] as String,
      translation: json['translation'] as String,
      whyThis: json['why_this'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'ref': ref,
      'sanskrit': sanskrit,
      'transliteration': transliteration,
      'translation': translation,
      'why_this': whyThis,
    };
    if (verseId != null) {
      payload['verse_id'] = verseId;
    }
    return payload;
  }
}

class MicroPractice {
  final String title;
  final List<String> steps;
  final int durationMinutes;

  const MicroPractice({
    required this.title,
    required this.steps,
    required this.durationMinutes,
  });

  factory MicroPractice.fromJson(Map<String, dynamic> json) {
    return MicroPractice(
      title: json['title'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((value) => value.toString())
          .toList(growable: false),
      durationMinutes: json['duration_minutes'] as int,
    );
  }
}

class SafetyMeta {
  final bool flagged;
  final String? message;

  const SafetyMeta({
    required this.flagged,
    required this.message,
  });

  factory SafetyMeta.fromJson(Map<String, dynamic> json) {
    return SafetyMeta(
      flagged: json['flagged'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

class VerificationCheck {
  final String name;
  final bool passed;
  final String note;

  const VerificationCheck({
    required this.name,
    required this.passed,
    required this.note,
  });

  factory VerificationCheck.fromJson(Map<String, dynamic> json) {
    return VerificationCheck(
      name: json['name'] as String? ?? '',
      passed: json['passed'] as bool? ?? false,
      note: json['note'] as String? ?? '',
    );
  }
}

class ProvenanceVerse {
  final int verseId;
  final int chapter;
  final int verse;
  final String sanskrit;
  final String translationSource;

  const ProvenanceVerse({
    required this.verseId,
    required this.chapter,
    required this.verse,
    required this.sanskrit,
    required this.translationSource,
  });

  factory ProvenanceVerse.fromJson(Map<String, dynamic> json) {
    return ProvenanceVerse(
      verseId: json['verse_id'] as int? ?? 0,
      chapter: json['chapter'] as int? ?? 0,
      verse: json['verse'] as int? ?? 0,
      sanskrit: json['sanskrit'] as String? ?? '',
      translationSource: json['translation_source'] as String? ?? '',
    );
  }
}

class GuidanceResponse {
  final String mode;
  final String topic;
  final List<GuidanceVerse> verses;
  final String guidanceShort;
  final String guidanceLong;
  final String answerText;
  final String verificationLevel;
  final List<VerificationCheck> verificationDetails;
  final List<ProvenanceVerse> provenance;
  final MicroPractice microPractice;
  final String reflectionPrompt;
  final SafetyMeta safety;

  const GuidanceResponse({
    required this.mode,
    required this.topic,
    required this.verses,
    required this.guidanceShort,
    required this.guidanceLong,
    required this.answerText,
    required this.verificationLevel,
    required this.verificationDetails,
    required this.provenance,
    required this.microPractice,
    required this.reflectionPrompt,
    required this.safety,
  });

  factory GuidanceResponse.fromJson(Map<String, dynamic> json) {
    return GuidanceResponse(
      mode: json['mode'] as String,
      topic: json['topic'] as String,
      verses: (json['verses'] as List<dynamic>)
          .map((value) => GuidanceVerse.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      guidanceShort: json['guidance_short'] as String,
      guidanceLong: json['guidance_long'] as String,
      answerText:
          json['answer_text'] as String? ?? (json['guidance_long'] as String),
      verificationLevel: json['verification_level'] as String? ?? 'RAW',
      verificationDetails:
          (json['verification_details'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) =>
                  VerificationCheck.fromJson(value as Map<String, dynamic>))
              .toList(growable: false),
      provenance: (json['provenance'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) =>
              ProvenanceVerse.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      microPractice: MicroPractice.fromJson(
          json['micro_practice'] as Map<String, dynamic>),
      reflectionPrompt: json['reflection_prompt'] as String,
      safety: SafetyMeta.fromJson(json['safety'] as Map<String, dynamic>),
    );
  }
}

class ChatTurn {
  final String role;
  final String content;

  const ChatTurn({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role,
      'content': content,
    };
  }

  factory ChatTurn.fromJson(Map<String, dynamic> json) {
    return ChatTurn(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }
}

class ChatHistoryEntry {
  final String role;
  final String text;
  final DateTime createdAt;

  const ChatHistoryEntry({
    required this.role,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChatHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ChatHistoryEntry(
      role: json['role'] as String,
      text: json['text'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  ChatTurn toTurn() {
    return ChatTurn(role: role, content: text);
  }
}

class JournalEntry {
  final String id;
  final DateTime createdAt;
  final String? moodTag;
  final int? verseId;
  final String? verseRef;
  final String text;

  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.text,
    this.moodTag,
    this.verseId,
    this.verseRef,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      moodTag: json['mood_tag'] as String?,
      verseId: json['verse_id'] as int?,
      verseRef: json['verse_ref'] as String?,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'mood_tag': moodTag,
      'verse_id': verseId,
      'verse_ref': verseRef,
      'text': text,
    };
  }
}

class ChatResponse {
  final String mode;
  final String reply;
  final String answerText;
  final String verificationLevel;
  final List<VerificationCheck> verificationDetails;
  final List<ProvenanceVerse> provenance;
  final List<GuidanceVerse> verses;
  final String actionStep;
  final String reflectionPrompt;
  final SafetyMeta safety;

  const ChatResponse({
    required this.mode,
    required this.reply,
    required this.answerText,
    required this.verificationLevel,
    required this.verificationDetails,
    required this.provenance,
    required this.verses,
    required this.actionStep,
    required this.reflectionPrompt,
    required this.safety,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      mode: json['mode'] as String,
      reply: json['reply'] as String,
      answerText: json['answer_text'] as String? ?? (json['reply'] as String),
      verificationLevel: json['verification_level'] as String? ?? 'RAW',
      verificationDetails:
          (json['verification_details'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) =>
                  VerificationCheck.fromJson(value as Map<String, dynamic>))
              .toList(growable: false),
      provenance: (json['provenance'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) =>
              ProvenanceVerse.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      verses: (json['verses'] as List<dynamic>)
          .map((value) => GuidanceVerse.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      actionStep: json['action_step'] as String,
      reflectionPrompt: json['reflection_prompt'] as String,
      safety: SafetyMeta.fromJson(json['safety'] as Map<String, dynamic>),
    );
  }
}

class FavoriteItem {
  final int id;
  final Verse verse;
  final DateTime createdAt;

  const FavoriteItem({
    required this.id,
    required this.verse,
    required this.createdAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as int,
      verse: Verse.fromJson(json['verse'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Journey {
  final String id;
  final String title;
  final String description;
  final int days;
  final String status;
  final List<JourneyDay> plan;

  const Journey({
    required this.id,
    required this.title,
    required this.description,
    required this.days,
    required this.status,
    this.plan = const <JourneyDay>[],
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    final rawPlan = json['plan'] ?? json['days_plan'];
    final plan = rawPlan is List<dynamic>
        ? rawPlan
            .whereType<Map<String, dynamic>>()
            .map(JourneyDay.fromJson)
            .toList(growable: false)
        : const <JourneyDay>[];

    return Journey(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      days: json['days'] as int,
      status: json['status'] as String,
      plan: plan,
    );
  }

  Journey copyWith({
    String? id,
    String? title,
    String? description,
    int? days,
    String? status,
    List<JourneyDay>? plan,
  }) {
    return Journey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      days: days ?? this.days,
      status: status ?? this.status,
      plan: plan ?? this.plan,
    );
  }
}

class JourneyDay {
  final int day;
  final int chapter;
  final int verseNumber;
  final String verseRef;
  final String verseFocus;
  final String commentary;
  final String microPractice;
  final String reflectionPrompt;

  const JourneyDay({
    required this.day,
    required this.chapter,
    required this.verseNumber,
    required this.verseRef,
    required this.verseFocus,
    required this.commentary,
    required this.microPractice,
    required this.reflectionPrompt,
  });

  factory JourneyDay.fromJson(Map<String, dynamic> json) {
    return JourneyDay(
      day: json['day'] as int,
      chapter: json['chapter'] as int,
      verseNumber: json['verse_number'] as int,
      verseRef: json['verse_ref'] as String,
      verseFocus: json['verse_focus'] as String,
      commentary: json['commentary'] as String,
      microPractice: json['micro_practice'] as String,
      reflectionPrompt: json['reflection_prompt'] as String,
    );
  }
}

/// A single bookmarked item — either a verse or an AI chat answer.
class BookmarkItem {
  final String id;
  final DateTime createdAt;

  /// 'verse' or 'answer'
  final String type;

  // Verse bookmark fields
  final int? verseId;
  final String? verseRef;
  final String? sanskrit;
  final String? translation;

  // AI-answer bookmark fields
  final String? answerText;
  final String? question;

  const BookmarkItem({
    required this.id,
    required this.createdAt,
    required this.type,
    this.verseId,
    this.verseRef,
    this.sanskrit,
    this.translation,
    this.answerText,
    this.question,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['id'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      type: json['type'] as String? ?? 'verse',
      verseId: json['verse_id'] as int?,
      verseRef: json['verse_ref'] as String?,
      sanskrit: json['sanskrit'] as String?,
      translation: json['translation'] as String?,
      answerText: json['answer_text'] as String?,
      question: json['question'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'verse_id': verseId,
      'verse_ref': verseRef,
      'sanskrit': sanskrit,
      'translation': translation,
      'answer_text': answerText,
      'question': question,
    };
  }

  /// Create a bookmark from a Verse object.
  factory BookmarkItem.fromVerse(Verse verse) {
    return BookmarkItem(
      id: 'bk_v${verse.id}_${DateTime.now().microsecondsSinceEpoch}',
      createdAt: DateTime.now(),
      type: 'verse',
      verseId: verse.id,
      verseRef: verse.ref,
      sanskrit: verse.sanskrit,
      translation: verse.translation,
    );
  }

  /// Create a bookmark from an AI chat answer.
  factory BookmarkItem.fromAnswer({
    required String answer,
    required String question,
  }) {
    return BookmarkItem(
      id: 'bk_a_${DateTime.now().microsecondsSinceEpoch}',
      createdAt: DateTime.now(),
      type: 'answer',
      answerText: answer,
      question: question,
    );
  }
}

/// A named collection of bookmarks (e.g. "Morning", "Difficult times").
class BookmarkCollection {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<BookmarkItem> items;

  const BookmarkCollection({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
  });

  factory BookmarkCollection.fromJson(Map<String, dynamic> json) {
    return BookmarkCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => BookmarkItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  BookmarkCollection copyWith({
    String? name,
    List<BookmarkItem>? items,
  }) {
    return BookmarkCollection(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}

class MorningBackground {
  final String name;
  final List<String> palette;
  final String imagePrompt;

  const MorningBackground({
    required this.name,
    required this.palette,
    required this.imagePrompt,
  });

  factory MorningBackground.fromJson(Map<String, dynamic> json) {
    return MorningBackground(
      name: json['name'] as String,
      palette: (json['palette'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      imagePrompt: json['image_prompt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'palette': palette,
      'image_prompt': imagePrompt,
    };
  }
}

class MorningGreeting {
  final DateTime date;
  final String mode;
  final String language;
  final String greeting;
  final GuidanceVerse verse;
  final String meaning;
  final String affirmation;
  final MorningBackground background;

  const MorningGreeting({
    required this.date,
    required this.mode,
    required this.language,
    required this.greeting,
    required this.verse,
    required this.meaning,
    required this.affirmation,
    required this.background,
  });

  factory MorningGreeting.fromJson(Map<String, dynamic> json) {
    return MorningGreeting(
      date: DateTime.parse(json['date'] as String),
      mode: json['mode'] as String,
      language: json['language'] as String,
      greeting: json['greeting'] as String,
      verse: GuidanceVerse.fromJson(json['verse'] as Map<String, dynamic>),
      meaning: json['meaning'] as String,
      affirmation: json['affirmation'] as String,
      background: MorningBackground.fromJson(
          json['background'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date.toIso8601String().split('T').first,
      'mode': mode,
      'language': language,
      'greeting': greeting,
      'verse': verse.toJson(),
      'meaning': meaning,
      'affirmation': affirmation,
      'background': background.toJson(),
    };
  }
}
