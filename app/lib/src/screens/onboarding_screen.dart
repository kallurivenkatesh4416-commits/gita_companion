import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continueAnonymous() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<AppState>().completeOnboardingAnonymous();
    } catch (error) {
      setState(() => _error = error.toString());
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
      await context.read<AppState>().completeOnboardingWithEmail(email);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings(appState.languageCode);

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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
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
