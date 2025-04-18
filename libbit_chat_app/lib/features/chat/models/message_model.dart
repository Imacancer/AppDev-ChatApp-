// Message model
class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String message;
  final DateTime timestamp;
  final bool viewed;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.message,
    required this.timestamp,
    required this.viewed,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      viewed: json['viewed'] ?? false,
    );
  }
}
