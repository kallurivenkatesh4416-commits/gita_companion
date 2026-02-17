import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/verse_preview_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gita Companion'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => appState.refreshDailyVerse(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: <Widget>[
              _HeaderPanel(
                mode: appState.guidanceMode,
                identityLine: appState.privacyAnonymous
                    ? 'Private by default. Anonymous mode is active.'
                    : 'Signed in as ${appState.email ?? 'user'}',
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'Daily Verse',
                subtitle: 'A steady anchor for today',
              ),
              const SizedBox(height: 10),
              if (appState.dailyVerse != null)
                VersePreviewCard(
                  verse: appState.dailyVerse!,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/verse',
                    arguments: appState.dailyVerse,
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(appState.errorMessage ?? 'No daily verse loaded yet.'),
                  ),
                ),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'Companion Tools',
                subtitle: 'Choose where you want guidance today',
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: MediaQuery.of(context).size.width >= 760 ? 4 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _DashboardTile(
                    icon: Icons.spa_outlined,
                    title: 'Check-in',
                    subtitle: 'Mood + one-minute reset',
                    onTap: () => Navigator.pushNamed(context, '/mood'),
                  ),
                  _DashboardTile(
                    icon: Icons.psychology_alt_outlined,
                    title: 'Chatbot',
                    subtitle: 'Conversation with verse-grounded guidance',
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  _DashboardTile(
                    icon: Icons.favorite_outline,
                    title: 'Favorites',
                    subtitle: 'Saved verses for revisit',
                    onTap: () => Navigator.pushNamed(context, '/favorites'),
                  ),
                  _DashboardTile(
                    icon: Icons.route_outlined,
                    title: 'Journeys',
                    subtitle: 'Structured progress paths',
                    onTap: () => Navigator.pushNamed(context, '/journeys'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  final String mode;
  final String identityLine;

  const _HeaderPanel({required this.mode, required this.identityLine});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF5E3620), Color(0xFF8E5B36), Color(0xFFB77A4B)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  mode == 'comfort' ? 'Comfort Mode' : 'Clarity Mode',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Good to see you.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  height: 1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            identityLine,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 12),
          Text(
            'Stay with one clear intention for the next hour.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colorScheme.secondary),
              ),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
