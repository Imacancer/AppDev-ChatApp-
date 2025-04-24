// Message model
import 'package:flutter/widgets.dart';
import 'package:libbit_chat_app/features/chat/models/classification_message_model.dart';

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
    this.isMedia,
    required this.timestamp,
    required this.viewed,
    this.classificationMessages,
    this.flaggedUrls,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Robust timestamp parsing with HTTP date format support
    DateTime parsedTimestamp;
    try {
      if (json['timestamp'] != null) {
        if (json['timestamp'] is String) {
          try {
            // First try standard ISO format
            parsedTimestamp = DateTime.parse(json['timestamp']);
          } catch (e) {
            // Try HTTP date format (RFC 1123)
            try {
              // Handle format like: "Wed, 23 Apr 2025 12:50:45 GMT"
              String httpDate = json['timestamp'];

              // Parse the HTTP date format manually
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

              // Example: "Wed, 23 Apr 2025 12:50:45 GMT"
              final parts = httpDate.split(' ');
              if (parts.length >= 6) {
                final day = int.parse(parts[1]);
                final month = months[parts[2]] ?? 1;
                final year = int.parse(parts[3]);
                final timeParts = parts[4].split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                final second = int.parse(timeParts[2]);

                parsedTimestamp = DateTime.utc(
                  year,
                  month,
                  day,
                  hour,
                  minute,
                  second,
                );
              } else {
                throw Exception('Invalid HTTP date format');
              }
            } catch (e) {
              debugPrint(
                'Error parsing HTTP date: ${json['timestamp']}. Error: $e',
              );
              parsedTimestamp = DateTime.now();
            }
          }
        } else if (json['timestamp'] is int) {
          // Handle Unix timestamp (milliseconds)
          parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
            json['timestamp'],
          );
        } else if (json['timestamp'] is Map) {
          // Handle timestamp as a MongoDB date object
          if (json['timestamp']['\$date'] != null) {
            if (json['timestamp']['\$date'] is int) {
              parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
                json['timestamp']['\$date'],
              );
            } else if (json['timestamp']['\$date'] is String) {
              parsedTimestamp = DateTime.parse(json['timestamp']['\$date']);
            } else {
              parsedTimestamp = DateTime.now();
            }
          } else {
            parsedTimestamp = DateTime.now();
          }
        } else {
          // Fallback to current time if format is unrecognized
          parsedTimestamp = DateTime.now();
        }
      } else {
        // Default to current time if timestamp is missing
        parsedTimestamp = DateTime.now();
      }
    } catch (e) {
      // Catch format exceptions and use current time as fallback
      debugPrint('Error parsing timestamp: ${json['timestamp']}. Error: $e');
      parsedTimestamp = DateTime.now();
    }

    // Handle classification messages carefully
    List<ClassificationMessage>? classifications;
    if (json['classificationMessages'] != null) {
      try {
        classifications =
            (json['classificationMessages'] as List)
                .map((e) => ClassificationMessage.fromJson(e))
                .toList();
      } catch (e) {
        debugPrint('Error parsing classification messages: $e');
        classifications = null;
      }
    } else if (json['classification_messages'] != null) {
      try {
        classifications =
            (json['classification_messages'] as List)
                .map((e) => ClassificationMessage.fromJson(e))
                .toList();
      } catch (e) {
        debugPrint('Error parsing classification messages: $e');
        classifications = null;
      }
    }

    // Handle flagged URLs carefully
    List<String>? urls;
    if (json['flaggedUrls'] != null) {
      try {
        if (json['flaggedUrls'] is List) {
          // Process as list
          urls =
              (json['flaggedUrls'] as List)
                  .whereType<String>() // Only include string items
                  .map((item) => item)
                  .toList();
        } else if (json['flaggedUrls'] is Map) {
          // Handle case where it's a map instead of expected list
          debugPrint('Warning: flaggedUrls is a Map, not a List as expected');
          // You could extract values from the map if they represent URLs
          urls = [];
        }
      } catch (e) {
        debugPrint('Error parsing flagged URLs: $e');
        urls = null;
      }
    } else if (json['flagged_urls'] != null) {
      try {
        if (json['flagged_urls'] is List) {
          // Process as list
          urls =
              (json['flagged_urls'] as List)
                  .whereType<String>() // Only include string items
                  .map((item) => item)
                  .toList();
        } else if (json['flagged_urls'] is Map) {
          // Handle case where it's a map instead of expected list
          debugPrint('Warning: flagged_urls is a Map, not a List as expected');
          urls = [];
        }
      } catch (e) {
        debugPrint('Error parsing flagged URLs: $e');
        urls = null;
      }
    }

    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      recipientId: json['recipientId'] ?? json['recipient_id'] ?? '',
      message: json['message'] ?? '',
      isMedia: json['isMedia'] ?? json['is_media'],
      timestamp: parsedTimestamp,
      viewed: json['viewed'] ?? false,
      classificationMessages: classifications,
      flaggedUrls: urls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'message': message,
      'isMedia': isMedia,
      'timestamp': timestamp.toIso8601String(),
      'viewed': viewed,
      'classification_messages':
          classificationMessages?.map((e) => e.toJson()).toList(),
      'flagged_urls': flaggedUrls,
    };
  }
}
