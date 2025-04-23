// ChatUser model
import 'package:flutter/material.dart';

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

  // Helper method to safely parse timestamps for ChatUser creation
  // In ChatUser class
  static String parseTimestamp(dynamic rawTimestamp) {
    if (rawTimestamp == null) {
      return DateTime.now().toIso8601String();
    }

    try {
      if (rawTimestamp is String) {
        try {
          // Try standard ISO format first
          return DateTime.parse(rawTimestamp).toIso8601String();
        } catch (e) {
          // Try HTTP date format (RFC 1123)
          try {
            // Handle format like: "Wed, 23 Apr 2025 12:50:45 GMT"
            String httpDate = rawTimestamp;
            final months = {
              'Jan': 1,
              'Feb': 2,
              'Mar': 3,
              'Apr': 4,
              'May': 5,
              'Jun': 6,
              'Jul': 7,
              'Aug': 8,
              'Sep': 9,
              'Oct': 10,
              'Nov': 11,
              'Dec': 12,
            };

            final parts = httpDate.split(' ');
            if (parts.length >= 6) {
              final day = int.parse(parts[1]);
              final month = months[parts[2]] ?? 1;
              final year = int.parse(parts[3]);
              final timeParts = parts[4].split(':');
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              final second = int.parse(timeParts[2]);

              return DateTime.utc(
                year,
                month,
                day,
                hour,
                minute,
                second,
              ).toIso8601String();
            }
          } catch (e) {
            debugPrint('Error parsing HTTP date in ChatUser: $rawTimestamp');
          }
        }
      } else if (rawTimestamp is int) {
        // Handle Unix timestamp (milliseconds)
        return DateTime.fromMillisecondsSinceEpoch(
          rawTimestamp,
        ).toIso8601String();
      } else if (rawTimestamp is Map) {
        // Handle timestamp as a MongoDB date object
        if (rawTimestamp['\$date'] != null) {
          if (rawTimestamp['\$date'] is int) {
            return DateTime.fromMillisecondsSinceEpoch(
              rawTimestamp['\$date'],
            ).toIso8601String();
          } else if (rawTimestamp['\$date'] is String) {
            return DateTime.parse(rawTimestamp['\$date']).toIso8601String();
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing chat timestamp: $rawTimestamp. Error: $e');
    }

    return DateTime.now().toIso8601String();
  }
}
