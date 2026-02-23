import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calendar/calendar_state.dart';
import '../calendar/festival.dart';
import '../ui/shared/design_tokens.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/spiritual_background.dart';

/// Full Hindu festival calendar screen (Panchang tab).
class PanchangScreen extends StatelessWidget {
  const PanchangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalendarState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panchang'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: _GoldOmIcon(),
          ),
        ],
      ),
      body: SpiritualBackground(
        child: state.all.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Hindu Festival Calendar — 2025 & 2026',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount:        state.all.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder:      (context, i) =>
                          _FestivalCard(festival: state.all[i]),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AppBottomNav(currentIndex: 4),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _GoldOmIcon extends StatelessWidget {
  const _GoldOmIcon();

  @override
  Widget build(BuildContext context) {
    return Text(
      'ॐ',
      style: TextStyle(
        fontSize:   22,
        color:      DesignColors.gold500,
        fontFamily: 'serif',
      ),
    );
  }
}

class _FestivalCard extends StatelessWidget {
  final Festival festival;
  const _FestivalCard({required this.festival});

  @override
  Widget build(BuildContext context) {
    final color    = festival.festivalColor;
    final daysLeft = festival.daysUntil;
    final isPast   = daysLeft < 0;
    final isToday  = festival.isToday;

    final borderColor = isPast
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.30);
    final bgColor = isPast
        ? Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45)
        : color.withValues(alpha: 0.07);

    return AnimatedContainer(
      duration: MotionTokens.medium,
      curve:    MotionTokens.standard,
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: borderColor, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Colour bar ────────────────────────────────────────────────────
          Container(
            width:  4,
            height: 56,
            decoration: BoxDecoration(
              color:        isPast ? Colors.grey.shade400 : color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // ── Date badge ────────────────────────────────────────────────────
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Text(
                  '${festival.date.day}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: isPast
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : color,
                        fontWeight: FontWeight.w700,
                        height:     1,
                      ),
                ),
                Text(
                  _monthAbbr(festival.date.month),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Name + significance ───────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        festival.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: isPast
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:        color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Today',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:      color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  festival.nameHi,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  festival.significance,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPast
                            ? Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
