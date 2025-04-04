import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/chat/ui/screens/chat_list_screen.dart';
import 'package:libbit_chat_app/navigation/ui/widgets/custom_navigation_bar.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentScreenIndex = 0;

  final List<Widget> screens = [const ChatListScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('libbit link'),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(CupertinoIcons.create_solid)),
        ],
      ),
      body: screens[currentScreenIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentScreenIndex: currentScreenIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentScreenIndex = index;
          });
        },
      ),
    );
  }
}
