import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SwitchListTile(
            title: const Text('Anonymous privacy mode'),
            subtitle: const Text('Store no identifying profile data locally.'),
            value: appState.privacyAnonymous,
            onChanged: (value) => context.read<AppState>().setPrivacyAnonymous(value),
          ),
          const Divider(),
          Text('Guidance mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'comfort', label: Text('Comfort')),
              ButtonSegment<String>(value: 'clarity', label: Text('Clarity')),
            ],
            selected: <String>{appState.guidanceMode},
            onSelectionChanged: (selection) {
              final selected = selection.first;
              context.read<AppState>().setGuidanceMode(selected);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () async {
              await context.read<AppState>().deleteLocalData();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            child: const Text('Delete Local Data'),
          ),
        ],
      ),
    );
  }
}
