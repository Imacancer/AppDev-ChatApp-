import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libbit_chat_app/features/account_management/controllers/account_controller.dart';

class EditAccountScreen extends StatefulWidget {
  static const String routeName = '/edit-account';

  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  File? _selectedProfileImage;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final accountController = Provider.of<AccountController>(
      context,
      listen: false,
    );
    final user = accountController.currentUser;

    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Method to unfocus and dismiss keyboard
  void _unfocusKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedProfileImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final accountController = Provider.of<AccountController>(
      context,
      listen: false,
    );
    final user = accountController.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found'),
          backgroundColor: ColorConstants.supportError,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String newUsername = _usernameController.text;
      final String newEmail = _emailController.text;
      final String newPassword = _passwordController.text;
      final String confirmPassword = _confirmPasswordController.text;
      final String? profilePicturePath = _selectedProfileImage?.path;

      // Check if anything has changed
      final bool usernameChanged = newUsername != user.username;
      final bool emailChanged = newEmail != user.email;
      final bool passwordChanged = newPassword.isNotEmpty;
      final bool profilePictureChanged = profilePicturePath != null;

      if (!usernameChanged &&
          !emailChanged &&
          !passwordChanged &&
          !profilePictureChanged) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No changes detected')));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update account
      final result = await accountController.updateAccount(
        newUsername: usernameChanged ? newUsername : null,
        newEmail: emailChanged ? newEmail : null,
        newPassword: passwordChanged ? newPassword : null,
        confirmPassword: passwordChanged ? confirmPassword : null,
        newProfilePicture: profilePictureChanged ? profilePicturePath : null,
      );

      if (result) {
        // Clear password fields
        _passwordController.clear();
        _confirmPasswordController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account updated successfully'),
              backgroundColor: ColorConstants.highlightPrimary,
            ),
          );
        }

        // Reset selected profile image
        setState(() {
          _selectedProfileImage = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                accountController.error ?? 'Failed to update account',
              ),
              backgroundColor: ColorConstants.supportError,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: ColorConstants.supportError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountController = Provider.of<AccountController>(context);
    final user = accountController.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(),
          // Wrap body content with GestureDetector to dismiss keyboard when tapping outside
          body: GestureDetector(
            onTap: _unfocusKeyboard,
            // Important: This ensures the gesture detector doesn't block other widgets
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                _selectedProfileImage != null
                                    ? FileImage(_selectedProfileImage!)
                                    : (user.profilePicture != null &&
                                            user.profilePicture!.isNotEmpty
                                        ? NetworkImage(user.profilePicture!)
                                            as ImageProvider
                                        : const AssetImage(
                                          'assets/images/temporary-profile-placeholder-1.jpg',
                                        )),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.camera_rotate_fill,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username is required';
                        }
                        if (!accountController.isValidUsername(value)) {
                          return 'Username must be at least 3 characters long and contain only letters, numbers, and underscores';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!accountController.isValidEmail(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _hidePassword,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            !accountController.isStrongPassword(value)) {
                          return 'Password must be at least 8 characters and include letters and numbers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hideConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _hideConfirmPassword = !_hideConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _hideConfirmPassword,
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty &&
                            value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: Theme.of(
                          context,
                        ).elevatedButtonTheme.style?.merge(
                          ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            minimumSize: const Size(0, 52),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'Save changes',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                      ),
                    ),

                    // Error message
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
          ),
        ),
      ],
    );
  }
}
