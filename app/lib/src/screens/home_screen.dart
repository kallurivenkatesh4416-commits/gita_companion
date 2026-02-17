import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';
import '../widgets/verse_preview_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('app_title')),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'divine-chat-fab',
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        icon: const Icon(Icons.auto_awesome),
        label: Text(strings.t('divine_chat')),
        backgroundColor: const Color(0xFFFFD8A8),
        foregroundColor: const Color(0xFF4A2A14),
      ),
      body: SpiritualBackground(
        child: RefreshIndicator(
          onRefresh: () => appState.refreshDailyVerse(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
            children: <Widget>[
              _HeaderPanel(
                strings: strings,
                mode: appState.guidanceMode,
                identityLine: appState.privacyAnonymous
                    ? strings.t('anonymous_active')
                    : '${strings.t('signed_in_as')} ${appState.email ?? 'user'}',
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: strings.t('daily_verse'),
                subtitle: strings.t('daily_verse_subtitle'),
              ),
              const SizedBox(height: 8),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          appState.dailyVerseError ??
                              strings.t('daily_verse_unavailable'),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              context.read<AppState>().refreshDailyVerse(),
                          icon: const Icon(Icons.refresh),
                          label: Text(strings.t('retry')),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                strings.t('daily_verse_update_note'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: strings.t('morning_greeting'),
                subtitle: strings.t('morning_greeting_subtitle'),
              ),
              const SizedBox(height: 8),
              if (appState.morningGreeting != null)
                _MorningGreetingCard(
                  greeting: appState.morningGreeting!,
                  strings: strings,
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(strings.t('morning_greeting_empty')),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: appState.morningGreetingLoading
                      ? null
                      : () => context
                          .read<AppState>()
                          .generateMorningGreeting(force: true),
                  icon: appState.morningGreetingLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wb_sunny_outlined),
                  label: Text(
                    appState.morningGreeting == null
                        ? strings.t('generate_morning_greeting')
                        : strings.t('regenerate_morning_greeting'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: strings.t('companion_tools'),
                subtitle: strings.t('companion_tools_subtitle'),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount:
                    MediaQuery.of(context).size.width >= 760 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _GlassTile(
                    icon: Icons.spa_outlined,
                    iconColor: const Color(0xFF4B5D43), // Sage green
                    title: strings.t('check_in'),
                    subtitle: strings.t('check_in_subtitle'),
                    onTap: () => Navigator.pushNamed(context, '/mood'),
                  ),
                  _GlassTile(
                    icon: Icons.favorite_outline,
                    iconColor: const Color(0xFFFF9933), // Saffron gold
                    title: strings.t('favorites'),
                    subtitle: strings.t('favorites_subtitle'),
                    onTap: () => Navigator.pushNamed(context, '/favorites'),
                  ),
                  _GlassTile(
                    icon: Icons.route_outlined,
                    iconColor: const Color(0xFF4B5D43), // Sage green
                    title: strings.t('journeys'),
                    subtitle: strings.t('journeys_subtitle'),
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

// ---------------------------------------------------------------------------
// Header Panel — Deep terracotta gradient + serif greeting
// ---------------------------------------------------------------------------

class _HeaderPanel extends StatelessWidget {
  final AppStrings strings;
  final String mode;
  final String identityLine;

  const _HeaderPanel({
    required this.strings,
    required this.mode,
    required this.identityLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF8E4A2F), // Deep Terracotta
            Color(0xFF5D2E1C), // Dark Earthy Brown
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF5D2E1C).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              mode == 'comfort'
                  ? strings.t('comfort_mode')
                  : strings.t('clarity_mode'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          // Serif greeting
          Text(
            strings.t('good_to_see_you'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            identityLine,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          Text(
            strings.t('stay_intention'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Title
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Glassmorphic Tile with scale-on-tap effect
// ---------------------------------------------------------------------------

class _GlassTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GlassTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_GlassTile> createState() => _GlassTileState();
}

class _GlassTileState extends State<_GlassTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _MorningGreetingCard extends StatelessWidget {
  final MorningGreeting greeting;
  final AppStrings strings;

  const _MorningGreetingCard({
    required this.greeting,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final palette = greeting.background.palette;
    final first = palette.isNotEmpty
        ? _colorFromHex(palette.first)
        : const Color(0xFFF6D08D);
    final second = palette.length > 1
        ? _colorFromHex(palette[1])
        : const Color(0xFFD98F4E);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[first, second],
        ),
      ),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting.greeting,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF2A1A0A),
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bhagavad Gita ${greeting.verse.ref}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2A1A0A),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                greeting.verse.translation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF3A2A1A),
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '${strings.t('morning_affirmation')}: ${greeting.affirmation}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2F241A),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${strings.t('background_theme')}: ${greeting.background.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2F241A),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFromHex(String value) {
    final hex = value.replaceAll('#', '').trim();
    if (hex.length != 6) {
      return const Color(0xFFF6D08D);
    }
    return Color(int.parse('FF$hex', radix: 16));
  }
}
