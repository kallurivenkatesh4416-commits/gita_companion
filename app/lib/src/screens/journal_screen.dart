import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../errors/app_error_mapper.dart';
import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/journal_exporter.dart';
import '../widgets/spiritual_background.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedVerseRef;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openLinkedVerse(
    AppState appState,
    JournalEntry entry,
    AppStrings strings,
  ) async {
    if (entry.verseId == null) {
      return;
    }
    try {
      final verse = await appState.repository.getVerseById(entry.verseId!);
      if (!mounted) {
        return;
      }
      await Navigator.pushNamed(context, '/verse', arguments: verse);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      final message = AppErrorMapper.toUserMessage(
        error,
        strings,
        stackTrace: stackTrace,
        context: 'JournalScreen.openLinkedVerse',
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _exportJournal(AppState appState, AppStrings strings) async {
    if (appState.journalEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('journal_export_empty'))),
      );
      return;
    }

    try {
      final payload = jsonEncode(
        appState.journalEntries
            .map((entry) => entry.toJson())
            .toList(growable: false),
      );
      final path = await exportJournalToJsonFile(payload);
      if (!mounted) {
        return;
      }

      final message = path == null
          ? strings.t('journal_export_unavailable')
          : '${strings.t('journal_export_done')}: $path';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      final message = AppErrorMapper.toUserMessage(
        error,
        strings,
        stackTrace: stackTrace,
        context: 'JournalScreen.export',
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final entries = appState.journalEntries;
    final verseOptions = entries
        .map((entry) => entry.verseRef?.trim() ?? '')
        .where((ref) => ref.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final query = _searchController.text.trim().toLowerCase();

    final filteredEntries = entries.where((entry) {
      final matchesVerse =
          _selectedVerseRef == null || entry.verseRef == _selectedVerseRef;
      if (!matchesVerse) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack = <String>[
        entry.text,
        entry.moodTag ?? '',
        entry.verseRef ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('journal_title')),
        actions: <Widget>[
          IconButton(
            tooltip: strings.t('journal_export'),
            onPressed: () => _exportJournal(appState, strings),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: SpiritualBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: strings.t('journal_search_hint'),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVerseRef,
                      decoration: InputDecoration(
                        labelText: strings.t('journal_filter_verse'),
                      ),
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(strings.t('journal_filter_all_verses')),
                        ),
                        ...verseOptions.map(
                          (ref) => DropdownMenuItem<String>(
                            value: ref,
                            child: Text('BG $ref'),
                          ),
                        ),
                      ],
                      onChanged: (selected) {
                        setState(() => _selectedVerseRef = selected);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (filteredEntries.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(strings.t('journal_empty')),
                ),
              )
            else
              ...filteredEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _formatTimestamp(entry.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              if (entry.moodTag != null &&
                                  entry.moodTag!.trim().isNotEmpty)
                                Chip(
                                  label: Text(
                                      '${strings.t('journal_mood')}: ${strings.moodLabel(entry.moodTag!)}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (entry.verseRef != null &&
                                  entry.verseRef!.trim().isNotEmpty)
                                ActionChip(
                                  label: Text(
                                      '${strings.t('journal_linked_verse')}: BG ${entry.verseRef!}'),
                                  onPressed: entry.verseId == null
                                      ? null
                                      : () => _openLinkedVerse(
                                            appState,
                                            entry,
                                            strings,
                                          ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.text,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
