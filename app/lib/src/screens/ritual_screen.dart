import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/ui_text_utils.dart';
import '../widgets/spiritual_background.dart';
import '../widgets/verse_preview_card.dart';

class RitualScreen extends StatefulWidget {
  const RitualScreen({super.key});

  @override
  State<RitualScreen> createState() => _RitualScreenState();
}

class _RitualScreenState extends State<RitualScreen> {
  final TextEditingController _reflectionController = TextEditingController();
  String? _selectedMood;
  GuidanceResponse? _guidance;
  bool _loadingGuidance = false;
  String? _error;

  int _step = 1;
  int _breathingRemaining = 10;
  Timer? _breathingTimer;
  bool _showCompletion = false;
  Timer? _completionTimer;

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _completionTimer?.cancel();
    _reflectionController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    _breathingTimer?.cancel();
    setState(() {
      _step = 2;
      _breathingRemaining = 10;
      _error = null;
    });

    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_breathingRemaining <= 1) {
        timer.cancel();
        setState(() {
          _breathingRemaining = 0;
          _step = 3;
        });
        return;
      }
      setState(() => _breathingRemaining -= 1);
    });
  }

  void _skipBreathing() {
    _breathingTimer?.cancel();
    setState(() {
      _breathingRemaining = 0;
      _step = 3;
    });
  }

  Future<void> _fetchGuidance(AppState appState, AppStrings strings) async {
    if (_selectedMood == null || _loadingGuidance) {
      return;
    }

    setState(() {
      _loadingGuidance = true;
      _error = null;
    });

    try {
      final guidance = await appState.repository.moodGuidance(
        moods: <String>[_selectedMood!],
        mode: appState.guidanceMode,
        language: appState.languageCode,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _guidance = guidance;
        _step = 4;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = mapFriendlyError(error, strings: strings, context: 'mood');
      });
    } finally {
      if (mounted) {
        setState(() => _loadingGuidance = false);
      }
    }
  }

  Future<void> _openVerse(AppState appState, int verseId, AppStrings strings) async {
    try {
      final verse = await appState.repository.getVerseById(verseId);
      if (!mounted) {
        return;
      }
      await Navigator.pushNamed(context, '/verse', arguments: verse);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('ritual_open_verse_failed'))),
      );
    }
  }

  Future<void> _completeRitual(AppState appState) async {
    await appState.completeRitual(
      reflection: _reflectionController.text.trim().isEmpty
          ? null
          : _reflectionController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _showCompletion = true);
    _completionTimer?.cancel();
    _completionTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _setReminderStub(AppStrings strings) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('ritual_reminder_stub'))),
    );
  }

  int get _progressStep {
    if (_step >= 4) {
      return 3;
    }
    if (_step >= 2) {
      return 2;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final colorScheme = Theme.of(context).colorScheme;
    final moods = appState.moodOptions.isEmpty
        ? const <String>[
            'Anxious',
            'Overwhelmed',
            'Uncertain',
            'Sad',
            'Hopeful',
          ]
        : appState.moodOptions;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('start_today_60_sec'))),
      body: SpiritualBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_showCompletion)
              AnimatedScale(
                scale: _showCompletion ? 1 : 0.95,
                duration: const Duration(milliseconds: 260),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: _showCompletion ? 1 : 0,
                  child: _RitualCompletionCard(strings: strings),
                ),
              )
            else ...<Widget>[
              _RitualProgressHeader(step: _progressStep, strings: strings),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.t('ritual_step_mood'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: moods
                            .map(
                              (mood) => FilterChip(
                                label: Text(strings.moodLabel(mood)),
                                selected: _selectedMood == mood,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedMood = mood;
                                    _error = null;
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _selectedMood == null ? null : _startBreathing,
                        child: Text(strings.t('ritual_continue')),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _step == 2
                    ? Padding(
                        key: const ValueKey<String>('ritual-breathing'),
                        padding: const EdgeInsets.only(top: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  strings.t('ritual_step_breathe'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  strings.t('ritual_breathing_title'),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.t('ritual_breathing_subtitle'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: (10 - _breathingRemaining) / 10,
                                  minHeight: 7,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Text('$_breathingRemaining s'),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _skipBreathing,
                                      child: Text(strings.t('ritual_breathing_skip')),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _step >= 3
                    ? Padding(
                        key: const ValueKey<String>('ritual-verse-step'),
                        padding: const EdgeInsets.only(top: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  strings.t('ritual_step_verse'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                if (appState.dailyVerse != null)
                                  VersePreviewCard(
                                    verse: appState.dailyVerse!,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/verse',
                                      arguments: appState.dailyVerse,
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(strings.t('daily_verse_unavailable')),
                                      const SizedBox(height: 10),
                                      FilledButton.tonalIcon(
                                        onPressed: () => context
                                            .read<AppState>()
                                            .refreshDailyVerse(),
                                        icon: const Icon(Icons.refresh),
                                        label: Text(strings.t('retry')),
                                      ),
                                    ],
                                  ),
                                if (_step == 3) ...<Widget>[
                                  const SizedBox(height: 14),
                                  FilledButton(
                                    onPressed: _loadingGuidance
                                        ? null
                                        : () => _fetchGuidance(appState, strings),
                                    child: _loadingGuidance
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(strings.t('ritual_get_action')),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _guidance != null && _step >= 4
                    ? Padding(
                        key: const ValueKey<String>('ritual-sankalpa-step'),
                        padding: const EdgeInsets.only(top: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  strings.t('ritual_step_action'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${strings.t('ritual_next_hour_sankalpa')}: ${_guidance!.guidanceShort}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _guidance!.verses
                                      .map(
                                        (verse) => ActionChip(
                                          label: Text(
                                            verse.verseId == null
                                                ? 'BG ${verse.ref}'
                                                : 'BG ${verse.ref} - #${verse.verseId}',
                                          ),
                                          onPressed: verse.verseId == null
                                              ? null
                                              : () => _openVerse(
                                                    appState,
                                                    verse.verseId!,
                                                    strings,
                                                  ),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _reflectionController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: strings.t('ritual_optional_reflection'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () => _completeRitual(appState),
                                        child: Text(strings.t('ritual_mark_done')),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _setReminderStub(strings),
                                        child: Text(strings.t('ritual_set_reminder')),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
            if (_error != null && !_showCompletion) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RitualProgressHeader extends StatelessWidget {
  final int step;
  final AppStrings strings;

  const _RitualProgressHeader({required this.step, required this.strings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final current = step.clamp(1, 3);
    final labels = <String>[
      strings.t('ritual_step_reflect'),
      strings.t('ritual_step_read'),
      strings.t('ritual_step_act'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                for (var i = 0; i < 3; i++) ...<Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i + 1 <= current
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.45),
                    ),
                  ),
                  if (i < 2)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i + 1 < current
                            ? colorScheme.primary.withValues(alpha: 0.75)
                            : colorScheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    labels[0],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: current >= 1
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    labels[1],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: current >= 2
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    labels[2],
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: current >= 3
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualCompletionCard extends StatelessWidget {
  final AppStrings strings;

  const _RitualCompletionCard({required this.strings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.self_improvement_rounded,
              size: 46,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              strings.t('ritual_completed_title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              strings.t('ritual_completed_subtitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}