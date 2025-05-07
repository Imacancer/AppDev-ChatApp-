import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/account_management/ui/screens/account_management_screen.dart';
import 'package:libbit_chat_app/features/chat/ui/screens/chat_list_screen.dart';
import 'package:libbit_chat_app/navigation/ui/widgets/custom_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:libbit_chat_app/features/chat/controllers/chat_list_controller.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentScreenIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the ChatListController when navigation is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatListController>(context, listen: false).initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentScreenIndex,
        children: const [ChatListScreen(), AccountManagementScreen()],
      ),
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
