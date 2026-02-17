import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/guidance_panel.dart';
import '../widgets/spiritual_background.dart';

class MoodCheckInScreen extends StatefulWidget {
  const MoodCheckInScreen({super.key});

  @override
  State<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends State<MoodCheckInScreen> {
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedMoods = <String>{};
  GuidanceResponse? _guidance;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedMoods.isEmpty) {
      final strings = AppStrings(context.read<AppState>().languageCode);
      setState(() => _error = strings.t('pick_one_mood'));
      return;
    }

    final appState = context.read<AppState>();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await appState.repository.moodGuidance(
        moods: _selectedMoods.toList(growable: false),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        mode: appState.guidanceMode,
        language: appState.languageCode,
      );
      if (!mounted) return;
      setState(() => _guidance = response);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings(appState.languageCode);

    final moods = appState.moodOptions.isEmpty
        ? const <String>[
            'Anxious',
            'Overwhelmed',
            'Uncertain',
            'Sad',
            'Hopeful'
          ]
        : appState.moodOptions;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('mood_title'))),
      body: SpiritualBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(strings.t('mood_heading'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      strings.t('mood_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: moods
                          .map(
                            (mood) => FilterChip(
                              label: Text(strings.moodLabel(mood)),
                              selected: _selectedMoods.contains(mood),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedMoods.add(mood);
                                  } else {
                                    _selectedMoods.remove(mood);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: strings.t('mood_note_label'),
                        hintText: strings.t('mood_note_hint'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? '...' : strings.t('get_guidance')),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_guidance != null) ...<Widget>[
              const SizedBox(height: 14),
              GuidancePanel(guidance: _guidance!, strings: strings),
              const SizedBox(height: 12),
              Text(strings.t('selected_verses'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._guidance!.verses.map(
                (verse) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Verse ${verse.ref}',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(verse.translation),
                        const SizedBox(height: 8),
                        Text(
                          verse.whyThis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
