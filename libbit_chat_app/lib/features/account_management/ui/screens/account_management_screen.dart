import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/account_management/services/account_service.dart';
import 'package:libbit_chat_app/features/account_management/ui/screens/edit_account_screen.dart';
import 'package:libbit_chat_app/features/authentication/ui/screens/authentication_screen.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';
import 'package:provider/provider.dart';
import 'package:libbit_chat_app/features/account_management/controllers/account_controller.dart';

class AccountManagementScreen extends StatelessWidget {
  static const String routeName = '/account-management';

  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountController(),
      child: const _AccountManagementContent(),
    );
  }
}

class _AccountManagementContent extends StatelessWidget {
  const _AccountManagementContent();

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Logout'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldLogout) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Logging out...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            );
          },
        );

        // Perform logout
        await AccountService.clearStorage();

        // Close loading dialog and navigate to login screen
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => AuthenticationScreen()),
          );
        }
      } catch (e) {
        // Close loading dialog if open
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountController = Provider.of<AccountController>(context);
    final user = accountController.currentUser;
    final theme = Theme.of(context);

    if (accountController.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Not logged in'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (ctx) => AuthenticationScreen()),
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('menu')),
      body: RefreshIndicator(
        onRefresh: accountController.refreshUserData,
        color: Theme.of(context).primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage:
                          user.profilePicture != null &&
                                  user.profilePicture!.isNotEmpty
                              ? NetworkImage(user.profilePicture!)
                              : null,
                      child:
                          user.profilePicture == null ||
                                  user.profilePicture!.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                    ),

                    const SizedBox(width: 16.0),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: theme.textTheme.headlineSmall,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: ColorConstants.neutralMedium),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(
                height: 16.0,
                indent: 8.0,
                endIndent: 8.0,
                color: ColorConstants.neutralMedium.withAlpha(100),
              ),

              // Account Management Card
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditAccountScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 24.0,
                        color: ColorConstants.neutralDark,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Account management',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ColorConstants.neutralDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              InkWell(
                onTap: () => _handleLogout(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 24.0,
                        color: ColorConstants.neutralDark,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Logout',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ColorConstants.neutralDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (accountController.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Text(
                    accountController.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
