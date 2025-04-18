import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/chat/models/chat_user_model.dart';
import 'package:libbit_chat_app/features/chat/ui/screens/chat_screen.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';
import 'package:intl/intl.dart'; // You'll need to add this package to your pubspec.yaml

class CustomCardWidget extends StatelessWidget {
  final ChatUser chatUser;
  final VoidCallback onTap;

  const CustomCardWidget({
    super.key,
    required this.chatUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format timestamp if available
    String formattedTime = '';
    if (chatUser.timestamp.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(chatUser.timestamp);
        formattedTime = DateFormat('h:mm a').format(dateTime);
      } catch (e) {
        formattedTime = '';
      }
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 32,
        backgroundImage:
            chatUser.avatar.startsWith('assets/')
                ? AssetImage(chatUser.avatar) as ImageProvider
                : NetworkImage(chatUser.avatar),
        child:
            chatUser.avatar.isEmpty ||
                    (chatUser.avatar != 'assets/images/default_avatar.png' &&
                        !chatUser.avatar.startsWith('http'))
                ? Text(chatUser.name[0].toUpperCase())
                : null,
      ),
      title: Text(
        chatUser.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle:
          chatUser.lastMessage.isNotEmpty
              ? RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    if (chatUser.lastMessageSenderName.isNotEmpty)
                      TextSpan(
                        text: '${chatUser.lastMessageSenderName}: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.neutralMedium,
                        ),
                      ),
                    TextSpan(
                      text: chatUser.lastMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorConstants.neutralMedium,
                      ),
                    ),
                  ],
                ),
              )
              : Text(
                'No messages yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorConstants.neutralMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: ColorConstants.neutralMedium,
            ),
          ),
          if (chatUser.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chatUser.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      },
    );
  }
}
