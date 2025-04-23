import 'package:libbit_chat_app/features/chat/models/classification_message_model.dart';

// Message model
class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String message;
  final bool? isMedia;
  final DateTime timestamp;
  final bool viewed;
  final List<ClassificationMessage>? classificationMessages;
  final List<String>? flaggedUrls;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.message,
    required this.isMedia,
    required this.timestamp,
    required this.viewed,
    this.classificationMessages,
    this.flaggedUrls,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      message: json['message'],
      isMedia: json['isMedia'],
      timestamp: DateTime.parse(json['timestamp']),
      viewed: json['viewed'] ?? false,
      classificationMessages:
          json['classificationMessages'] != null
              ? (json['classificationMessages'] as List)
                  .map((e) => ClassificationMessage.fromJson(e))
                  .toList()
              : null,
      flaggedUrls:
          json['flaggedUrls'] != null
              ? List<String>.from(json['flaggedUrls'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'message': message,
      'isMedia': isMedia,
      'timestamp': timestamp.toIso8601String(),
      'viewed': viewed,
      'classificationMessages':
          classificationMessages?.map((e) => e.toJson()).toList(),
      'flaggedUrls': flaggedUrls,
    };
  }
}
