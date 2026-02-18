import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/ui_text_utils.dart';
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

  IconData _moodVisual(String mood) {
    final key = mood.toLowerCase();
    if (key.contains('anx')) return Icons.waves_rounded;
    if (key.contains('over')) return Icons.cloud_queue_rounded;
    if (key.contains('uncertain')) return Icons.blur_on_rounded;
    if (key.contains('sad')) return Icons.air_rounded;
    if (key.contains('hope')) return Icons.wb_sunny_outlined;
    if (key.contains('grateful')) return Icons.wb_sunny_rounded;
    if (key.contains('angry')) return Icons.local_fire_department_outlined;
    if (key.contains('unmotivated')) return Icons.landscape_outlined;
    return Icons.self_improvement_outlined;
  }

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);

    if (_selectedMoods.isEmpty) {
      setState(() => _error = strings.t('pick_one_mood'));
      return;
    }
    if (_selectedMoods.length > 3) {
      setState(() => _error = strings.t('mood_select_up_to_three'));
      return;
    }

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
      if (!mounted) {
        return;
      }
      setState(() => _guidance = response);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = mapFriendlyError(
          error,
          strings: strings,
          context: 'mood',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
            'Hopeful',
          ]
        : appState.moodOptions;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('mood_title'))),
      body: SpiritualBackground(
        animate: false,
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
                      strings.t('mood_heading'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.t('mood_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.t('mood_select_up_to_three'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 560 ? 4 : 3;
                        const spacing = 10.0;
                        final tileWidth =
                            (constraints.maxWidth - ((columns - 1) * spacing)) /
                                columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: moods
                              .map(
                                (mood) => SizedBox(
                                  width: tileWidth,
                                  child: _MoodChoiceTile(
                                    label: strings.moodLabel(mood),
                                    visual: _moodVisual(mood),
                                    selected: _selectedMoods.contains(mood),
                                    onTap: () {
                                      setState(() {
                                        if (_selectedMoods.contains(mood)) {
                                          _selectedMoods.remove(mood);
                                        } else if (_selectedMoods.length < 3) {
                                          _selectedMoods.add(mood);
                                        } else {
                                          _error = strings.t('mood_select_up_to_three');
                                        }
                                      });
                                    },
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
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
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(_loading ? '...' : strings.t('get_guidance')),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                          TextButton(
                            onPressed: _loading ? null : _submit,
                            child: Text(strings.t('try_again')),
                          ),
                        ],
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
              Text(
                strings.t('selected_verses'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ..._guidance!.verses.map(
                (verse) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Verse ${verse.ref}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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

class _MoodChoiceTile extends StatelessWidget {
  final String label;
  final IconData visual;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChoiceTile({
    required this.label,
    required this.visual,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    colorScheme.secondary.withValues(alpha: 0.18),
                    colorScheme.primary.withValues(alpha: 0.14),
                  ],
                )
              : null,
          color: selected ? null : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? colorScheme.secondary
                : colorScheme.outline.withValues(alpha: 0.5),
            width: selected ? 1.3 : 1,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.secondary.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(visual, size: 22, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
