import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../errors/app_error_mapper.dart';
import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _emailController = TextEditingController();
  int _step = 0;
  bool _saving = false;
  String? _error;
  bool _initializedSelections = false;
  late String _selectedLanguage;
  late String _selectedGuidanceMode;
  late bool _notificationsEnabled;
  late String _notificationWindow;
  TimeOfDay _notificationCustomTime =
      const TimeOfDay(hour: 7, minute: 30);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _initializeSelections(AppState appState) {
    if (_initializedSelections) {
      return;
    }
    _initializedSelections = true;
    _selectedLanguage = appState.languageCode;
    _selectedGuidanceMode = guidanceModeFromCode(appState.guidanceMode);
    _notificationsEnabled = appState.verseNotificationsEnabled;
    _notificationWindow = appState.verseNotificationWindow;
    _notificationCustomTime = TimeOfDay(
      hour: appState.verseNotificationCustomHour,
      minute: appState.verseNotificationCustomMinute,
    );
  }

  Future<void> _savePreferencesAndContinue(AppState appState) async {
    final strings = AppStrings(_selectedLanguage);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final notificationEnabled = await appState.setOnboardingPreferences(
        mode: _selectedGuidanceMode,
        language: _selectedLanguage,
        notificationsEnabled: _notificationsEnabled,
        notificationWindow: _notificationWindow,
        notificationCustomHour: _notificationCustomTime.hour,
        notificationCustomMinute: _notificationCustomTime.minute,
      );
      if (_notificationsEnabled && !notificationEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('notification_permission_denied'))),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() => _step = 1);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(
        () => _error = AppErrorMapper.toUserMessage(
          error,
          strings,
          stackTrace: stackTrace,
          context: 'OnboardingScreen.savePreferences',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickNotificationTime(AppStrings strings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationCustomTime,
      helpText: strings.t('notification_pick_time'),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _notificationCustomTime = picked);
  }

  Future<void> _continueAnonymous() async {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await appState.completeOnboardingAnonymous();
    } catch (error, stackTrace) {
      setState(
        () => _error = AppErrorMapper.toUserMessage(
          error,
          strings,
          stackTrace: stackTrace,
          context: 'OnboardingScreen.continueAnonymous',
        ),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _continueWithEmail() async {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = strings.t('invalid_email'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await appState.completeOnboardingWithEmail(email);
    } catch (error, stackTrace) {
      setState(
        () => _error = AppErrorMapper.toUserMessage(
          error,
          strings,
          stackTrace: stackTrace,
          context: 'OnboardingScreen.continueWithEmail',
        ),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    _initializeSelections(appState);
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings(_selectedLanguage);

    return Scaffold(
      body: SpiritualBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF4F2E1E), Color(0xFF896347)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.17),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            strings.t('onboarding_tag'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.t('onboarding_title'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                height: 0.95,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.t('onboarding_subtitle'),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_step == 0)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(strings.t('onboarding_preferences_title'),
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(
                              strings.t('onboarding_preferences_subtitle'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            Text(strings.t('language'),
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedLanguage,
                              items: supportedAppLanguages
                                  .map(
                                    (language) => DropdownMenuItem<String>(
                                      value: language.code,
                                      child: Text(
                                          '${language.nativeName} (${language.name})'),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: _saving
                                  ? null
                                  : (selected) {
                                      if (selected == null) {
                                        return;
                                      }
                                      setState(
                                          () => _selectedLanguage = selected);
                                    },
                            ),
                            const SizedBox(height: 14),
                            Text(strings.t('guidance_mode'),
                                style: Theme.of(context).textTheme.titleSmall),
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
                                ButtonSegment<String>(
                                  value: 'traditional',
                                  label: Text(strings.t('traditional_mode')),
                                ),
                              ],
                              selected: <String>{_selectedGuidanceMode},
                              onSelectionChanged: _saving
                                  ? null
                                  : (selection) {
                                      setState(() {
                                        _selectedGuidanceMode = selection.first;
                                      });
                                    },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings.t('onboarding_notifications_title'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.t('onboarding_notifications_subtitle'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(strings.t('notification_opt_in_title')),
                              subtitle:
                                  Text(strings.t('notification_opt_in_subtitle')),
                              value: _notificationsEnabled,
                              onChanged: _saving
                                  ? null
                                  : (value) => setState(
                                      () => _notificationsEnabled = value),
                            ),
                            if (_notificationsEnabled) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                strings.t('notification_time_window'),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<String>(
                                segments: <ButtonSegment<String>>[
                                  ButtonSegment<String>(
                                    value: AppState.notificationWindowMorning,
                                    label:
                                        Text(strings.t('notification_morning')),
                                  ),
                                  ButtonSegment<String>(
                                    value: AppState.notificationWindowEvening,
                                    label:
                                        Text(strings.t('notification_evening')),
                                  ),
                                  ButtonSegment<String>(
                                    value: AppState.notificationWindowCustom,
                                    label: Text(
                                        strings.t('notification_custom_time')),
                                  ),
                                ],
                                selected: <String>{_notificationWindow},
                                onSelectionChanged: _saving
                                    ? null
                                    : (selection) => setState(
                                          () => _notificationWindow =
                                              selection.first,
                                        ),
                              ),
                              if (_notificationWindow ==
                                  AppState.notificationWindowCustom) ...<Widget>[
                                const SizedBox(height: 8),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${strings.t('notification_pick_time')}: ${_notificationCustomTime.format(context)}',
                                  ),
                                  trailing: TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () => _pickNotificationTime(strings),
                                    child:
                                        Text(strings.t('notification_pick_time')),
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: _saving
                                  ? null
                                  : () => _savePreferencesAndContinue(appState),
                              child: Text(strings.t('onboarding_continue')),
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
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _step = 0),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text(strings.t('onboarding_back')),
                            ),
                            const SizedBox(height: 4),
                            Text(strings.t('start_private'),
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(
                              strings.t('email_optional'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: strings.t('email_label'),
                                hintText: strings.t('email_hint'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _saving ? null : _continueWithEmail,
                              child: Text(strings.t('continue_email')),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _saving ? null : _continueAnonymous,
                              child: Text(strings.t('continue_anonymous')),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
