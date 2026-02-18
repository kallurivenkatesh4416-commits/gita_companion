import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../services/share_card_service.dart';
import '../state/app_state.dart';
import '../utils/ui_text_utils.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/hero_verse_card.dart';
import '../widgets/spiritual_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final friendlyVerseError = appState.dailyVerseError == null
        ? null
        : mapFriendlyError(
            appState.dailyVerseError!,
            strings: strings,
            context: 'verses',
          );

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: isDark
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
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
      body: SpiritualBackground(
        animate: true,
        enableParallax: true,
        parallaxController: _scrollController,
        child: RefreshIndicator(
          onRefresh: () => appState.refreshDailyVerse(),
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: -16),
                child: _HeaderPanelMask(
                  child: _HeaderPanel(
                    strings: strings,
                    mode: appState.guidanceMode,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SectionTitle(
                title: strings.t('daily_verse'),
                subtitle: strings.t('daily_verse_primary_subtitle'),
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              if (appState.dailyVerse != null)
                _DailyVerseFocus(
                  child: HeroVerseCard(
                    verse: appState.dailyVerse!,
                    isSaved: appState.isFavorite(appState.dailyVerse!.id),
                    saveLabel: strings.t('bookmark'),
                    shareLabel: strings.t('share'),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/verse',
                      arguments: appState.dailyVerse,
                    ),
                    onShare: () => ShareCardService.shareVerseCard(
                      context,
                      appState.dailyVerse!,
                    ),
                    onToggleSaved: () => context
                        .read<AppState>()
                        .toggleFavorite(appState.dailyVerse!),
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
                          friendlyVerseError ?? strings.t('daily_verse_unavailable'),
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/ritual'),
                  icon: const Icon(Icons.self_improvement_outlined),
                  label: Text(strings.t('start_today_60_sec')),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${strings.t('sadhana_streak')}: ${appState.ritualStreakDays} days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (appState.ritualCompletedToday) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      strings.t('done_today'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
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
              const SizedBox(height: 24),
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
                  _GlassTile(
                    icon: Icons.menu_book_outlined,
                    iconColor: const Color(0xFFFF9933), // Saffron gold
                    title: strings.t('browse_chapters'),
                    subtitle: strings.t('verses_browser'),
                    onTap: () => Navigator.pushNamed(context, '/verses'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AppBottomNav(currentIndex: 0),
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
    final todayLine = _todayLine(context);

    return Container(
      padding: const EdgeInsets.all(14),
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
            color: const Color(0xFF5D2E1C).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${strings.t('today')}: $todayLine',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontWeight: FontWeight.w600,
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

  String _todayLine(BuildContext context) {
    final now = DateTime.now();
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final weekdayByLang = <String, List<String>>{
      'en': <String>[
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ],
      'hi': <String>[
        'सोमवार',
        'मंगलवार',
        'बुधवार',
        'गुरुवार',
        'शुक्रवार',
        'शनिवार',
        'रविवार',
      ],
      'te': <String>[
        'సోమవారం',
        'మంగళవారం',
        'బుధవారం',
        'గురువారం',
        'శుక్రవారం',
        'శనివారం',
        'ఆదివారం',
      ],
      'ta': <String>[
        'திங்கள்',
        'செவ்வாய்',
        'புதன்',
        'வியாழன்',
        'வெள்ளி',
        'சனி',
        'ஞாயிறு',
      ],
      'kn': <String>[
        'ಸೋಮವಾರ',
        'ಮಂಗಳವಾರ',
        'ಬುಧವಾರ',
        'ಗುರುವಾರ',
        'ಶುಕ್ರವಾರ',
        'ಶನಿವಾರ',
        'ಭಾನುವಾರ',
      ],
      'ml': <String>[
        'തിങ്കള്‍',
        'ചൊവ്വ',
        'ബുധന്‍',
        'വ്യാഴം',
        'വെള്ളി',
        'ശനി',
        'ഞായര്‍',
      ],
      'es': <String>[
        'lunes',
        'martes',
        'miercoles',
        'jueves',
        'viernes',
        'sabado',
        'domingo',
      ],
    };

    final localeCode = Localizations.localeOf(context).languageCode;
    final dayNames = weekdayByLang[localeCode] ?? weekdayByLang['en']!;
    final dayName = dayNames[now.weekday - 1];
    return '${now.day} ${months[now.month - 1]} • $dayName';
  }
}

class _HeaderPanelMask extends StatelessWidget {
  final Widget child;

  const _HeaderPanelMask({required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: <double>[0, 0.8, 1],
        ).createShader(bounds);
      },
      child: child,
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
  final bool isPrimary;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isPrimary = false,
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
                style: (isPrimary
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
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

class _DailyVerseFocus extends StatefulWidget {
  final Widget child;

  const _DailyVerseFocus({required this.child});

  @override
  State<_DailyVerseFocus> createState() => _DailyVerseFocusState();
}

class _DailyVerseFocusState extends State<_DailyVerseFocus> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        child: widget.child,
      ),
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
  Alignment _highlightAlignment = const Alignment(-0.45, -0.8);
  bool _highlightVisible = false;

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

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
    if (details.globalPosition != Offset.zero) {
      _updateHighlight(details.globalPosition, visible: true);
    }
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    HapticFeedback.lightImpact();
    setState(() => _highlightVisible = false);
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
    setState(() => _highlightVisible = false);
  }

  void _updateHighlight(Offset globalPosition, {required bool visible}) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) {
      return;
    }
    final local = box.globalToLocal(globalPosition);
    final dx = ((local.dx / box.size.width) * 2 - 1).clamp(-1.0, 1.0);
    final dy = ((local.dy / box.size.height) * 2 - 1).clamp(-1.0, 1.0);
    setState(() {
      _highlightAlignment = Alignment(dx, dy);
      _highlightVisible = visible;
    });
  }

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
      child: MouseRegion(
        onHover: (event) => _updateHighlight(event.position, visible: true),
        onExit: (_) => setState(() => _highlightVisible = false),
        child: Listener(
          onPointerDown: (event) => _updateHighlight(event.position, visible: true),
          onPointerMove: (event) => _updateHighlight(event.position, visible: true),
          onPointerHover: (event) => _updateHighlight(event.position, visible: true),
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.34),
                    Colors.white.withValues(alpha: 0.12),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: widget.iconColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: widget.iconColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: widget.iconColor,
                                    size: 20,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  widget.title,
                                  style:
                                      Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color:
                                                Theme.of(context).colorScheme.onSurface,
                                          ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _highlightVisible ? 1 : 0.35,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: _highlightAlignment,
                                    radius: 0.75,
                                    colors: <Color>[
                                      Colors.white.withValues(alpha: 0.2),
                                      Colors.white.withValues(alpha: 0.06),
                                      Colors.transparent,
                                    ],
                                    stops: const <double>[0.0, 0.42, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  final VoidCallback? onVerseTap;

  const _MorningGreetingCard({
    required this.greeting,
    required this.strings,
    this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = this.greeting;
    final strings = this.strings;
    final palette = greeting.background.palette;
    final first = palette.isNotEmpty
        ? _colorFromHex(palette.first)
        : const Color(0xFFF6D08D);
    final second = palette.length > 1
        ? _colorFromHex(palette[1])
        : const Color(0xFFD98F4E);
    final cleanGreeting = sanitizeAiText(greeting.greeting);
    final uplifting = firstGentleLine(greeting.meaning);
    final sankalpa = sanitizeAiText(greeting.affirmation);

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
                  cleanGreeting.isEmpty ? strings.t('stay_intention') : cleanGreeting,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2A1A0A),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  uplifting.isEmpty ? strings.t('stay_intention') : uplifting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2F241A).withValues(alpha: 0.86),
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${strings.t('todays_sankalpa')}: "
                    "${sankalpa.isEmpty ? strings.t('stay_intention') : sankalpa}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF2A1A0A),
                        ),
                  ),
                ),
                const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    label: Text('Bhagavad Gita ${greeting.verse.ref}'),
                    onPressed: onVerseTap,
                  ),
                ],
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
