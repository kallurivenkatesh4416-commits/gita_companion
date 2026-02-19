import '../models/models.dart';

// Feature flag stays off by default until curated audio assets are added.
const bool kEnableVerseRecitation =
    bool.fromEnvironment('ENABLE_VERSE_RECITATION', defaultValue: false);

// Map key format: "<chapter>.<verse>", value: Flutter asset path.
const Map<String, String> _verseAudioAssetByRef = <String, String>{
  // Example:
  // '2.47': 'assets/audio/verses/bg_2_47.mp3',
};

String? verseAudioAssetFor(Verse verse) {
  if (!kEnableVerseRecitation) {
    return null;
  }

  final key = '${verse.chapter}.${verse.verseNumber}';
  return _verseAudioAssetByRef[key];
}
