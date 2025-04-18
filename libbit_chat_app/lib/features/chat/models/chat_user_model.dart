// ChatUser model
class ChatUser {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String lastMessageId;
  final int unreadCount;
  final String timestamp;
  final bool viewed;
  final String lastMessageSenderName;

  ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageId,
    required this.unreadCount,
    required this.timestamp,
    required this.viewed,
    required this.lastMessageSenderName,
  });
}
