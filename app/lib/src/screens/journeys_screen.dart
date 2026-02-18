import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class JourneysScreen extends StatefulWidget {
  const JourneysScreen({super.key});

  @override
  State<JourneysScreen> createState() => _JourneysScreenState();
}

class _JourneysScreenState extends State<JourneysScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    context.read<AppState>().refreshJourneys();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('journeys'))),
      body: SpiritualBackground(
        child: RefreshIndicator(
          onRefresh: () => appState.refreshJourneys(),
          child: appState.journeysLoading && appState.journeys.isEmpty
              ? const _JourneysSkeletonList()
              : appState.journeys.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: <Widget>[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: <Widget>[
                                Icon(
                                  Icons.route_rounded,
                                  size: 46,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  strings.t('journeys_empty'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  strings.t('empty_state_hint_journeys'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: appState.journeys.length,
                      itemBuilder: (context, index) {
                        final journey = appState.journeys[index];
                        return Card(
                          child: ListTile(
                            title: Text(journey.title),
                            subtitle: Text(journey.description),
                            trailing: Text('${journey.days} days'),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _JourneysSkeletonList extends StatelessWidget {
  const _JourneysSkeletonList();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.16);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      itemCount: 3,
      itemBuilder: (_, __) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 170,
                  height: 14,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
