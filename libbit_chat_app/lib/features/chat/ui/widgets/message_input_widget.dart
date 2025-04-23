import 'dart:io';
import 'package:flutter/material.dart';

class MessageInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final VoidCallback onAttachmentPressed;
  final String? selectedMedia;
  final VoidCallback onClearMedia;

  const MessageInputWidget({
    super.key,
    required this.controller,
    required this.onSendPressed,
    required this.onAttachmentPressed,
    this.selectedMedia,
    required this.onClearMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedMedia != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(File(selectedMedia!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClearMedia,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(24, 24),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attachment),
                onPressed: onAttachmentPressed,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                  ),
                  minLines: 1,
                  maxLines: 5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                onPressed: onSendPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
