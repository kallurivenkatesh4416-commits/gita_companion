import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final customTime = TimeOfDay(
      hour: appState.verseNotificationCustomHour,
      minute: appState.verseNotificationCustomMinute,
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('settings'))),
      body: SpiritualBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SwitchListTile(
              title: Text(strings.t('privacy_mode')),
              subtitle: Text(strings.t('privacy_mode_subtitle')),
              value: appState.privacyAnonymous,
              onChanged: (value) =>
                  context.read<AppState>().setPrivacyAnonymous(value),
            ),
            const Divider(),
            Text(strings.t('guidance_mode'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                    value: 'comfort', label: Text(strings.t('comfort_mode'))),
                ButtonSegment<String>(
                    value: 'clarity', label: Text(strings.t('clarity_mode'))),
                ButtonSegment<String>(
                    value: 'traditional',
                    label: Text(strings.t('traditional_mode'))),
              ],
              selected: <String>{appState.guidanceMode},
              onSelectionChanged: (selection) {
                final selected = selection.first;
                context.read<AppState>().setGuidanceMode(selected);
              },
            ),
            const SizedBox(height: 20),
            Text(strings.t('language'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: languageOptionFromCode(appState.languageCode).code,
              decoration: const InputDecoration(),
              items: supportedAppLanguages
                  .map(
                    (language) => DropdownMenuItem<String>(
                      value: language.code,
                      child: Text('${language.nativeName} (${language.name})'),
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
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(strings.t('voice_input_setting')),
              value: appState.voiceInputEnabled,
              onChanged: (value) =>
                  context.read<AppState>().setVoiceInputEnabled(value),
            ),
            SwitchListTile(
              title: Text(strings.t('voice_output_setting')),
              value: appState.voiceOutputEnabled,
              onChanged: (value) =>
                  context.read<AppState>().setVoiceOutputEnabled(value),
            ),
            const Divider(),
            Text(strings.t('notification_section_title'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(strings.t('notification_opt_in_title')),
              subtitle: Text(strings.t('notification_opt_in_subtitle')),
              value: appState.verseNotificationsEnabled,
              onChanged: (value) async {
                final enabled = await context
                    .read<AppState>()
                    .setVerseNotificationsEnabled(value);
                if (!context.mounted) {
                  return;
                }
                if (value && !enabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            strings.t('notification_permission_denied'))),
                  );
                }
              },
            ),
            if (appState.verseNotificationsEnabled) ...<Widget>[
              SwitchListTile(
                title: Text(strings.t('notification_pause_title')),
                subtitle: Text(strings.t('notification_pause_subtitle')),
                value: appState.verseNotificationsPaused,
                onChanged: (value) =>
                    context.read<AppState>().setVerseNotificationsPaused(value),
              ),
              const SizedBox(height: 8),
              Text(strings.t('notification_time_window'),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: AppState.notificationWindowMorning,
                    label: Text(strings.t('notification_morning')),
                  ),
                  ButtonSegment<String>(
                    value: AppState.notificationWindowEvening,
                    label: Text(strings.t('notification_evening')),
                  ),
                  ButtonSegment<String>(
                    value: AppState.notificationWindowCustom,
                    label: Text(strings.t('notification_custom_time')),
                  ),
                ],
                selected: <String>{appState.verseNotificationWindow},
                onSelectionChanged: (selection) {
                  context
                      .read<AppState>()
                      .setVerseNotificationWindow(selection.first);
                },
              ),
              if (appState.verseNotificationWindow ==
                  AppState.notificationWindowCustom) ...<Widget>[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${strings.t('notification_pick_time')}: ${customTime.format(context)}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: customTime,
                        helpText: strings.t('notification_pick_time'),
                      );
                      if (picked == null || !context.mounted) {
                        return;
                      }
                      await context.read<AppState>().setVerseNotificationCustomTime(
                            hour: picked.hour,
                            minute: picked.minute,
                          );
                    },
                    child: Text(strings.t('notification_pick_time')),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () async {
                await context.read<AppState>().clearChatHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.t('clear_chat_history'))),
                  );
                }
              },
              child: Text(strings.t('clear_chat_history')),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () async {
                await context.read<AppState>().deleteLocalData();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                }
              },
              child: Text(strings.t('delete_local_data')),
            ),
          ],
        ),
      ),
    );
  }
}
