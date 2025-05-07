import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:libbit_chat_app/utils/constants/url_constants.dart';
import 'package:libbit_chat_app/features/chat/models/user_model.dart';

class AccountService {
  static const String API_URL = UrlConstants.apiUrl;
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  /// Get authentication token based on platform
  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userToken');
    } else {
      return await secureStorage.read(key: 'userToken');
    }
  }

  // Platform-specific storage clearing for logout
  static Future<void> clearStorage() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken');
      await prefs.remove('userData');
    } else {
      await secureStorage.delete(key: 'userToken');
      await secureStorage.delete(key: 'userData');
    }
  }

  /// Get current user data
  static Future<User?> getCurrentUser() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final data = prefs.getString('userData');
        return data != null ? User.fromJson(jsonDecode(data)) : null;
      } else {
        final data = await secureStorage.read(key: 'userData');
        return data != null ? User.fromJson(jsonDecode(data)) : null;
      }
    } catch (e) {
      debugPrint("Error getting current user: $e");
      return null;
    }
  }

  /// Save user data
  static Future<void> saveUserData(User user) async {
    final userData = jsonEncode(user.toJson());

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', userData);
    } else {
      await secureStorage.write(key: 'userData', value: userData);
    }
  }

  /// Update user account information
  static Future<Map<String, dynamic>> updateUserAccount({
    required String userId,
    String? username,
    String? email,
    String? password,
    String? profilePicturePath,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {"success": false, "message": "Authentication token not found"};
      }

      // Get current user
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {"success": false, "message": "Current user not found"};
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$API_URL/update_user/$userId'),
      );

      // Add authorization header
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Only add fields if they differ from current values
      if (username != null && username != currentUser.username) {
        request.fields['username'] = username;
      }

      if (email != null && email != currentUser.email) {
        request.fields['email'] = email;
      }

      if (password != null) {
        request.fields['password'] = password;
      }

      // Add profile picture if provided
      if (profilePicturePath != null) {
        final file = File(profilePicturePath);
        final filename = profilePicturePath.split('/').last;
        final contentType =
            filename.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg';

        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            file.path,
            filename: filename,
            contentType:
                contentType == 'image/png'
                    ? MediaType('image', 'png')
                    : MediaType('image', 'jpeg'),
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update local user data
        if (responseData['user'] != null) {
          final updatedUser = User.fromJson(responseData['user']);
          await saveUserData(updatedUser);
        }

        return {
          "success": true,
          "data": responseData,
          "message": responseData['message'] ?? "Account updated successfully",
        };
      } else {
        return {
          "success": false,
          "message": responseData['error'] ?? "Failed to update user account",
        };
      }
    } catch (error) {
      debugPrint("Error updating user account: $error");
      String errorMessage =
          error is SocketException
              ? "Network error"
              : "An unexpected error occurred";

      return {"success": false, "message": errorMessage};
    }
  }

  /// Update username
  static Future<Map<String, dynamic>> updateUsername({
    required String userId,
    required String username,
  }) async {
    return await updateUserAccount(userId: userId, username: username);
  }

  /// Update email
  static Future<Map<String, dynamic>> updateEmail({
    required String userId,
    required String email,
  }) async {
    return await updateUserAccount(userId: userId, email: email);
  }

  /// Update password
  static Future<Map<String, dynamic>> updatePassword({
    required String userId,
    required String password,
  }) async {
    return await updateUserAccount(userId: userId, password: password);
  }

  /// Update profile picture
  static Future<Map<String, dynamic>> updateProfilePicture({
    required String userId,
    required String profilePicturePath,
  }) async {
    return await updateUserAccount(
      userId: userId,
      profilePicturePath: profilePicturePath,
    );
  }

  /// Full account edit - mimics the React Native implementation
  static Future<Map<String, dynamic>> editAccount({
    required String userId,
    required String currentUsername,
    required String currentEmail,
    String? newUsername,
    String? newEmail,
    String? newPassword,
    String? confirmPassword,
    String? newProfilePicture,
  }) async {
    // Validate passwords match
    if (newPassword != null &&
        confirmPassword != null &&
        newPassword.isNotEmpty &&
        newPassword != confirmPassword) {
      return {"success": false, "message": "Passwords do not match!"};
    }

    try {
      final token = await getToken();
      final currentUser = await getCurrentUser();
      if (token == null || currentUser == null) {
        return {"success": false, "message": "Authentication required"};
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$API_URL/update_user/$userId'),
      );

      // Add authorization header
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Add fields only if they've changed
      if (newUsername != null && newUsername != currentUsername) {
        request.fields['username'] = newUsername;
      }

      if (newEmail != null && newEmail != currentEmail) {
        request.fields['email'] = newEmail;
      }

      if (newPassword != null && newPassword.isNotEmpty) {
        request.fields['password'] = newPassword;
      }

      // Add profile picture if provided
      if (newProfilePicture != null) {
        final file = File(newProfilePicture);
        final filename = newProfilePicture.split('/').last;
        final contentType =
            filename.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg';

        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            file.path,
            filename: filename,
            contentType:
                contentType == 'image/png'
                    ? MediaType('image', 'png')
                    : MediaType('image', 'jpeg'),
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update local user data
        if (responseData['user'] != null) {
          final updatedUser = User.fromJson(responseData['user']);
          await saveUserData(updatedUser);
        }

        return {
          "success": true,
          "data": responseData,
          "user": responseData['user'],
          "message": "Account updated successfully",
        };
      } else {
        return {
          "success": false,
          "message": responseData['error'] ?? "Failed to update account",
        };
      }
    } catch (error) {
      debugPrint("Error editing account: $error");
      return {"success": false, "message": "Failed to update account"};
    }
  }
}
