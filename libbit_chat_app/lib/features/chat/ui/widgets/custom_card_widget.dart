import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/chat/ui/screens/chat_screen.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class CustomCardWidget extends StatelessWidget {
  const CustomCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(radius: 32),
      title: Text(
        'Hoshimachi Suisei',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        'message',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: ColorConstants.neutralMedium),
      ),
      trailing: Text(
        '7:28 PM',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: ColorConstants.neutralMedium),
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
