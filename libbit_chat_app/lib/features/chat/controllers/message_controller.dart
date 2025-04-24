import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:libbit_chat_app/core/data/services/socket_service.dart';

class MessageController extends ChangeNotifier {
  final String apiUrl = UrlConstants.apiUrl;
  final ChatService _chatService = ChatService();
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

  WebRTCService? _webRTCService;
  WebRTCService? get webRTCService => _webRTCService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  MessageController();

  void setCurrentUser(User user) {
    _currentUser = user;
    // Consider delaying notification if this is called during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setRecipient(User recipient) {
    _recipient = recipient;
    // Use post-frame callback to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    // Use post-frame callback to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> initializeWebRTC() async {
    if (_currentUser != null &&
        _currentUser!.userId.isNotEmpty &&
        _recipient != null &&
        _recipient!.userId.isNotEmpty) {
      debugPrint("Initializing WebRTC service...");
      final service = WebRTCService(userId: _currentUser!.userId);

      service.setOnMessageCallback((message) {
        if (message is Map<String, dynamic>) {
          final newMessage = Message.fromJson(message);
          _messages.add(newMessage);
          notifyListeners();
        }
      });

      await service.joinRoom(
        'chat_${_currentUser!.userId}_${_recipient!.userId}',
      );
      _webRTCService = service;
      debugPrint("WebRTC service initialized successfully");
    } else {
      debugPrint("Can't initialize WebRTC - missing userId");
    }
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
        // Add debug print to check message count after fetching
        // debugPrint("After fetchMessages, message count: ${_messages.length}");
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
      }
    } catch (error) {
      debugPrint("Error marking messages as viewed: $error");
    }
  }

  Future<void> pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Store picked file in app's temporary directory for more reliable access
      final tempDir = await getTemporaryDirectory();
      final fileName = path_lib.basename(image.path);
      final savedFile = File('${tempDir.path}/$fileName');

      // Copy the picked file to our temp directory
      final pickedFileBytes = await image.readAsBytes();
      await savedFile.writeAsBytes(pickedFileBytes);

      _selectedMedia = savedFile.path;
      notifyListeners();
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

      // Add the optimistic message to display immediately
      // Insert at index 0 since messages are already reversed
      _messages.insert(0, optimisticMessage);
      notifyListeners();

      final response = await http.post(
        Uri.parse('$apiUrl/messages/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messageObj),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle blocked messages
        if (responseData['blocked'] == true) {
          // Remove the optimistic message if it was blocked
          _messages.removeWhere((msg) => msg.id == optimisticMessage.id);
          notifyListeners();

          final url = responseData['url'];
          final probability = responseData['probability'] * 100;
          final classificationMessage = responseData['classificationMessage'];

          debugPrint("🚫 Message blocked due to high-risk link: $url");
          debugPrint("Confidence: ${probability.toStringAsFixed(2)}%");
          debugPrint(classificationMessage);
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

        // Replace the optimistic message with the real one
        final index = _messages.indexWhere(
          (msg) => msg.id == optimisticMessage.id,
        );
        if (index != -1) {
          _messages[index] = serverMessage;
        } else {
          // If for some reason we can't find the optimistic message, add the new one
          _messages.insert(0, serverMessage);
        }

        // Send via WebRTC if available
        if (_webRTCService != null) {
          try {
            await _webRTCService!.sendMessage(
              _recipient!.userId,
              serverMessage.toJson(),
            );
            debugPrint("Message sent via WebRTC");
          } catch (rtcError) {
            debugPrint(
              "Error sending via WebRTC, but HTTP successful: $rtcError",
            );
          }
        } else {
          debugPrint("WebRTC not available, message sent via HTTP only");
        }

        // Notify listeners after all updates are complete
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
  }

  void clearSelectedMedia() {
    _selectedMedia = null;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    _webRTCService?.disconnect();
    super.dispose();
  }
}
