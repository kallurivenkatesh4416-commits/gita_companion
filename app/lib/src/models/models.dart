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
  final int verseCount;

  const ChapterSummary({
    required this.chapter,
    required this.verseCount,
  });

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    return ChapterSummary(
      chapter: json['chapter'] as int,
      verseCount: json['verse_count'] as int? ?? 0,
    );
  }
}

class VerseStats {
  final int totalVerses;
  final int expectedMinimum;

  const VerseStats({
    required this.totalVerses,
    required this.expectedMinimum,
  });

  factory VerseStats.fromJson(Map<String, dynamic> json) {
    return VerseStats(
      totalVerses: json['total_verses'] as int? ?? 0,
      expectedMinimum: json['expected_minimum'] as int? ?? 700,
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

class GuidanceResponse {
  final String mode;
  final String topic;
  final List<GuidanceVerse> verses;
  final String guidanceShort;
  final String guidanceLong;
  final MicroPractice microPractice;
  final String reflectionPrompt;
  final SafetyMeta safety;

  const GuidanceResponse({
    required this.mode,
    required this.topic,
    required this.verses,
    required this.guidanceShort,
    required this.guidanceLong,
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

class ChatResponse {
  final String mode;
  final String reply;
  final List<GuidanceVerse> verses;
  final String actionStep;
  final String reflectionPrompt;
  final SafetyMeta safety;

  const ChatResponse({
    required this.mode,
    required this.reply,
    required this.verses,
    required this.actionStep,
    required this.reflectionPrompt,
    required this.safety,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      mode: json['mode'] as String,
      reply: json['reply'] as String,
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

  const Journey({
    required this.id,
    required this.title,
    required this.description,
    required this.days,
    required this.status,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      days: json['days'] as int,
      status: json['status'] as String,
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
