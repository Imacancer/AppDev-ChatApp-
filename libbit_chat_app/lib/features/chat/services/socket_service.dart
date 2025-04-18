import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'dart:convert';
import 'package:libbit_chat_app/utils/constants/url_constants.dart';

// Constants - You'll need to define these in your Flutter project
// const String API_URL = 'your_api_url';
// const String LOCALHOST_URL = 'http://localhost:5001';
// const String ANDROID_EMULATOR_URL = 'http://10.0.2.2:5001';
// const String LOCALHOST_5501 = 'http://localhost:5501';
// const String MY_IP_URL = 'http://your_ip:5001';

class UserProfile {
  final String userId;
  String? profilePicture;

  UserProfile({required this.userId, this.profilePicture});

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'profilePicture': profilePicture};
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      profilePicture: json['profilePicture'],
    );
  }
}

class WebRTCService {
  final String userId;
  late io.Socket socket;
  Map<String, webrtc.RTCPeerConnection> peerConnections = {};
  Map<String, webrtc.RTCDataChannel> dataChannels = {};
  Function(dynamic)? onMessageCallback;
  Function(UserProfile)? onProfileUpdateCallback;

  WebRTCService({required this.userId}) {
    _initSocket();
    setupSocketListeners();
  }

  void _initSocket() {
    socket = io.io(
      UrlConstants.androidEmulatorUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNewConnection()
          .setExtraHeaders({'Authorization': 'Bearer $userId'})
          .build(),
    );
  }

  void setOnMessageCallback(Function(dynamic) callback) {
    onMessageCallback = callback;
  }

  void setOnProfileUpdateCallback(Function(UserProfile) callback) {
    onProfileUpdateCallback = callback;
  }

  void setupSocketListeners() {
    socket.onConnect((_) {
      print('Connected to server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
    });

    socket.onReconnect((_) {
      print('Reconnected to server');
    });

    socket.on('user_joined', (data) async {
      await createPeerConnection(data['user_id']);
    });

    socket.on('profile_update', (profile) {
      if (onProfileUpdateCallback != null) {
        final userProfile = UserProfile.fromJson(profile);
        onProfileUpdateCallback!(userProfile);
      }
    });

    socket.on('connect_error', (error) {
      print('Connection error: $error');
    });

    socket.on('error', (error) {
      print('Socket error: $error');
    });

    socket.on('offer', (data) async {
      print('Received offer from ${data['sender_id']}');
      final peerConnection = await createPeerConnection(data['sender_id']);
      final offer = webrtc.RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await peerConnection.setRemoteDescription(offer);
      final answer = await peerConnection.createAnswer({});
      await peerConnection.setLocalDescription(answer);
      print('Sending answer to ${data['sender_id']}');
      socket.emit('answer', {
        'sender_id': data['sender_id'],
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      });
    });

    socket.on('answer', (data) async {
      print('Received answer from ${data['sender_id']}');
      final peerConnection = peerConnections[data['sender_id']];
      if (peerConnection != null) {
        final answer = webrtc.RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await peerConnection.setRemoteDescription(answer);
      }
    });

    socket.on('ice_candidate', (data) async {
      print('Received ICE candidate from ${data['sender_id']}');
      final peerConnection = peerConnections[data['sender_id']];
      if (peerConnection != null) {
        final candidate = webrtc.RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        await peerConnection.addCandidate(candidate);
      }
    });

    socket.on('message', (message) {
      if (onMessageCallback != null) {
        onMessageCallback!(message);
      }
    });
  }

  Future<webrtc.RTCPeerConnection> createPeerConnection(
    String recipientId,
  ) async {
    if (peerConnections.containsKey(recipientId)) {
      return peerConnections[recipientId]!;
    }

    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    final peerConnection = await createPeerConnectionWithConfiguration(
      configuration,
    );
    peerConnections[recipientId] = peerConnection;

    // Create data channel
    final dataChannelInit = webrtc.RTCDataChannelInit();
    dataChannelInit.ordered = true;
    final dataChannel = await peerConnection.createDataChannel(
      'messageChannel',
      dataChannelInit,
    );
    setupDataChannel(dataChannel);
    dataChannels[recipientId] = dataChannel;

    peerConnection.onIceCandidate = (webrtc.RTCIceCandidate candidate) {
      print('ICE Candidate: ${candidate.toMap()}');
      socket.emit('ice_candidate', {
        'recipient_id': recipientId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    peerConnection.onDataChannel = (webrtc.RTCDataChannel channel) {
      setupDataChannel(channel);
    };

    return peerConnection;
  }

  Future<webrtc.RTCPeerConnection> createPeerConnectionWithConfiguration(
    Map<String, dynamic> configuration,
  ) async {
    return await webrtc.createPeerConnection(configuration);
  }

  void setupDataChannel(webrtc.RTCDataChannel dataChannel) {
    dataChannel.onDataChannelState = (webrtc.RTCDataChannelState state) {
      if (state == webrtc.RTCDataChannelState.RTCDataChannelOpen) {
        print('Data channel is open and ready to send data.');
      } else if (state == webrtc.RTCDataChannelState.RTCDataChannelClosed) {
        print('Data channel is closed.');
      }
    };

    dataChannel.onMessage = (webrtc.RTCDataChannelMessage message) {
      print('Message received via data channel: ${message.text}');
      if (onMessageCallback != null) {
        final decodedMessage = json.decode(message.text);
        onMessageCallback!(decodedMessage);
      }
    };
  }

  Future<void> updateProfile(String profilePicture) async {
    socket.emit('profile_update', {
      'userId': userId,
      'profilePicture': profilePicture,
    });
  }

  Future<void> joinRoom(String roomId) async {
    socket.emit('join_room', {'user_id': userId, 'room': roomId});
  }

  Future<void> sendMessage(String recipientId, dynamic message) async {
    try {
      final messageString = json.encode(message);

      final dataChannel = dataChannels[recipientId];
      if (dataChannel != null &&
          dataChannel.state == webrtc.RTCDataChannelState.RTCDataChannelOpen) {
        print('Sending encrypted message via WebRTC');
        dataChannel.send(webrtc.RTCDataChannelMessage(messageString));
      } else {
        print('Falling back to WebSocket');
        socket.emit('message', {
          'recipient_id': recipientId,
          'message': message,
        });
      }
    } catch (error) {
      print('Failed to send message: $error');
      rethrow;
    }
  }

  void disconnect() {
    peerConnections.forEach((userId, peerConnection) {
      peerConnection.close();
    });
    peerConnections.clear();
    dataChannels.clear();
    socket.disconnect();
  }
}
