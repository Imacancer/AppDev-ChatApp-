import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/chat/models/chat_user_model.dart';
import 'package:libbit_chat_app/features/chat/models/message_model.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';
import 'package:libbit_chat_app/features/chat/services/chat_service.dart';

class ChatListController extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  // State variables
  User? currentUser;
  bool isLoading = true;
  List<ChatUser> chatUsers = [];
  User? selectedUserDetails;

  // Search functionality
  String searchQuery = '';
  List<User> searchResults = [];

  ChatListController() {
    initializeData();
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
        notifyListeners();
        await fetchUserMessages(userData.userId);

        // Direct conversation handling will be done in UI layer with Provider
      }
    } catch (e) {
      print('Initialization error: $e');
      // Snackbar will be shown from UI layer
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateChatWithNewMessage(Map<String, dynamic> message) {
    final senderId = message['senderId'];

    for (int i = 0; i < chatUsers.length; i++) {
      if (chatUsers[i].id == senderId) {
        final updatedUser = ChatUser(
          id: chatUsers[i].id,
          name: chatUsers[i].name,
          avatar: chatUsers[i].avatar,
          lastMessage: message['content'],
          lastMessageId: message['id'],
          timestamp: DateTime.now().toLocal().toString(),
          unreadCount: chatUsers[i].unreadCount + 1,
          viewed: false,
          lastMessageSenderName: chatUsers[i].name,
        );

        chatUsers[i] = updatedUser;
        notifyListeners();
        return;
      }
    }

    // If we get here, this is a new chat partner - we should fetch their info
    fetchUserDetails(senderId).then((user) {
      if (user != null) {
        final newChatUser = ChatUser(
          id: user.userId,
          name: user.name,
          avatar: user.profilePicture ?? 'assets/images/default_avatar.png',
          lastMessage: message['content'],
          lastMessageId: message['id'],
          timestamp: DateTime.now().toLocal().toString(),
          unreadCount: 1,
          viewed: false,
          lastMessageSenderName: user.name,
        );

        chatUsers.add(newChatUser);
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserMessages(String userId) async {
    try {
      // First get all messages
      final messages = await _chatService.getUserMessages(userId);

      // Get unique user IDs from both sent and received messages
      final uniqueUserIds = <String>{};
      for (final message in messages) {
        if (message.senderId == userId) {
          uniqueUserIds.add(message.recipientId);
        } else {
          uniqueUserIds.add(message.senderId);
        }
      }

      // For each unique partner, create a chat user representation
      final chatUsersData = <ChatUser>[];

      for (final partnerId in uniqueUserIds) {
        // Get conversation between current user and partner
        final conversation = await _chatService.getConversation(
          userId,
          partnerId,
        );

        // Get partner details
        final partner = await _chatService.getUserDetails(partnerId);

        if (partner != null) {
          // Compute shared secret for decryption
          final sharedSecret = await _chatService.computeSharedSecret(
            partner.userId,
          );

          // Decrypt messages
          final decryptedMessages =
              conversation.map((msg) {
                return Message(
                  id: msg.id,
                  senderId: msg.senderId,
                  recipientId: msg.recipientId,
                  message: _chatService.decryptMessage(
                    msg.message,
                    sharedSecret,
                  ),
                  timestamp: msg.timestamp,
                  viewed: msg.viewed,
                );
              }).toList();

          // Sort messages by timestamp to get the latest message
          decryptedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (decryptedMessages.isNotEmpty) {
            final latestMessage = decryptedMessages[0];

            // Set the last message sender name
            final lastMessageSenderName =
                latestMessage.senderId == userId ? 'You' : partner.name;

            // Count unread messages where current user is the recipient
            final unreadCount =
                decryptedMessages
                    .where((msg) => msg.senderId == partnerId && !msg.viewed)
                    .length;

            chatUsersData.add(
              ChatUser(
                id: partner.userId,
                name: partner.name,
                avatar:
                    partner.profilePicture ??
                    'assets/images/default_avatar.png',
                lastMessage: latestMessage.message,
                lastMessageId: latestMessage.id,
                unreadCount: unreadCount,
                timestamp: latestMessage.timestamp.toLocal().toString(),
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
      print('Error fetching user messages: $e');
      // Snackbar will be shown from UI layer
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
      print('Error fetching user details: $e');
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
        print('Error searching users: $e');
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
      print('Error marking message as viewed: $e');
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
      await _chatService.clearStorage();
      // Navigation will be handled in UI layer
    } catch (e) {
      print('Logout error: $e');
      // Snackbar will be shown from UI layer
    }
  }
}
