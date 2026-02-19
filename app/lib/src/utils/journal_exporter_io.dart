import 'dart:io';

Future<String?> exportJournalToJsonFile(String jsonText) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}gita_journal_$timestamp.json');
  await file.writeAsString(jsonText, flush: true);
  return file.path;
}
