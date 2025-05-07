import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/account_management/services/account_service.dart';
import 'package:libbit_chat_app/features/account_management/ui/screens/edit_account_screen.dart';
import 'package:libbit_chat_app/features/authentication/ui/screens/authentication_screen.dart';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
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
      appBar: AppBar(
        title: const Text('Account Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: accountController.refreshUserData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: accountController.refreshUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    user.profilePicture != null &&
                            user.profilePicture!.isNotEmpty
                        ? NetworkImage(user.profilePicture!)
                        : null,
                child:
                    user.profilePicture == null || user.profilePicture!.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
              ),
              const SizedBox(height: 16),

              // Username and email
              Text(user.username, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(user.email, style: theme.textTheme.bodyLarge),

              const SizedBox(height: 32),

              // Account Management Card
              Card(
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Account'),
                  subtitle: const Text(
                    'Change username, email, password or profile picture',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditAccountScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Logout Card
              Card(
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  subtitle: const Text('Sign out from your account'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _handleLogout(context),
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
