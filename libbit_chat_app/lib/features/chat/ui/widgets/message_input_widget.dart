import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MessageInputWidgetState createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final FocusNode _focusNode = FocusNode();
  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          if (!isFocused) ...[
            // Hide icons when focused
            IconButton(
              onPressed: () {},
              icon: Icon(
                CupertinoIcons.book_circle_fill,
                color: ColorConstants.highlightPrimary,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.image),
              color: ColorConstants.highlightPrimary,
            ),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                focusNode: _focusNode, // Attach focus node
                decoration: InputDecoration(
                  hintText: "Message",
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: ColorConstants.neutralLight,
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 2,
                minLines: 1,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.send),
            color: ColorConstants.highlightPrimary,
          ),
        ],
      ),
    );
  }
}
