import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubbleWidget extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime? timestamp;
  final bool isMedia;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    this.isMe = true,
    this.timestamp,
    this.isMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormatted =
        timestamp != null
            ? DateFormat('h:mm a').format(timestamp!.toLocal())
            : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isMe
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isMedia)
              Container(
                constraints: BoxConstraints(
                  maxHeight: 200,
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                ),
              )
            else
              Text(
                message,
                style: TextStyle(
                  color:
                      isMe
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  timeFormatted,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isMe
                            ? Colors.white.withOpacity(0.7)
                            : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
