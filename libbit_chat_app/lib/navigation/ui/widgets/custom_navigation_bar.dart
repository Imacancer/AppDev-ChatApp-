import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:libbit_chat_app/utils/theme/custom_theme/custom_navbar_theme.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentScreenIndex;
  final ValueChanged<int> onDestinationSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentScreenIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: CustomNavbarTheme.lightCustomNavBarTheme,
      child: NavigationBar(
        selectedIndex: currentScreenIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.chat_bubble_fill),
            selectedIcon: Icon(CupertinoIcons.chat_bubble_fill),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.person_2_fill),
            selectedIcon: Icon(CupertinoIcons.person_2_fill),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.ellipsis),
            selectedIcon: Icon(CupertinoIcons.ellipsis),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
