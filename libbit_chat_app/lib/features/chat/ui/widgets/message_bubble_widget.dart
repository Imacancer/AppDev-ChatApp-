import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class MessageBubbleWidget extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime? timestamp;
  final bool isMedia;
  final bool isBlocked;
  final List<String>? flaggedUrls;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    this.isMe = true,
    this.timestamp,
    this.isMedia = false,
    this.isBlocked = false,
    this.flaggedUrls,
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
              isBlocked
                  ? Colors.red.shade100
                  : isMe
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border:
              isBlocked
                  ? Border.all(
                    color: ColorConstants.supportError.withAlpha(150),
                    width: 1,
                  )
                  : null,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isBlocked) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: ColorConstants.supportError,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Message blocked',
                    style: TextStyle(
                      color: ColorConstants.supportError,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'This message contains content that may be unsafe.',
                style: TextStyle(
                  color:
                      isMe
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12,
                ),
              ),
              if (flaggedUrls != null && flaggedUrls!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Flagged URL: ${flaggedUrls!.first}',
                  style: TextStyle(
                    color: ColorConstants.supportError,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ] else if (isMedia)
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
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: 100,
                        color: ColorConstants.neutralMedium,
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
                            ? Colors.white.withAlpha(150)
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
