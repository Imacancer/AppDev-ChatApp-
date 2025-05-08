import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class MessageInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final Function() onAttachmentPressed;
  final String? selectedMedia;
  final VoidCallback onClearMedia;
  final FocusNode? focusNode;

  const MessageInputWidget({
    super.key,
    required this.controller,
    required this.onSendPressed,
    required this.onAttachmentPressed,
    this.selectedMedia,
    required this.onClearMedia,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    backgroundColor: ColorConstants.neutralMedium,
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(24, 24),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.photo,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () => onAttachmentPressed(),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Messaege',
                    hintStyle: TextStyle(color: ColorConstants.neutralMedium),
                    border: InputBorder.none,
                  ),
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSendPressed(),
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
