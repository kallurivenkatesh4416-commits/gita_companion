import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../calendar/calendar_state.dart';
import '../../calendar/festival.dart';
import '../shared/design_tokens.dart';

/// Horizontal scrolling strip of upcoming festival chips.
///
/// Placed on the home screen between the header panel and the daily verse.
/// Tapping a chip (or "See all") navigates to /panchang.
class FestivalStrip extends StatelessWidget {
  const FestivalStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalendarState>();
    if (state.upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Row(
            children: [
              Text(
                'Upcoming Festivals',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, '/panchang'),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection:   Axis.horizontal,
            clipBehavior:      Clip.none,
            itemCount:         state.upcoming.length,
            separatorBuilder:  (_, __) => const SizedBox(width: 10),
            itemBuilder:       (context, i) =>
                _FestivalChip(festival: state.upcoming[i]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FestivalChip extends StatelessWidget {
  final Festival festival;
  const _FestivalChip({required this.festival});

  String _daysLabel() {
    final d = festival.daysUntil;
    if (d == 0) return 'Today!';
    if (d == 1) return 'Tomorrow';
    return '$d days';
  }

  @override
  Widget build(BuildContext context) {
    final color     = festival.festivalColor;
    final daysLabel = _daysLabel();

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/panchang'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassTokens.blurFestival,
              sigmaY: GlassTokens.blurFestival,
            ),
            child: Container(
              width:   122,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: GlassTokens.fillFestival),
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: GlassTokens.borderWidth,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Days badge ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:        color.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      daysLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:      color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── Festival name ───────────────────────────────────────────
                  Text(
                    festival.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // ── Devanagari name ─────────────────────────────────────────
                  Text(
                    festival.nameHi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:    Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
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
