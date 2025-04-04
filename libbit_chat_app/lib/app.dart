import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/authentication/ui/screens/authentication_screen.dart';
import 'package:libbit_chat_app/utils/theme/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Libbit Link',
      theme: CustomAppTheme.lightTheme,
      home: const AuthenticationScreen(),
    );
  }
}
