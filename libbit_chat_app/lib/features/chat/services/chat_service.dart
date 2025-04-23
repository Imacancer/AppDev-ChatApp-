import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:libbit_chat_app/features/chat/models/message_model.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';
import 'package:libbit_chat_app/features/chat/models/chat_user_model.dart';
import 'package:libbit_chat_app/utils/constants/url_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _apiUrl = UrlConstants.apiUrl;
  final Map<String, String> _headers = {};

  // Initialize with auth token
  Future<void> init() async {
    final token = await getToken();
    if (token != null) {
      _headers['Authorization'] = 'Bearer $token';
    }
    _headers['Content-Type'] = 'application/json';
  }

  // Platform-specific token retrieval
  Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userToken');
    } else {
      return await _secureStorage.read(key: 'userToken');
    }
  }

  // Platform-specific user data retrieval
  Future<User?> getUserData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('userData');
      return data != null ? User.fromJson(jsonDecode(data)) : null;
    } else {
      final data = await _secureStorage.read(key: 'userData');
      return data != null ? User.fromJson(jsonDecode(data)) : null;
    }
  }

  // Platform-specific storage clearing for logout
  Future<void> clearStorage() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken');
      await prefs.remove('userData');
    } else {
      await _secureStorage.delete(key: 'userToken');
      await _secureStorage.delete(key: 'userData');
    }
  }

  // Get a list of all conversations/chats for the current user
  Future<List<ChatUser>> getUserChats(String userId) async {
    try {
      await init();
      final response = await http.get(
        Uri.parse('$_apiUrl/conversations/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<ChatUser> chatUsers = [];

        for (final item in data) {
          final user = item['user'];
          final lastMessage = item['lastMessage'];

          if (user != null && lastMessage != null) {
            // Update this part in getUserChats method:
            final ChatUser chatUser = ChatUser(
              id: user['userId'],
              name: user['name'],
              avatar:
                  user['profilePicture'] ?? 'assets/images/default_avatar.png',
              lastMessage: lastMessage['message'] ?? '',
              lastMessageId: lastMessage['_id'] ?? '',
              unreadCount: item['unreadCount'] ?? 0,
              timestamp: ChatUser.parseTimestamp(
                lastMessage['timestamp'],
              ), // Use the helper method
              viewed: lastMessage['viewed'] ?? false,
              lastMessageSenderName: lastMessage['senderName'] ?? '',
            );

            chatUsers.add(chatUser);
          }
        }
        return chatUsers;
      } else {
        debugPrint('Error fetching user chats: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching user chats: $e');
      return [];
    }
  }

  // Get user messages
  Future<List<Message>> getUserMessages(String userId) async {
    try {
      await init();
      final response = await http.get(
        Uri.parse('$_apiUrl/messages/getMessages/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> messageData = jsonDecode(response.body);
        return messageData.map((data) => Message.fromJson(data)).toList();
      } else {
        debugPrint('Error fetching user messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching user messages: $e');
      return [];
    }
  }

  // Get conversation messages between two users
  Future<List<Message>> getConversation(String userId, String partnerId) async {
    try {
      await init();
      final response = await http.get(
        Uri.parse('$_apiUrl/messages/conversation/$userId/$partnerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> messageData = jsonDecode(response.body);
        return messageData.map((data) => Message.fromJson(data)).toList();
      } else {
        debugPrint('Error fetching conversation: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
      return [];
    }
  }

  // Mark message as viewed
  Future<bool> markMessageAsViewed(String messageId) async {
    try {
      await init();
      final response = await http.put(
        Uri.parse('$_apiUrl/messages/view/$messageId'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking message as viewed: $e');
      return false;
    }
  }

  // Search users by query
  Future<List<User>> searchUsers(String query) async {
    try {
      await init();
      final response = await http.get(
        Uri.parse('$_apiUrl/search_users?query=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['users'] != null) {
          final List<dynamic> userData = data['users'];
          return userData.map((data) => User.fromJson(data)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Get user details
  Future<User?> getUserDetails(String userId) async {
    try {
      await init();
      final response = await http.get(
        Uri.parse('$_apiUrl/get_user/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data['user']);
      } else {
        debugPrint('Error fetching user details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }

  // Send a message
  Future<Map<String, dynamic>?> sendMessage({
    required String senderId,
    required String recipientId,
    required String message,
    String? mediaUrl,
  }) async {
    try {
      await init();

      final messageObj = {
        'sender_id': senderId,
        'recipient_id': recipientId,
        'message': message,
        'isMedia': mediaUrl != null,
        'file_url': mediaUrl,
      };

      final response = await http.post(
        Uri.parse('$_apiUrl/messages/send'),
        headers: _headers,
        body: jsonEncode(messageObj),
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error sending message: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }
}
