import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/account_management/services/account_service.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';

class AccountController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isEditing = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEditing => _isEditing;

  // Constructor - Load current user on initialization
  AccountController() {
    _loadCurrentUser();
  }

  // Load current user from storage
  Future<void> _loadCurrentUser() async {
    _setLoading(true);
    try {
      _currentUser = await AccountService.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = "Failed to load user data: $e";
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Toggle editing state
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    await _loadCurrentUser();
  }

  // Update username
  Future<bool> updateUsername(String newUsername) async {
    if (_currentUser == null) {
      _setError("No user logged in");
      return false;
    }

    _setLoading(true);

    try {
      final result = await AccountService.updateUsername(
        userId: _currentUser!.userId,
        username: newUsername,
      );

      if (result['success']) {
        await refreshUserData();
        _setError(null);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError("Failed to update username: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update email
  Future<bool> updateEmail(String newEmail) async {
    if (_currentUser == null) {
      _setError("No user logged in");
      return false;
    }

    _setLoading(true);

    try {
      final result = await AccountService.updateEmail(
        userId: _currentUser!.userId,
        email: newEmail,
      );

      if (result['success']) {
        await refreshUserData();
        _setError(null);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError("Failed to update email: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    if (_currentUser == null) {
      _setError("No user logged in");
      return false;
    }

    _setLoading(true);

    try {
      final result = await AccountService.updatePassword(
        userId: _currentUser!.userId,
        password: newPassword,
      );

      if (result['success']) {
        _setError(null);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError("Failed to update password: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile picture
  Future<bool> updateProfilePicture(String profilePicturePath) async {
    if (_currentUser == null) {
      _setError("No user logged in");
      return false;
    }

    _setLoading(true);

    try {
      final result = await AccountService.updateProfilePicture(
        userId: _currentUser!.userId,
        profilePicturePath: profilePicturePath,
      );

      if (result['success']) {
        await refreshUserData();
        _setError(null);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError("Failed to update profile picture: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete account update
  Future<bool> updateAccount({
    String? newUsername,
    String? newEmail,
    String? newPassword,
    String? confirmPassword,
    String? newProfilePicture,
  }) async {
    if (_currentUser == null) {
      _setError("No user logged in");
      return false;
    }

    // Validate passwords match if provided
    if (newPassword != null &&
        confirmPassword != null &&
        newPassword.isNotEmpty &&
        newPassword != confirmPassword) {
      _setError("Passwords do not match");
      return false;
    }

    _setLoading(true);

    try {
      final result = await AccountService.editAccount(
        userId: _currentUser!.userId,
        currentUsername: _currentUser!.username,
        currentEmail: _currentUser!.email,
        newUsername: newUsername,
        newEmail: newEmail,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        newProfilePicture: newProfilePicture,
      );

      if (result['success']) {
        await refreshUserData();
        _setError(null);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError("Failed to update account: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Validate new username
  bool isValidUsername(String username) {
    // Implement username validation logic here
    // Example: minimum length, no special characters, etc.
    return username.length >= 3 &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  // Validate email
  bool isValidEmail(String email) {
    // Basic email validation
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  // Validate password strength
  bool isStrongPassword(String password) {
    // Password should be at least 8 characters and include letters and numbers
    return password.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }
}
