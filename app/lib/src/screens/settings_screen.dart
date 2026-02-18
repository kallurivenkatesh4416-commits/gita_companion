import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/spiritual_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('settings'))),
      body: SpiritualBackground(
        animate: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _SectionHeader(title: strings.t('settings_section_practice')),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(strings.t('guidance_mode'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'comfort',
                          label: Text(strings.t('comfort_mode')),
                        ),
                        ButtonSegment<String>(
                          value: 'clarity',
                          label: Text(strings.t('clarity_mode')),
                        ),
                      ],
                      selected: <String>{appState.guidanceMode},
                      onSelectionChanged: (selection) {
                        final selected = selection.first;
                        context.read<AppState>().setGuidanceMode(selected);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(strings.t('language'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue:
                          languageOptionFromCode(appState.languageCode).code,
                      decoration: const InputDecoration(),
                      items: supportedAppLanguages
                          .map(
                            (language) => DropdownMenuItem<String>(
                              value: language.code,
                              child:
                                  Text('${language.nativeName} (${language.name})'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (selected) {
                        if (selected == null) {
                          return;
                        }
                        context.read<AppState>().setLanguageCode(selected);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.t('voice_input_setting')),
                      value: appState.voiceInputEnabled,
                      onChanged: (value) =>
                          context.read<AppState>().setVoiceInputEnabled(value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.t('voice_output_setting')),
                      value: appState.voiceOutputEnabled,
                      onChanged: (value) =>
                          context.read<AppState>().setVoiceOutputEnabled(value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _SectionHeader(title: strings.t('settings_section_privacy_data')),
            Card(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: Text(strings.t('privacy_mode')),
                    subtitle: Text(strings.t('privacy_mode_subtitle')),
                    value: appState.privacyAnonymous,
                    onChanged: (value) =>
                        context.read<AppState>().setPrivacyAnonymous(value),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () async {
                              await context.read<AppState>().clearChatHistory();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(strings.t('clear_chat_history')),
                                  ),
                                );
                              }
                            },
                            child: Text(strings.t('clear_chat_history')),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () async {
                              await context.read<AppState>().deleteLocalData();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                    context, '/', (route) => false);
                              }
                            },
                            child: Text(strings.t('delete_local_data')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionHeader(title: strings.t('settings_section_about')),
            Card(
              child: ListTile(
                title: Text(strings.t('app_title')),
                subtitle: const Text('v0.1.0'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AppBottomNav(currentIndex: 3),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}
