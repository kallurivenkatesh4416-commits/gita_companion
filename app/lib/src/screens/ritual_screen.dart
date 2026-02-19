import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../errors/app_error_mapper.dart';
import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';
import '../widgets/verification_badge_panel.dart';
import '../widgets/verse_recitation_control.dart';
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

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _fetchGuidance(AppState appState) async {
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
        _step = 3;
      });
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(
        () => _error = AppErrorMapper.toUserMessage(
          error,
          AppStrings(appState.languageCode),
          stackTrace: stackTrace,
          context: 'RitualScreen.fetchGuidance',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingGuidance = false);
      }
    }
  }

  Future<void> _openVerse(
      AppState appState, int verseId, AppStrings strings) async {
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

  Future<void> _completeRitual(AppState appState, AppStrings strings) async {
    final linkedVerse =
        _guidance?.verses.isNotEmpty == true ? _guidance!.verses.first : null;

    await appState.completeRitual(
      reflection: _reflectionController.text.trim().isEmpty
          ? null
          : _reflectionController.text.trim(),
      moodTag: _selectedMood,
      linkedVerseId: linkedVerse?.verseId ?? appState.dailyVerse?.id,
      linkedVerseRef: linkedVerse?.ref ?? appState.dailyVerse?.ref,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('ritual_done_message'))),
    );
    Navigator.pop(context);
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
                      onPressed: _selectedMood == null
                          ? null
                          : () => setState(() => _step = 2),
                      child: Text(strings.t('ritual_continue')),
                    ),
                  ],
                ),
              ),
            ),
            if (_step >= 2) ...<Widget>[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.t('ritual_step_verse'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 10),
                      if (appState.dailyVerse != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            VersePreviewCard(
                              verse: appState.dailyVerse!,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/verse',
                                arguments: appState.dailyVerse,
                              ),
                            ),
                            const SizedBox(height: 10),
                            VerseRecitationControl(
                              verse: appState.dailyVerse!,
                              strings: strings,
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              appState.dailyVerseError ??
                                  strings.t('daily_verse_unavailable'),
                            ),
                            const SizedBox(height: 10),
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  context.read<AppState>().refreshDailyVerse(),
                              icon: const Icon(Icons.refresh),
                              label: Text(strings.t('retry')),
                            ),
                          ],
                        ),
                      if (_step == 2) ...<Widget>[
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _loadingGuidance
                              ? null
                              : () => _fetchGuidance(appState),
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
            ],
            if (_guidance != null && _step >= 3) ...<Widget>[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.t('ritual_step_action'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 10),
                      VerificationBadgePanel(
                        strings: strings,
                        verificationLevel: _guidance!.verificationLevel,
                        verificationDetails: _guidance!.verificationDetails,
                        provenance: _guidance!.provenance,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${strings.t('ritual_action_for_now')}: ${_guidance!.guidanceShort}',
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
                                      : 'BG ${verse.ref} · #${verse.verseId}',
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
                      FilledButton(
                        onPressed: () => _completeRitual(appState, strings),
                        child: Text(strings.t('ritual_mark_done')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
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
