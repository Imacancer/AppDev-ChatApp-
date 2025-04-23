import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/chat/controllers/message_controller.dart';
import 'package:libbit_chat_app/features/chat/models/chat_user_model.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';
import 'package:libbit_chat_app/features/chat/ui/widgets/message_bubble_widget.dart';
import 'package:libbit_chat_app/features/chat/ui/widgets/message_input_widget.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser chatUser;
  final User currentUser;

  const ChatScreen({
    super.key,
    required this.chatUser,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late MessageController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = Provider.of<MessageController>(context, listen: false);

    // Add a post-frame callback to initialize conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
  }

  Future<void> _initializeConversation() async {
    // Set current user from widget parameter
    _messageController.setCurrentUser(widget.currentUser);

    // Initialize conversation with recipient ID
    await _messageController.initializeConversation(widget.chatUser.id);

    // Initialize WebRTC for real-time messaging
    await _messageController.initializeWebRTC();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.chatUser.avatar.startsWith('assets/')
                      ? AssetImage(widget.chatUser.avatar)
                      : NetworkImage(widget.chatUser.avatar) as ImageProvider,
            ),
            const SizedBox(width: 16),
            Text(
              widget.chatUser.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageController>(
              builder: (context, controller, _) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.builder(
                    reverse: true, // Most recent messages at the bottom
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message =
                          controller.messages[controller.messages.length -
                              1 -
                              index];
                      final isMe =
                          message.senderId == widget.currentUser.userId;

                      return MessageBubbleWidget(
                        message: message.message,
                        isMe: isMe,
                        timestamp: message.timestamp,
                        isMedia: message.isMedia ?? false,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Consumer<MessageController>(
            builder: (context, controller, _) {
              return MessageInputWidget(
                controller: controller.textController,
                onSendPressed: controller.sendMessage,
                onAttachmentPressed: controller.pickMedia,
                selectedMedia: controller.selectedMedia,
                onClearMedia: controller.clearSelectedMedia,
              );
            },
          ),
        ],
      ),
    );
  }
}
