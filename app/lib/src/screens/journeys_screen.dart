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
          child: appState.journeys.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: <Widget>[
                    Text(strings.t('journeys_empty')),
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
