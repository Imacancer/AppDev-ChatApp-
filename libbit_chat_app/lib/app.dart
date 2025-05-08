import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/account_management/controllers/account_controller.dart';
import 'package:libbit_chat_app/features/authentication/ui/screens/authentication_screen.dart';
import 'package:libbit_chat_app/features/chat/controllers/chat_list_controller.dart';
import 'package:libbit_chat_app/features/chat/controllers/message_controller.dart';
import 'package:libbit_chat_app/utils/theme/theme.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global providers that will be available throughout the app
        ChangeNotifierProvider(create: (_) => MessageController()),
        ChangeNotifierProvider(create: (_) => ChatListController()),
        ChangeNotifierProvider(create: (_) => AccountController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Libbit Link',
        theme: CustomAppTheme.lightTheme,
        home: const AuthenticationScreen(),
      ),
    );
  }
}
