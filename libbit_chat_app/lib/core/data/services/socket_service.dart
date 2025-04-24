import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:libbit_chat_app/utils/constants/url_constants.dart';
import 'package:libbit_chat_app/features/chat/models/message_model.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';

class SocketService {
  io.Socket? _socket;
  String? _userId;
  bool _isConnected = false;

  // Callbacks for different events
  Function(Message)? onNewMessageCallback;
  Function(User)? onProfileUpdateCallback;
  Function(String)? onUserJoinedCallback;
  Function(String)? onConnectionStatusCallback;

  // Singleton pattern
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  bool get isConnected => _isConnected;

  void initialize(String userId) {
    if (_socket != null) {
      // If already connected with the same user, don't reconnect
      if (_isConnected && _userId == userId) return;

      // Disconnect existing socket if user changed
      disconnect();
    }

    _userId = userId;
    _connectSocket();
  }

  void _connectSocket() {
    debugPrint('Connecting to socket server with userId: $_userId');

    String socketUrl = UrlConstants.androidEmulatorUrl;

    // For debugging connection issues
    debugPrint('Socket connecting to: $socketUrl');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNewConnection()
          .setExtraHeaders({'Authorization': 'Bearer $_userId'})
          .build(),
    );

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('Socket connected successfully');
      _isConnected = true;
      if (onConnectionStatusCallback != null) {
        onConnectionStatusCallback!('connected');
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
      _isConnected = false;
      if (onConnectionStatusCallback != null) {
        onConnectionStatusCallback!('disconnected');
      }
    });

    _socket!.onReconnect((_) {
      debugPrint('Socket reconnected');
      _isConnected = true;
      if (onConnectionStatusCallback != null) {
        onConnectionStatusCallback!('connected');
      }
    });

    _socket!.on('message', (data) {
      debugPrint('Received socket message: $data');
      if (onNewMessageCallback != null) {
        try {
          final message = Message.fromJson(data);
          onNewMessageCallback!(message);
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      }
    });

    _socket!.on('profile_update', (data) {
      debugPrint('Received profile update: $data');
      if (onProfileUpdateCallback != null) {
        try {
          final user = User.fromJson(data);
          onProfileUpdateCallback!(user);
        } catch (e) {
          debugPrint('Error parsing profile update: $e');
        }
      }
    });

    _socket!.on('user_joined', (data) {
      debugPrint('User joined: ${data['user_id']}');
      if (onUserJoinedCallback != null) {
        onUserJoinedCallback!(data['user_id']);
      }
    });

    _socket!.on('connect_error', (error) {
      debugPrint('Socket connection error: $error');
      if (onConnectionStatusCallback != null) {
        onConnectionStatusCallback!('error: $error');
      }
    });

    // Add more detailed error logging
    _socket!.on('connect_error', (error) {
      debugPrint('Socket connection error: $error');
      debugPrint('Connection attempted with user ID: $_userId');
      if (onConnectionStatusCallback != null) {
        onConnectionStatusCallback!('error: $error');
      }
    });
  }

  void joinRoom(String roomId) {
    if (_socket != null && _isConnected) {
      debugPrint('Joining room: $roomId');
      _socket!.emit('join_room', {'user_id': _userId, 'room': roomId});
    } else {
      debugPrint('Cannot join room: Socket not connected');
    }
  }

  void sendMessage(Map<String, dynamic> messageData) {
    if (_socket != null && _isConnected) {
      debugPrint('Sending socket message: $messageData');
      _socket!.emit('message', messageData);
    } else {
      debugPrint('Cannot send message: Socket not connected');
    }
  }

  void updateProfile(Map<String, dynamic> profileData) {
    if (_socket != null && _isConnected) {
      _socket!.emit('profile_update', profileData);
    }
  }

  void disconnect() {
    if (_socket != null) {
      debugPrint('Disconnecting socket');
      _socket!.disconnect();
      _socket!.close();
      _socket = null;
      _isConnected = false;
      _userId = null;
    }
  }

  // Set various event callbacks
  void setOnNewMessageCallback(Function(Message) callback) {
    onNewMessageCallback = callback;
  }

  void setOnProfileUpdateCallback(Function(User) callback) {
    onProfileUpdateCallback = callback;
  }

  void setOnUserJoinedCallback(Function(String) callback) {
    onUserJoinedCallback = callback;
  }

  void setOnConnectionStatusCallback(Function(String) callback) {
    onConnectionStatusCallback = callback;
  }
}
