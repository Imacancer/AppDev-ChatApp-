import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class MessageBubbleWidget extends StatelessWidget {
  final String message;
  final bool isMe;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    this.isMe = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color:
              isMe
                  ? ColorConstants.highlightPrimary
                  : ColorConstants.neutralLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMe ? Colors.white : ColorConstants.neutralMedium,
          ),
        ),
      ),
    );
  }
}
