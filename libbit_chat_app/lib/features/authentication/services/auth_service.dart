import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libbit_chat_app/utils/constants/url_constants.dart';
import 'package:libbit_chat_app/utils/helpers/encryption.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import 'package:device_info_plus/device_info_plus.dart';

class AuthService {
  static const String API_URL =
      UrlConstants.apiUrl; // Replace with your backend URL
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  /// Get Device Token (Alternative to Firebase Messaging)
  // static Future<String?> getDeviceToken() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   if (Platform.isAndroid) {
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     return androidInfo.id;
  //   } else if (Platform.isIOS) {
  //     IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //     return iosInfo.identifierForVendor;
  //   }
  //   return null;
  // }

  /// Convert Image to Base64
  static Future<String?> convertImageToBase64(String? path) async {
    if (path == null) return null;

    try {
      final File imageFile = File(path);
      if (!await imageFile.exists()) return null;

      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Determine the image type (you may need to enhance this)
      String mimeType = "image/jpeg";
      if (path.toLowerCase().endsWith('.png')) mimeType = "image/png";

      // Return with the proper data URI format
      return "data:$mimeType;base64,$base64Image";
    } catch (e) {
      print("Error converting image: $e");
      return null;
    }
  }

  /// Save User Token
  static Future<void> saveUserToken(String token) async {
    await secureStorage.write(key: "userToken", value: token);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("userToken", token);
  }

  /// Get User Token
  static Future<String?> getUserToken() async {
    return await secureStorage.read(key: "userToken");
  }

  /// Delete User Token
  static Future<void> deleteUserToken() async {
    await secureStorage.delete(key: "userToken");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("userToken");
  }

  /// Login User
  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/log_users'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await saveUserToken(data["accessToken"]);
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["error"]};
      }
    } catch (error) {
      print("Error logging in: $error");
      return {"success": false, "message": "Network error"};
    }
  }

  /// Sign Up User
  static Future<Map<String, dynamic>> signUpUser({
    required String email,
    required String password,
    required String name,
    required String username,
    String? profilePicturePath,
    String? publicKey,
  }) async {
    try {
      // Generate keys using your custom Encryption class
      final keys = Encryption.generateECDHKeys();
      final privateKey = keys['privateKey'];
      final publicKey = keys['publicKey'];

      // final String? deviceToken = await getDeviceToken();
      final String? profilePictureBase64 = await convertImageToBase64(
        profilePicturePath,
      );
      final String currentDate = DateTime.now().toIso8601String();

      final requestBody = {
        "email": email,
        "password": password,
        "name": name,
        "username": username,
        "profile_picture": profilePictureBase64,
        "status": "active",
        "device_tokens": [], //deviceToken != null ? [deviceToken] : [],
        "last_seen": currentDate,
        "created_at": currentDate,
        "updated_at": currentDate,
        "public_key": publicKey,
      };

      final response = await http.post(
        Uri.parse('$API_URL/add_user'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await saveUserToken(data["accessToken"]);
        await secureStorage.write(key: "privateKey", value: privateKey);
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["error"]};
      }
    } catch (error) {
      print("Error signing up: $error");
      return {"success": false, "message": "Network error"};
    }
  }
}
