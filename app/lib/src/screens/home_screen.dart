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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
            children: <Widget>[
              _HeaderPanel(
                strings: strings,
                mode: appState.guidanceMode,
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: strings.t('daily_verse'),
                subtitle: strings.t('daily_verse_subtitle'),
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
              const SizedBox(height: 10),
              Text(
                strings.t('daily_verse_update_note'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                title: strings.t('morning_greeting'),
                subtitle: strings.t('morning_greeting_subtitle'),
                trailing: IconButton(
                  tooltip: appState.morningGreeting == null
                      ? strings.t('generate_morning_greeting')
                      : strings.t('regenerate_morning_greeting'),
                  onPressed: appState.morningGreetingLoading
                      ? null
                      : () => context
                          .read<AppState>()
                          .generateMorningGreeting(force: true),
                  icon: appState.morningGreetingLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ),
              const SizedBox(height: 10),
              if (appState.morningGreeting != null)
                _MorningGreetingCard(
                  greeting: appState.morningGreeting!,
                  strings: strings,
                  onVerseTap: appState.dailyVerse == null
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            '/verse',
                            arguments: appState.dailyVerse,
                          ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(strings.t('morning_greeting_empty')),
                  ),
                ),
              const SizedBox(height: 20),
              _SectionTitle(
                title: strings.t('companion_tools'),
                subtitle: strings.t('companion_tools_subtitle'),
              ),
              const SizedBox(height: 10),
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

  const _HeaderPanel({
    required this.strings,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              mode == 'comfort'
                  ? strings.t('comfort_mode')
                  : strings.t('clarity_mode'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.t('good_to_see_you'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
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
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          trailing!,
        ],
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

class _MorningGreetingCard extends StatefulWidget {
  final MorningGreeting greeting;
  final AppStrings strings;
  final VoidCallback? onVerseTap;

  const _MorningGreetingCard({
    required this.greeting,
    required this.strings,
    this.onVerseTap,
  });

  @override
  State<_MorningGreetingCard> createState() => _MorningGreetingCardState();
}

class _MorningGreetingCardState extends State<_MorningGreetingCard> {
  bool _expanded = false;

  String _previewText(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 160) {
      return normalized;
    }
    return '${normalized.substring(0, 160).trimRight()}...';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = widget.greeting;
    final strings = widget.strings;
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
                _expanded ? greeting.greeting : _previewText(greeting.greeting),
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF2A1A0A),
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    label: Text('Bhagavad Gita ${greeting.verse.ref}'),
                    onPressed: widget.onVerseTap,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(
                  _expanded ? strings.t('collapse') : strings.t('expand'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (_expanded) ...<Widget>[
                const SizedBox(height: 8),
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
