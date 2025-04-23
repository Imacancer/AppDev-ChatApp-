import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libbit_chat_app/features/authentication/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool isLoading = false;
  String? errorMessage;

  // User data fields
  String? userId;
  String? name;
  String? username;
  String? email;
  String? profilePicture;

  // Set loading state
  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  // Handle user login
  Future<bool> handleLogin(
    String email,
    String password,
    BuildContext context,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      _showAlert(context, "Error", "Please enter both email and password.");
      return false;
    }

    setLoading(true);
    try {
      final result = await AuthService.loginUser(email, password);

      if (result['success']) {
        // Store user data in secure storage
        final userData = {
          'userId': result['data']['user']['userId'],
          'name': result['data']['user']['name'],
          'username': result['data']['user']['username'],
          'email': result['data']['user']['email'],
          'profilePicture': result['data']['user']['profilePicture'],
        };

        await _secureStorage.write(
          key: "userData",
          value: jsonEncode(userData),
        );

        // Update controller state with user data
        userId = userData['userId'];
        name = userData['name'];
        username = userData['username'];
        email = userData['email'];
        profilePicture = userData['profilePicture'];

        setLoading(false);
        return true;
      } else {
        _showAlert(
          context,
          "Login Failed",
          result['message'] ?? "Unknown error",
        );
        setLoading(false);
        return false;
      }
    } catch (error) {
      debugPrint("Error during login: $error");
      _showAlert(context, "Error", "An unexpected error occurred during login");
      setLoading(false);
      return false;
    }
  }

  // Handle user signup
  Future<bool> handleSignUp({
    required String email,
    required String password,
    required String name,
    String? profilePicturePath,
    required BuildContext context,
  }) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showAlert(context, "Error", "Please fill in all fields.");
      return false;
    }

    setLoading(true);
    try {
      // Generate username from email if not provided
      var username = email.split("@")[0];

      final result = await AuthService.signUpUser(
        email: email,
        password: password,
        name: name,
        username: username,
        profilePicturePath: profilePicturePath,
      );

      if (result['success']) {
        // Store user data in secure storage
        final userData = {
          'userId': result['data']['user']['userId'],
          'name': result['data']['user']['name'],
          'username': result['data']['user']['username'],
          'email': result['data']['user']['email'],
          'profilePicture': result['data']['user']['profilePicture'],
        };

        await _secureStorage.write(
          key: "userData",
          value: jsonEncode(userData),
        );

        // Update controller state with user data
        userId = userData['userId'];
        name = userData['name'];
        username = userData['username'];
        email = userData['email'];
        profilePicture = userData['profilePicture'];

        setLoading(false);
        return true;
      } else {
        _showAlert(
          context,
          "Sign Up Failed",
          result['message'] ?? "Unknown error",
        );
        setLoading(false);
        return false;
      }
    } catch (error) {
      debugPrint("Error during sign up: $error");
      _showAlert(
        context,
        "Error",
        "An unexpected error occurred during sign up",
      );
      setLoading(false);
      return false;
    }
  }

  // Get user data from storage
  Future<bool> loadUserData() async {
    try {
      final userDataString = await _secureStorage.read(key: "userData");
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        userId = userData['userId'];
        name = userData['name'];
        username = userData['username'];
        email = userData['email'];
        profilePicture = userData['profilePicture'];
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      debugPrint("Error loading user data: $error");
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await AuthService.deleteUserToken();
      await _secureStorage.delete(key: "userData");

      // Clear controller state
      userId = null;
      name = null;
      username = null;
      email = null;
      profilePicture = null;

      notifyListeners();
    } catch (error) {
      debugPrint("Error during logout: $error");
    }
  }

  // Show alert dialog
  void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
