import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:libbit_chat_app/features/chat/models/message_model.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';
import 'package:libbit_chat_app/features/chat/models/classification_message_model.dart';
import 'package:libbit_chat_app/utils/constants/url_constants.dart';
import 'package:libbit_chat_app/features/chat/services/chat_service.dart';
import 'package:libbit_chat_app/core/services/socket_service.dart';

class MessageController extends ChangeNotifier {
  final String apiUrl = UrlConstants.apiUrl;
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  List<Message> _messages = [];
  List<Message> get messages => _messages;

  final TextEditingController textController = TextEditingController();
  String? _selectedMedia;
  String? get selectedMedia => _selectedMedia;

  User? _currentUser;
  User? get currentUser => _currentUser;

  User? _recipient;
  User? get recipient => _recipient;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _messageBlocked = false;
  String? _blockedMessageInfo;
  bool get messageBlocked => _messageBlocked;
  String? get blockedMessageInfo => _blockedMessageInfo;

  bool _isPickerActive = false;
  final ImagePicker _picker = ImagePicker();

  MessageController() {
    // Set up socket message callback
    _socketService.setOnNewMessageCallback(_handleSocketMessage);
    _socketService.setOnConnectionStatusCallback(_handleConnectionStatus);
  }

  // Handle socket connection status changes
  void _handleConnectionStatus(String status) {
    debugPrint('Socket connection status: $status');
    // You can add UI feedback for connection status if needed

    // If reconnected, attempt to rejoin the chat room
    if (status == 'connected' && _currentUser != null && _recipient != null) {
      _joinChatRoom();
    }
  }

  // Join chat room with appropriate room ID generation
  void _joinChatRoom() {
    final roomId = _getRoomId(_currentUser!.userId, _recipient!.userId);
    debugPrint("Joining room: $roomId");
    _socketService.joinRoom(roomId);
  }

