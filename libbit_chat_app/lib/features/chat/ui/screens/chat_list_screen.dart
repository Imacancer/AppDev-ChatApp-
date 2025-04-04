import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/chat/ui/widgets/custom_card_widget.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView(children: [CustomCardWidget()]);
  }
}
