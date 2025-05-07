import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libbit_chat_app/features/chat/models/chat_user_model.dart';
import 'package:libbit_chat_app/features/chat/models/message_model.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';
import 'package:libbit_chat_app/features/chat/services/chat_service.dart';
import 'package:libbit_chat_app/core/services/socket_service.dart';

class ChatListController extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();

  // State variables
  User? currentUser;
  bool isLoading = true;
  List<ChatUser> chatUsers = [];
  User? selectedUserDetails;

  // Search functionality
  String searchQuery = '';
  List<User> searchResults = [];

  ChatListController() {
    _setupSocketListeners();
    initializeData();
  }

  void _setupSocketListeners() {
    // Set up socket message callback for updating chat list
    _socketService.setOnNewMessageCallback(_handleNewSocketMessage);

    // Set up profile update callback
    _socketService.setOnProfileUpdateCallback(_handleProfileUpdate);
  }

  void _handleNewSocketMessage(Message message) {
    debugPrint('Received message in ChatListController: ${message.toJson()}');

    // If the current user is the recipient, update the chat list
    if (currentUser != null && message.recipientId == currentUser!.userId) {
      _updateChatWithNewMessage(message);
    }
    // If the current user is the sender, also update chat list
    else if (currentUser != null && message.senderId == currentUser!.userId) {
      _updateSentMessage(message);
    }
  }

  void _handleProfileUpdate(User updatedUser) {
    // Update the chat user if it exists in our list
    for (int i = 0; i < chatUsers.length; i++) {
      if (chatUsers[i].id == updatedUser.userId) {
        final updatedChatUser = ChatUser(
          id: chatUsers[i].id,
          name: updatedUser.name,
          avatar:
              updatedUser.profilePicture ?? 'assets/images/default_avatar.png',
          lastMessage: chatUsers[i].lastMessage,
          lastMessageId: chatUsers[i].lastMessageId,
          timestamp: chatUsers[i].timestamp,
          unreadCount: chatUsers[i].unreadCount,
          viewed: chatUsers[i].viewed,
          lastMessageSenderName: chatUsers[i].lastMessageSenderName,
        );

        chatUsers[i] = updatedChatUser;
        notifyListeners();
        break;
      }
    }

    // If this is the selected user, update it
    if (selectedUserDetails != null &&
        selectedUserDetails!.userId == updatedUser.userId) {
      selectedUserDetails = updatedUser;
      notifyListeners();
    }
  }

  void _updateChatWithNewMessage(Message message) {
    final senderId = message.senderId;

    // Find if we already have a chat with this sender
    int existingIndex = -1;

    for (int i = 0; i < chatUsers.length; i++) {
      if (chatUsers[i].id == senderId) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex >= 0) {
      // Update existing chat
      final updatedUser = ChatUser(
        id: chatUsers[existingIndex].id,
        name: chatUsers[existingIndex].name,
        avatar: chatUsers[existingIndex].avatar,
        lastMessage: message.message,
        lastMessageId: message.id,
        timestamp: DateFormat.jm().format(message.timestamp.toLocal()),
        unreadCount: chatUsers[existingIndex].unreadCount + 1,
        viewed: false,
        lastMessageSenderName: chatUsers[existingIndex].name,
      );

      // Move this chat to the top of the list
      chatUsers.removeAt(existingIndex);
      chatUsers.insert(0, updatedUser);
      notifyListeners();
    } else {
      // This is a new chat partner - fetch their details
      fetchUserDetails(senderId).then((user) {
        if (user != null) {
          final newChatUser = ChatUser(
            id: user.userId,
            name: user.name,
            avatar: user.profilePicture ?? 'assets/images/default_avatar.png',
            lastMessage: message.message,
            lastMessageId: message.id,
            timestamp: DateFormat.jm().format(message.timestamp.toLocal()),
            unreadCount: 1,
            viewed: false,
            lastMessageSenderName: user.name,
          );

          chatUsers.insert(0, newChatUser);
          notifyListeners();
        }
      });
    }
  }

  void _updateSentMessage(Message message) {
    final recipientId = message.recipientId;

    // Find if we already have a chat with this recipient
    int existingIndex = -1;

    for (int i = 0; i < chatUsers.length; i++) {
      if (chatUsers[i].id == recipientId) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex >= 0) {
      // Update existing chat
      final updatedUser = ChatUser(
        id: chatUsers[existingIndex].id,
        name: chatUsers[existingIndex].name,
        avatar: chatUsers[existingIndex].avatar,
        lastMessage: message.message,
        lastMessageId: message.id,
        timestamp: DateFormat.jm().format(message.timestamp.toLocal()),
        unreadCount: chatUsers[existingIndex].unreadCount,
        viewed: true,
        lastMessageSenderName: 'You',
      );

      // Move this chat to the top of the list
      chatUsers.removeAt(existingIndex);
      chatUsers.insert(0, updatedUser);
      notifyListeners();
    }
  }

  Future<void> initializeData() async {
    try {
      final storedToken = await _chatService.getToken();
      if (storedToken == null) {
        // Navigate to login - will need to be handled differently in Provider
        // See navigation section below
        return;
      }

      final userData = await _chatService.getUserData();
      if (userData != null) {
        currentUser = userData;

        // Initialize the socket connection with current user
        _socketService.initialize(userData.userId);

        notifyListeners();
        await fetchUserMessages(userData.userId);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Snackbar will be shown from UI layer
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserMessages(String userId) async {
    try {
      // First get all messages the current user has interacted with
      final messagesResponse = await _chatService.getUserMessages(userId);

      // Get unique user IDs from both sent and received messages
      final uniqueUserIds = <String>{};
      for (final message in messagesResponse) {
        if (message.senderId == userId) {
          uniqueUserIds.add(message.recipientId);
        } else {
          uniqueUserIds.add(message.senderId);
        }
      }

      // For each unique partner, create a chat user representation
      final chatUsersData = <ChatUser>[];

      for (final partnerId in uniqueUserIds) {
        // Get the full conversation between current user and partner
        final conversationResponse = await _chatService.getConversation(
          userId,
          partnerId,
        );

        // Get partner user details
        final partner = await _chatService.getUserDetails(partnerId);

        if (partner != null) {
          // Filter out empty messages like in the React code
          final messages =
              conversationResponse
                  .where(
                    (msg) =>
                        // ignore: unnecessary_null_comparison
                        msg.message != null && msg.message.trim().isNotEmpty,
                  )
                  .toList();

          // debugPrint('Messages for partner $partnerId: $messages');

          if (messages.isNotEmpty) {
            // Sort messages by timestamp to get the latest message
            messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            final latestMessage = messages[0];

            // Set the last message sender name
            final lastMessageSenderName =
                latestMessage.senderId == userId ? 'You' : partner.name;

            // Count unread messages where current user is the recipient
            final unreadCount =
                messages
                    .where((msg) => msg.senderId == partnerId && !msg.viewed)
                    .length;

            chatUsersData.add(
              ChatUser(
                id: partner.userId,
                name: partner.name,
                avatar:
                    partner.profilePicture ??
                    'assets/images/temporary-profile-placeholder-1.jpg',
                lastMessage: latestMessage.message,
                lastMessageId: latestMessage.id,
                unreadCount: unreadCount,
                timestamp: DateFormat.jm().format(
                  latestMessage.timestamp.toLocal(),
                ),
                viewed:
                    latestMessage.senderId == userId || latestMessage.viewed,
                lastMessageSenderName: lastMessageSenderName,
              ),
            );
          }
        }
      }

      chatUsers = chatUsersData;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user messages: $e');
    }
  }

  Future<User?> fetchUserDetails(String userId) async {
    try {
      final user = await _chatService.getUserDetails(userId);
      if (user != null) {
        // In Provider, we'll set selectedUserDetails when navigating to conversation
        selectedUserDetails = user;
        notifyListeners();
      }
      return user;
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      // Snackbar will be shown from UI layer
      return null;
    }
  }

  Future<void> handleSearch(String query) async {
    searchQuery = query;

    if (query.isNotEmpty) {
      try {
        final results = await _chatService.searchUsers(query);
        searchResults = results;
        notifyListeners();
      } catch (e) {
        debugPrint('Error searching users: $e');
        searchResults = [];
        notifyListeners();
      }
    } else {
      searchResults = [];
      notifyListeners();
    }
  }

  Future<void> markMessageAsViewed(String messageId) async {
    try {
      final success = await _chatService.markMessageAsViewed(messageId);

      if (success) {
        // Update the local chat user to reflect the message has been viewed
        for (int i = 0; i < chatUsers.length; i++) {
          if (chatUsers[i].lastMessageId == messageId) {
            final updatedUser = ChatUser(
              id: chatUsers[i].id,
              name: chatUsers[i].name,
              avatar: chatUsers[i].avatar,
              lastMessage: chatUsers[i].lastMessage,
              lastMessageId: chatUsers[i].lastMessageId,
              timestamp: chatUsers[i].timestamp,
              unreadCount:
                  chatUsers[i].unreadCount > 0
                      ? chatUsers[i].unreadCount - 1
                      : 0,
              viewed: true,
              lastMessageSenderName: chatUsers[i].lastMessageSenderName,
            );

            chatUsers[i] = updatedUser;
            notifyListeners();
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error marking message as viewed: $e');
    }
  }

  Future<void> handleChatPress(ChatUser chatUser) async {
    if (currentUser != null &&
        chatUser.lastMessageId.isNotEmpty &&
        !chatUser.viewed &&
        chatUser.id != currentUser!.userId) {
      await markMessageAsViewed(chatUser.lastMessageId);
    }

    // Navigation will be handled in UI layer
  }

  Future<void> handleLogout() async {
    try {
      // Clean up socket connection
      _socketService.disconnect();

      // Clear user data
      await _chatService.clearStorage();

      // Navigation will be handled in UI layer
    } catch (e) {
      debugPrint('Logout error: $e');
      // Snackbar will be shown from UI layer
    }
  }

  // Clean up resources when controller is disposed
  @override
  void dispose() {
    // Note: We don't disconnect the socket here since it's a singleton
    // and might be needed by other parts of the app
    super.dispose();
  }
}