  // Generate consistent room ID regardless of user order
  String _getRoomId(String userId1, String userId2) {
    // Sort the IDs to ensure the same room ID regardless of which user starts the chat
    final sortedIds = [userId1, userId2]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  // Handle incoming socket messages with improved duplicate detection
  void _handleSocketMessage(Message message) {
    debugPrint('Received socket message in controller: ${message.message}');

    // Check if this message is relevant to current conversation
    if (_isMessageForCurrentConversation(message)) {
      // Check for duplicates with more robust ID comparison
      final existingIndex = _messages.indexWhere(
        (msg) =>
            msg.id == message.id ||
            (msg.senderId == message.senderId &&
                msg.timestamp.toString() == message.timestamp.toString() &&
                msg.message == message.message),
      );

      if (existingIndex >= 0) {
        // Update existing message
        _messages[existingIndex] = message;
      } else {
        // Add new message
        _messages.add(message);

        // Sort messages by timestamp to ensure correct order
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      notifyListeners();

      // Mark incoming messages as viewed automatically
      if (_shouldMarkAsViewed(message)) {
        _chatService.markMessageAsViewed(message.id);
      }
    }

    // Debug logging
    debugPrint('Messages count after update: ${_messages.length}');
    if (_messages.isNotEmpty) {
      debugPrint('Last/newest message now: ${_messages.last.message}');
    }
  }

  // Check if a message is for the current conversation
  bool _isMessageForCurrentConversation(Message message) {
    if (_currentUser == null || _recipient == null) return false;

    return (message.senderId == _currentUser!.userId &&
            message.recipientId == _recipient!.userId) ||
        (message.senderId == _recipient!.userId &&
            message.recipientId == _currentUser!.userId);
  }

  // Check if we should mark a message as viewed
  bool _shouldMarkAsViewed(Message message) {
    return _currentUser != null &&
        message.recipientId == _currentUser!.userId &&
        !message.viewed;
  }

  void setCurrentUser(User user) {
    _currentUser = user;

    // Initialize socket connection with current user
    _socketService.initialize(user.userId);

    notifyListeners();
  }

  void setRecipient(User recipient) {
    _recipient = recipient;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> initializeConversation(String recipientId) async {
    try {
      setLoading(true);
      final token = await _chatService.getToken();
      final userData = await _chatService.getUserData();

      if (token == null || userData == null) {
        debugPrint("No token or user data found");
        return;
      }

      _headers['Authorization'] = 'Bearer $token';
      setCurrentUser(userData);

      // Fetch recipient details
      final recipientData = await _chatService.getUserDetails(recipientId);

      if (recipientData != null) {
        setRecipient(recipientData);
        await fetchMessages(token, userData.userId, recipientId);

        // Join the chat room for real-time messages
        if (_currentUser != null && _recipient != null) {
          _joinChatRoom();

          // Check if socket is connected
          debugPrint("Socket connected: ${_socketService.isConnected}");
        }
      } else {
        debugPrint("Error fetching recipient");
      }
    } catch (error) {
      debugPrint("Initialization error: $error");
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchMessages(
    String token,
    String userId,
    String recipientId,
  ) async {
    try {
      final messages = await _chatService.getConversation(userId, recipientId);
      debugPrint(
        'Fetched ${messages.length} messages. First message: ${messages.isNotEmpty ? messages[0].message : "none"}',
      );
      debugPrint(
        'Last/newest message: ${messages.isNotEmpty ? messages[messages.length - 1].message : "none"}',
      );

      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _messages = messages;
      notifyListeners();

      // Mark unread messages as viewed
      await markUnreadMessagesAsViewed();
    } catch (error) {
      debugPrint("Error fetching messages: $error");
    }
  }

  Future<void> markUnreadMessagesAsViewed() async {
    try {
      if (_currentUser == null) return;

      final unreadMessages =
          _messages
              .where(
                (msg) => msg.recipientId == _currentUser!.userId && !msg.viewed,
              )
              .toList();

      for (final msg in unreadMessages) {
        await _chatService.markMessageAsViewed(msg.id);
        // Update local message state for immediate UI feedback
        final index = _messages.indexWhere((m) => m.id == msg.id);
        if (index >= 0) {
          _messages[index].viewed = true;
        }
      }

      if (unreadMessages.isNotEmpty) {
        notifyListeners();
      }
    } catch (error) {
      debugPrint("Error marking messages as viewed: $error");
    }
  }

  Future<void> pickMedia([ImageSource source = ImageSource.gallery]) async {
    if (_isPickerActive) return;

    _isPickerActive = true;

    try {
      final XFile? image = await _picker.pickImage(source: source).catchError((
        e,
      ) {
        if (e is PlatformException && e.code == 'already_active') {
          debugPrint("Image picker is already active");
          return null;
        }
        throw e;
      });

      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final fileName = path_lib.basename(image.path);
        final savedFile = File('${tempDir.path}/$fileName');

        final pickedFileBytes = await image.readAsBytes();
        await savedFile.writeAsBytes(pickedFileBytes);

        _selectedMedia = savedFile.path;
        notifyListeners();
      }
    } catch (error) {
      debugPrint("Error picking media: $error");
    } finally {
      _isPickerActive = false;
    }
  }

  Future<String?> uploadMedia(String mediaPath) async {
    try {
      final token = await _chatService.getToken();
      if (token == null) return null;

      final file = File(mediaPath);
      final fileName = path_lib.basename(file.path);
      final fileExtension = path_lib.extension(fileName).replaceFirst('.', '');

      String mimeType;
      if (['jpg', 'jpeg', 'png'].contains(fileExtension.toLowerCase())) {
        mimeType = 'image/${fileExtension.toLowerCase()}';
      } else if (['mp4', 'mov', 'avi'].contains(fileExtension.toLowerCase())) {
        mimeType = 'video/${fileExtension.toLowerCase()}';
      } else {
        mimeType = 'application/octet-stream';
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/messages/upload'),
      );
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        debugPrint("Upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (error) {
      debugPrint("Error uploading media: $error");
      return null;
    }
  }

  Future<void> sendMessage([String? overrideText]) async {
    // Use the override text if provided, otherwise use the controller text
    final messageText = overrideText ?? textController.text.trim();

    // Debug print to check inputs
    debugPrint(
      "sendMessage called. Text: $messageText, Media: $_selectedMedia",
    );

    debugPrint("Initial _messageBlocked state: $_messageBlocked");

    if ((messageText.isEmpty && _selectedMedia == null) ||
        _currentUser == null ||
        _recipient == null) {
      debugPrint("Message not sent: missing content or user data");
      return;
    }

    // Clear text immediately for better UX
    if (overrideText == null) {
      textController.clear();
    }

    String? mediaUrl;
    String? mediaPathCopy = _selectedMedia;

    // Store the media path and clear the selected media immediately
    if (_selectedMedia != null) {
      debugPrint("Uploading media...");
      _selectedMedia = null; // Clear immediately
      notifyListeners(); // Update UI to show the media is being processed

      mediaUrl = await uploadMedia(mediaPathCopy!);
      if (mediaUrl == null) {
        debugPrint("Failed to upload media.");
        return;
      }
    }

    try {
      final token = await _chatService.getToken();
      if (token == null) {
        debugPrint("No token available");
        return;
      }

      final messageContent = mediaUrl ?? messageText;
      final isMediaMessage = mediaUrl != null;

      final messageObj = {
        'sender_id': _currentUser!.userId,
        'recipient_id': _recipient!.userId,
        'message': messageContent,
        'isMedia': isMediaMessage,
        'file_url': mediaUrl,
      };

      // Create a temporary optimistic message to show immediately
      final optimisticMessage = Message(
        id: "temp_${DateTime.now().millisecondsSinceEpoch}",
        senderId: _currentUser!.userId,
        recipientId: _recipient!.userId,
        message: messageContent,
        isMedia: isMediaMessage,
        timestamp: DateTime.now(),
        viewed: false,
      );

      // BEFORE adding the optimistic message, log the count
      debugPrint("Message count BEFORE adding: ${_messages.length}");

      // Add the optimistic message to display immediately
      _messages.add(optimisticMessage);
      debugPrint("Message count AFTER adding optimistic: ${_messages.length}");
      notifyListeners();

      final response = await http.post(
        Uri.parse('$apiUrl/messages/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messageObj),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Server response: ${response.body}");

        final responseData = jsonDecode(response.body);

        // Handle blocked messages
        if (responseData['blocked'] == true) {
          final url = responseData['url'];
          final probability = responseData['probability'] * 100;
          final classificationMessage = responseData['classificationMessage'];

          // Set blocked message status
          _messageBlocked = true;
          debugPrint("Current _messageBlocked state: $_messageBlocked");

          _blockedMessageInfo =
              "Message blocked: $classificationMessage\nURL: $url\nConfidence: ${probability.toStringAsFixed(2)}%";
          notifyListeners();

          debugPrint("🚫 Message blocked due to high-risk link: $url");
          debugPrint("Confidence: ${probability.toStringAsFixed(2)}%");
          debugPrint(classificationMessage);

          // Remove the optimistic message
          _messages.removeWhere((msg) => msg.id == optimisticMessage.id);
          notifyListeners();
          return;
        }

        // Process classification messages
        List<ClassificationMessage>? classificationMessages;
        List<String>? flaggedUrls;

        if (responseData['classificationMessages'] != null) {
          classificationMessages =
              (responseData['classificationMessages'] as List)
                  .map((msg) => ClassificationMessage.fromJson(msg))
                  .toList();

          flaggedUrls =
              classificationMessages
                  .where((msg) => msg.classification != "benign")
                  .map((msg) => msg.url)
                  .toList();
        }

        // Create the real message object with server-provided ID
        final serverMessage = Message(
          id:
              responseData['_id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: _currentUser!.userId,
          recipientId: _recipient!.userId,
          message: messageContent,
          isMedia: isMediaMessage,
          timestamp: DateTime.now(),
          viewed: false,
          classificationMessages: classificationMessages,
          flaggedUrls: flaggedUrls,
        );

        // Remove the optimistic message
        _messages.removeWhere((msg) => msg.id == optimisticMessage.id);

        // Now add the server message
        _messages.add(serverMessage);

        // Log the count after replacement
        debugPrint(
          "Message count after server replacement: ${_messages.length}",
        );

        // Emit socket event for real-time updates if socket is connected
        // This ensures the recipient gets the message immediately via socket
        if (_socketService.isConnected) {
          final socketMessageData = {
            'sender_id': _currentUser!.userId,
            'recipient_id': _recipient!.userId,
            'message': messageContent,
            'timestamp': DateTime.now().toIso8601String(),
            'room': _getRoomId(_currentUser!.userId, _recipient!.userId),
            'is_media': isMediaMessage,
            'file_url': mediaUrl,
            'message_id': serverMessage.id,
          };

          _socketService.sendMessage(socketMessageData);
        }

        notifyListeners();
      } else if (response.statusCode == 400) {
        // Handle 400 error, remove optimistic message
        _messages.removeWhere((msg) => msg.id == optimisticMessage.id);
        notifyListeners();

        final data = jsonDecode(response.body);
        if (data['blocked'] == true) {
          // Handle blocked message logic here
          final url = data['url'];
          final probability = data['probability'] * 100;
          final classificationMessage = data['classificationMessage'];

          // Set blocked message status
          _messageBlocked = true;
          debugPrint("Current _messageBlocked state: $_messageBlocked");

          _blockedMessageInfo =
              "Message blocked: $classificationMessage\nURL: $url\nConfidence: ${probability.toStringAsFixed(2)}%";
          notifyListeners();

          debugPrint("🚫 Message blocked due to high-risk link: $url");
          debugPrint("Confidence: ${probability.toStringAsFixed(2)}%");
          debugPrint(classificationMessage);
        } else {
          debugPrint("Error sending message: ${response.statusCode}");
        }
      } else {
        // Handle other errors, remove optimistic message
        _messages.removeWhere((msg) => msg.id == optimisticMessage.id);
        notifyListeners();
        debugPrint("Error sending message: ${response.statusCode}");
      }
    } catch (error) {
      // In case of an exception, remove the optimistic message
      _messages.removeWhere((msg) => msg.id.startsWith("temp_"));
      notifyListeners();

      debugPrint("Error sending message: $error");
      debugPrint("Failed to send message. Please try again.");
    }

    // Add to your sendMessage method:
    debugPrint("Message list length after sending: ${_messages.length}");
    if (_messages.isNotEmpty) {
      debugPrint("Last message: ${_messages.last.message}");
    }
  }

  void clearSelectedMedia() {
    _selectedMedia = null;
    notifyListeners();
  }

  // This method clears the blocked message status
  void clearBlockedMessageStatus() {
    _messageBlocked = false;
    _blockedMessageInfo = null;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    // We don't disconnect socket service here since it's a singleton
    // and might be used by other controllers
    super.dispose();
  }
}
