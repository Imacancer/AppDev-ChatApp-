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
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _messageController = Provider.of<MessageController>(context, listen: false);
    // debugPrint("ChatScreen initialized, controller acquired");

    // Add a post-frame callback to initialize conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
  }

  Future<void> _initializeConversation() async {
    // Set current user from widget parameter
    _messageController.setCurrentUser(widget.currentUser);
    // debugPrint("Current user set in controller");

    // Initialize conversation with recipient ID
    await _messageController.initializeConversation(widget.chatUser.id);
    // debugPrint(
    //   "Conversation initialized, message count: ${_messageController.messages.length}",
    // );

    // Initialize WebRTC for real-time messaging
    await _messageController.initializeWebRTC();
    debugPrint("WebRTC initialized");
  }

  // Handles message sending and rendering
  void _handleSendMessage() async {
    final messageText = _messageController.textController.text;

    if (messageText.isNotEmpty || _messageController.selectedMedia != null) {
      // Unfocus the text field
      _messageFocusNode.unfocus();

      // Call sendMessage and await its completion
      await _messageController.sendMessage();

      // Add a small delay to ensure the UI has updated
      await Future.delayed(const Duration(milliseconds: 50));

      // Since the list is already reversed and new messages are at the top,
      // we need to scroll to position 0
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController
              .position
              .maxScrollExtent, // Scroll to the top where the newest message is
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
      body: GestureDetector(
        onTap: () {
          // Unfocuses text field upon clicking out
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: Consumer<MessageController>(
                builder: (context, controller, _) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Debug print to confirm consumer rebuild
                  // debugPrint(
                  //   "Consumer rebuilding, message count: ${controller.messages.length}",
                  // );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final message = controller.messages[index];
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
                  onSendPressed: _handleSendMessage, // Use the wrapper method
                  onAttachmentPressed: controller.pickMedia,
                  selectedMedia: controller.selectedMedia,
                  onClearMedia: controller.clearSelectedMedia,
                  focusNode: _messageFocusNode,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
