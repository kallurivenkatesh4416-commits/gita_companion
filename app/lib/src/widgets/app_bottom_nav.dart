import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../ui/shared/design_tokens.dart';

/// Bottom navigation bar with five tabs and a frosted-glass backdrop.
///
/// Tabs (by index):
///   0 → Today     (/)
///   1 → Verses    (/verses)
///   2 → Chat      (/chat)
///   3 → Library   (/collections)
///   4 → Panchang  (/panchang)
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  String _label({
    required AppStrings strings,
    required String key,
    required String fallback,
  }) {
    final value = strings.t(key);
    return value == key ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings  = AppStrings(appState.languageCode);

    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.blurNavBar,
            sigmaY: GlassTokens.blurNavBar,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:  Colors.white.withValues(alpha: GlassTokens.fillNavBar),
              border: const Border(
                top: BorderSide(
                  color: GlassTokens.borderLight,
                  width: GlassTokens.borderWidth,
                ),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: Theme.of(context)
                    .navigationBarTheme
                    .copyWith(
                      backgroundColor:  Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      shadowColor:      Colors.transparent,
                      elevation:        0,
                    ),
              ),
              child: NavigationBar(
                selectedIndex:    currentIndex,
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                backgroundColor: Colors.transparent,
                onDestinationSelected: (index) {
                  if (index == currentIndex) return;
                  switch (index) {
                    case 0:
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/', (route) => false);
                    case 1:
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/verses', (route) => false);
                    case 2:
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/chat', (route) => false);
                    case 3:
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/collections', (route) => false);
                    case 4:
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/panchang', (route) => false);
                  }
                },
                destinations: <NavigationDestination>[
                  NavigationDestination(
                    icon:         const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label:        _label(
                      strings:  strings,
                      key:      'tab_today',
                      fallback: 'Today',
                    ),
                  ),
                  NavigationDestination(
                    icon:         const Icon(Icons.menu_book_outlined),
                    selectedIcon: const Icon(Icons.menu_book_rounded),
                    label:        _label(
                      strings:  strings,
                      key:      'tab_verses',
                      fallback: 'Verses',
                    ),
                  ),
                  NavigationDestination(
                    icon:         const Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: const Icon(Icons.chat_bubble_rounded),
                    label:        _label(
                      strings:  strings,
                      key:      'tab_chat',
                      fallback: 'Chat',
                    ),
                  ),
                  NavigationDestination(
                    icon:         const Icon(Icons.collections_bookmark_outlined),
                    selectedIcon: const Icon(Icons.collections_bookmark_rounded),
                    label:        _label(
                      strings:  strings,
                      key:      'tab_library',
                      fallback: 'Library',
                    ),
                  ),
                  NavigationDestination(
                    icon:         const Icon(Icons.calendar_month_outlined),
                    selectedIcon: const Icon(Icons.calendar_month_rounded),
                    label:        _label(
                      strings:  strings,
                      key:      'tab_panchang',
                      fallback: 'Panchang',
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
