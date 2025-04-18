import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:libbit_chat_app/features/chat/models/message_model.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';
import 'package:libbit_chat_app/utils/constants/url_constants.dart';
import 'package:libbit_chat_app/utils/helpers/encryption.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// User model and other model classes remain unchanged

// Refactored ChatService class
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

  // Generate and store ECDH keys
  Future<void> generateAndStoreKeys() async {
    final keys = Encryption.generateECDHKeys();

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('privateKey', keys['privateKey']!);
      await prefs.setString('publicKey', keys['publicKey']!);
    } else {
      await _secureStorage.write(key: 'privateKey', value: keys['privateKey']);
      await _secureStorage.write(key: 'publicKey', value: keys['publicKey']);
    }
  }

  // Get public key
  Future<String?> getPublicKey() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('publicKey');
    } else {
      return _secureStorage.read(key: 'publicKey');
    }
  }

  // Compute shared secret for message encryption/decryption
  Future<String> computeSharedSecret(String recipientPublicKey) async {
    String? privateKey;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      privateKey = prefs.getString('privateKey');
    } else {
      privateKey = await _secureStorage.read(key: 'privateKey');
    }

    if (privateKey == null) {
      throw Exception('Private key not found');
    }

    final combined = privateKey + recipientPublicKey;
    final bytes = utf8.encode(combined);
    final sharedSecretBytes = Encryption.hash(bytes);
    return Encryption.bytesToHex(sharedSecretBytes);
  }

  // Encrypt message with shared secret
  String encryptMessage(String message, String sharedSecret) {
    return Encryption.encryptMessage(message, sharedSecret);
  }

  // Decrypt message with shared secret
  String decryptMessage(String encryptedMessage, String sharedSecret) {
    try {
      return Encryption.decryptMessage(encryptedMessage, sharedSecret);
    } catch (e) {
      print('Error decrypting message: $e');
      return '[Encrypted Message]';
    }
  }

  // API-related methods using http instead of dio
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
        print('Error fetching user messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching user messages: $e');
      return [];
    }
  }

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
        print('Error fetching conversation: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching conversation: $e');
      return [];
    }
  }

  Future<bool> markMessageAsViewed(String messageId) async {
    try {
      await init();
      final response = await http.put(
        Uri.parse('$_apiUrl/messages/view/$messageId'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking message as viewed: $e');
      return false;
    }
  }

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
      print('Error searching users: $e');
      return [];
    }
  }

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
        print('Error fetching user details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  Future<bool> sendMessage(String recipientId, String message) async {
    try {
      await init();
      final recipientDetails = await getUserDetails(recipientId);
      if (recipientDetails == null) return false;

      final currentUser = await getUserData();
      if (currentUser == null) return false;

      final sharedSecret = await computeSharedSecret(recipientDetails.userId);
      final encryptedMessage = encryptMessage(message, sharedSecret);

      final response = await http.post(
        Uri.parse('$_apiUrl/messages/send'),
        headers: _headers,
        body: jsonEncode({
          'senderId': currentUser.userId,
          'recipientId': recipientId,
          'message': encryptedMessage,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
}
