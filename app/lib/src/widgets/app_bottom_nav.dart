import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../state/app_state.dart';

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
    final strings = AppStrings(appState.languageCode);

    return NavigationBar(
      selectedIndex: currentIndex,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        if (index == currentIndex) {
          return;
        }
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            break;
          case 1:
            Navigator.pushNamedAndRemoveUntil(
                context, '/verses', (route) => false);
            break;
          case 2:
            Navigator.pushNamedAndRemoveUntil(
                context, '/chat', (route) => false);
            break;
          case 3:
            Navigator.pushNamedAndRemoveUntil(
                context, '/collections', (route) => false);
            break;
        }
      },
      destinations: <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: _label(
            strings: strings,
            key: 'tab_today',
            fallback: 'Today',
          ),
        ),
        NavigationDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book_rounded),
          label: _label(
            strings: strings,
            key: 'tab_verses',
            fallback: 'Verses',
          ),
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(Icons.chat_bubble_rounded),
          label: _label(
            strings: strings,
            key: 'tab_chat',
            fallback: 'Chat',
          ),
        ),
        NavigationDestination(
          icon: const Icon(Icons.collections_bookmark_outlined),
          selectedIcon: const Icon(Icons.collections_bookmark_rounded),
          label: _label(
            strings: strings,
            key: 'tab_library',
            fallback: 'Library',
          ),
        ),
      ],
    );
  }
}
