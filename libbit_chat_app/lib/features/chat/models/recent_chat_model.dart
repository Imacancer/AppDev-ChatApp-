class RecentChatModel {
  String id;
  String name;
  String avatar;
  String lastMessageId;
  String lastMessage;
  String lastMessageSenderName;
  int unreadCount;
  String timestamp;
  bool isViewed;

  RecentChatModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessageId,
    required this.lastMessage,
    required this.lastMessageSenderName,
    required this.unreadCount,
    required this.isViewed,
    required this.timestamp,
  });

  // Convert JSON from API to Dart Model
  factory RecentChatModel.fromJson(Map<String, dynamic> json) {
    return RecentChatModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'] ?? '',
      lastMessageId: json['lastMessageId'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageSenderName: json['lastMessageSenderName'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      isViewed: json['isViewed'] ?? false,
      timestamp: json['timestamp'] ?? '',
    );
  }
}
