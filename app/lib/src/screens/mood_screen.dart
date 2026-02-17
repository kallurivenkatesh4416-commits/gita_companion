import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/guidance_panel.dart';

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
      setState(() => _error = 'Pick at least one mood.');
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
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        mode: appState.guidanceMode,
      );
      setState(() => _guidance = response);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;
    final moods = appState.moodOptions.isEmpty
        ? const <String>['Anxious', 'Overwhelmed', 'Uncertain', 'Sad', 'Hopeful']
        : appState.moodOptions;

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Check-in')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('How are you feeling right now?',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Choose moods and add a short note if useful. You will get verse guidance + a micro-practice.',
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
                              label: Text(mood),
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
                      decoration: const InputDecoration(
                        labelText: 'Optional note',
                        hintText: 'Write one line about what is weighing on you.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Loading...' : 'Get Guidance'),
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
              GuidancePanel(guidance: _guidance!),
              const SizedBox(height: 12),
              Text('Selected verses', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._guidance!.verses.map(
                (verse) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Verse ${verse.ref}', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(verse.translation),
                        const SizedBox(height: 8),
                        Text(
                          verse.whyThis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
