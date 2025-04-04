import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/authentication/controllers/auth_controller.dart';
import 'package:libbit_chat_app/navigation/ui/screens/navigation.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // For image picking

class AuthenticationFormWidget extends StatefulWidget {
  const AuthenticationFormWidget({super.key});

  @override
  State<AuthenticationFormWidget> createState() =>
      _AuthenticationFormWidgetState();
}

class _AuthenticationFormWidgetState extends State<AuthenticationFormWidget> {
  bool isLogin = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _profilePicturePath;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Method to pick profile picture
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profilePicturePath = image.path;
      });
    }
  }

  // Handle form submission
  Future<void> _handleSubmit() async {
    final authController = Provider.of<AuthController>(context, listen: false);

    if (isLogin) {
      // Handle login
      final success = await authController.handleLogin(
        _emailController.text,
        _passwordController.text,
        context,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
        );
      }
    } else {
      // Handle signup
      final success = await authController.handleSignUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        profilePicturePath: _profilePicturePath,
        context: context,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get reference to the auth controller
    final authController = Provider.of<AuthController>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Toggle between Login and Signup
        Row(
          children: [
            // Login toggler
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isLogin = true),
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          "Login",
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            color:
                                isLogin
                                    ? ColorConstants.highlightPrimary
                                    : ColorConstants.neutralMedium,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 2,
                      color:
                          isLogin
                              ? ColorConstants.highlightPrimary
                              : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),

            // Sign up toggler
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isLogin = false),
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          "Sign up",
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            color:
                                !isLogin
                                    ? ColorConstants.highlightPrimary
                                    : ColorConstants.neutralMedium,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 2,
                      color:
                          !isLogin
                              ? ColorConstants.highlightPrimary
                              : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 24),

        // Form Fields
        if (!isLogin)
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Name"),
          ),

        if (!isLogin) SizedBox(height: 16),

        if (!isLogin)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _pickImage,
              style: Theme.of(context).outlinedButtonTheme.style?.merge(
                OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  minimumSize: Size(0, 52),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _profilePicturePath != null
                        ? 'Change profile picture'
                        : 'Upload profile picture',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ColorConstants.highlightPrimary,
                    ),
                  ),
                  if (_profilePicturePath != null) ...[
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: FileImage(File(_profilePicturePath!)),
                    ),
                  ],
                ],
              ),
            ),
          ),

        if (!isLogin) SizedBox(height: 16),

        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: "Email"),
          keyboardType: TextInputType.emailAddress,
        ),

        SizedBox(height: 16),

        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: "Password"),
          obscureText: true,
        ),

        SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authController.isLoading ? null : _handleSubmit,
            style: Theme.of(context).elevatedButtonTheme.style?.merge(
              ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 24),
                minimumSize: Size(0, 52),
              ),
            ),
            child:
                authController.isLoading
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      isLogin ? 'Login' : 'Signup',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
          ),
        ),
      ],
    );
  }
}
