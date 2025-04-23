import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoIcons
import 'package:libbit_chat_app/features/chat/models/chat_user_model.dart';
import 'package:libbit_chat_app/features/chat/ui/screens/chat_screen.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';
import 'package:provider/provider.dart';
import 'package:libbit_chat_app/features/chat/ui/widgets/custom_card_widget.dart';
import 'package:libbit_chat_app/features/chat/controllers/chat_list_controller.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize the data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatListController>(context, listen: false).initializeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        // Clear search when hiding the search bar
        _searchController.clear();
        Provider.of<ChatListController>(
          context,
          listen: false,
        ).handleSearch('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('libbit link'),
        actions: [
          IconButton(
            onPressed: _toggleSearchBar,
            icon: Icon(
              !_showSearchBar
                  ? CupertinoIcons.create_solid
                  : CupertinoIcons.clear,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            if (_showSearchBar)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search users',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                  ),
                  onChanged: (value) {
                    Provider.of<ChatListController>(
                      context,
                      listen: false,
                    ).handleSearch(value);
                  },
                ),
              ),

            Consumer<ChatListController>(
              builder: (context, controller, _) {
                return Expanded(child: _buildBody(controller));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ChatListController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.searchQuery.isNotEmpty) {
      return _buildSearchResults(controller);
    }

    if (controller.chatUsers.isEmpty) {
      return Center(
        child: Text(
          'No chats found',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: ColorConstants.neutralMedium),
        ),
      );
    }

    return _buildChatList(controller);
  }

  Widget _buildChatList(ChatListController controller) {
    return ListView.builder(
      itemCount: controller.chatUsers.length,
      itemBuilder: (context, index) {
        final chatUser = controller.chatUsers[index];
        return CustomCardWidget(
          chatUser: chatUser,
          onTap: () async {
            await controller.handleChatPress(
              chatUser,
            ); // Mark messages as viewed

            // Navigate to chat screen with the selected user
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatScreen(
                        chatUser: chatUser,
                        currentUser: controller.currentUser!,
                      ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSearchResults(ChatListController controller) {
    if (controller.searchResults.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: ColorConstants.neutralMedium),
        ),
      );
    }

    return ListView.builder(
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final user = controller.searchResults[index];
        // Create a temporary chat user for display
        final tempChatUser = ChatUser(
          id: user.userId,
          name: user.name,
          avatar: user.profilePicture ?? 'assets/images/default_avatar.png',
          lastMessage: '',
          lastMessageId: '',
          unreadCount: 0,
          timestamp: '',
          viewed: true,
          lastMessageSenderName: '',
        );

        return CustomCardWidget(
          chatUser: tempChatUser,
          onTap: () async {
            await controller.fetchUserDetails(user.userId);

            // Navigate to chat screen with the selected user
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatScreen(
                        chatUser: tempChatUser,
                        currentUser: controller.currentUser!,
                      ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
