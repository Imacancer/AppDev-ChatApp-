import 'dart:math';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messageController = Provider.of<MessageController>(context, listen: false);
    debugPrint("ChatScreen initialized, controller acquired");

    // Add a post-frame callback to initialize conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
  }

  Future<void> _initializeConversation() async {
    // Set current user from widget parameter
    _messageController.setCurrentUser(widget.currentUser);
    debugPrint("Current user set in controller");

    // Initialize conversation with recipient ID
    await _messageController.initializeConversation(widget.chatUser.id);
    debugPrint(
      "Conversation initialized, message count: ${_messageController.messages.length}",
    );

    // Initialize WebRTC for real-time messaging
    await _messageController.initializeWebRTC();
    debugPrint("WebRTC initialized");
  }

  void _handleSendMessage() {
    final messageText = _messageController.textController.text;

    if (messageText.isNotEmpty || _messageController.selectedMedia != null) {
      // Call sendMessage and then scroll immediately after
      _messageController.sendMessage(messageText);

      // Scroll to show the new message
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // Debug print to confirm method was called
      debugPrint("Message sent and scroll attempted");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

                // Debug print to confirm consumer rebuild
                debugPrint(
                  "Consumer rebuilding, message count: ${controller.messages.length}",
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      // When using reverse: true, use the direct index
                      final message = controller.messages[index];
                      final isMe =
                          message.senderId == widget.currentUser.userId;

                      // Debug print for each message being rendered
                      debugPrint(
                        "Rendering message at index $index: ${message.message.substring(0, min(20, message.message.length))}...",
                      );

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
                onSendPressed: _handleSendMessage, // Use the wrapper method
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
