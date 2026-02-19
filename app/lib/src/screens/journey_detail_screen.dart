import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class JourneyDetailScreen extends StatelessWidget {
  final Journey journey;

  const JourneyDetailScreen({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final completed = appState.journeyCompletedCount(journey.id);
    final ratio = appState.journeyCompletionRatio(journey.id, journey.days);
    final nextDay = appState.journeyNextDay(journey.id, journey.days);

    return Scaffold(
      appBar: AppBar(title: Text(journey.title)),
      body: SpiritualBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      journey.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${strings.t('journey_progress')}: $completed / ${journey.days}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      completed >= journey.days
                          ? strings.t('journey_complete_message')
                          : '${strings.t('journey_next_day')}: $nextDay',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (journey.plan.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(strings.t('journey_empty_detail')),
              )
            else
              ...journey.plan.map(
                (day) => _JourneyDayCard(journey: journey, day: day),
              ),
          ],
        ),
      ),
    );
  }
}

class _JourneyDayCard extends StatelessWidget {
  final Journey journey;
  final JourneyDay day;

  const _JourneyDayCard({
    required this.journey,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final done = appState.isJourneyDayCompleted(journey.id, day.day);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${strings.t('journey_day')} ${day.day}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'BG ${day.verseRef}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                day.verseFocus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 10),
              _LabelText(
                label: strings.t('journey_commentary'),
                value: day.commentary,
              ),
              const SizedBox(height: 8),
              _LabelText(
                label: strings.t('journey_micro_practice'),
                value: day.microPractice,
              ),
              const SizedBox(height: 8),
              _LabelText(
                label: strings.t('journey_reflection_prompt'),
                value: day.reflectionPrompt,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openVerse(context, day),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(strings.t('journey_open_verse')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.read<AppState>().setJourneyDayCompleted(
                          journeyId: journey.id,
                          day: day.day,
                          completed: !done,
                        ),
                    icon: Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      done
                          ? strings.t('journey_done')
                          : strings.t('journey_mark_done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVerse(BuildContext context, JourneyDay day) async {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);
    await appState.loadChapterVerses(day.chapter);
    if (!context.mounted) {
      return;
    }

    Verse? targetVerse;
    for (final verse in appState.versesForChapter(day.chapter)) {
      if (verse.verseNumber == day.verseNumber) {
        targetVerse = verse;
        break;
      }
    }

    if (targetVerse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('journey_verse_unavailable'))),
      );
      return;
    }

    Navigator.pushNamed(context, '/verse', arguments: targetVerse);
  }
}

class _LabelText extends StatelessWidget {
  final String label;
  final String value;

  const _LabelText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
