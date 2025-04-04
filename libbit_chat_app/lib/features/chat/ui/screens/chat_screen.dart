import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/chat/ui/widgets/message_bubble_widget.dart';
import 'package:libbit_chat_app/features/chat/ui/widgets/message_input_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(),
            SizedBox(width: 16),
            Text(
              'Hoshimachi Suisei',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView(
                children: [
                  MessageBubbleWidget(message: "Sample Message"),
                  MessageBubbleWidget(message: "Sample Message", isMe: false),
                ],
              ),
            ),
          ),
          MessageInputWidget(),
        ],
      ),
    );
  }
}
