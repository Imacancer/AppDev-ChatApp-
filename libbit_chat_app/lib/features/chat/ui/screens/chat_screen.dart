import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/chat/controllers/message_controller.dart';
import 'package:libbit_chat_app/features/chat/models/chat_user_model.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';
import 'package:libbit_chat_app/features/chat/ui/widgets/message_bubble_widget.dart';
import 'package:libbit_chat_app/features/chat/ui/widgets/message_input_widget.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';
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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late MessageController _messageController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = Provider.of<MessageController>(context, listen: false);

    // Initialize the conversation after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access the MessageController using Provider for real-time updates
    _messageController = Provider.of<MessageController>(context, listen: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to manage socket connections
    if (state == AppLifecycleState.resumed) {
      // Rejoin the chat room when app comes back to foreground
      if (_messageController.currentUser != null &&
          _messageController.recipient != null) {
        // The socket service will handle reconnection if needed
        debugPrint("App resumed, ensuring socket connection is active");
      }
    }
  }

  Future<void> _initializeConversation() async {
    // Set current user from widget parameter
    _messageController.setCurrentUser(widget.currentUser);

    // Initialize conversation with recipient ID
    await _messageController.initializeConversation(widget.chatUser.id);

    // Scroll to bottom after messages are loaded
    _scrollToBottomAfterLoad();
  }

  void _scrollToBottomAfterLoad() {
    // Small delay to ensure messages are loaded
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Scroll to bottom when new messages arrive
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Handles message sending and rendering
  Future<void> _handleSendMessage() async {
    final messageText = _messageController.textController.text;

    if (messageText.isEmpty && _messageController.selectedMedia == null) {
      return; // Don't send empty messages
    }

    // Unfocus the text field
    _messageFocusNode.unfocus();

    // Call sendMessage and await its completion
    await _messageController.sendMessage();

    // Check if message was blocked
    if (_messageController.messageBlocked) {
      // Show snackbar with blocked message info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _messageController.blockedMessageInfo ??
                  'Message blocked due to unsafe content',
            ),
            backgroundColor: ColorConstants.supportError,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        // Clear the blocked message status
        _messageController.clearBlockedMessageStatus();
      }
    } else {
      // Add a small delay to ensure the UI has updated
      await Future.delayed(const Duration(milliseconds: 50));
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _messageFocusNode.dispose();
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
      body: SafeArea(
        child: GestureDetector(
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
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      );
                    }

                    final messages = controller.messages;

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet. Start a conversation!',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }

                    // When messages list changes, scroll to bottom
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (messages.isNotEmpty && _scrollController.hasClients) {
                        _scrollToBottom();
                      }
                    });

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe =
                              message.senderId == widget.currentUser.userId;

                          // Determine if the message has flagged URLs
                          final hasFlaggedUrls =
                              message.flaggedUrls != null &&
                              message.flaggedUrls!.isNotEmpty;

                          return MessageBubbleWidget(
                            message: message.message,
                            isMe: isMe,
                            timestamp: message.timestamp,
                            isMedia: message.isMedia ?? false,
                            isBlocked: hasFlaggedUrls,
                            flaggedUrls: message.flaggedUrls,
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
                    onSendPressed: _handleSendMessage,
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
      ),
    );
  }
}
