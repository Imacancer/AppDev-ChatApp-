import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/pointycastle.dart';
import 'dart:math';

class Encryption {
  // Generate ECDH keys (simulated with a random private key)
  static Map<String, String> generateECDHKeys() {
    // In a real-world scenario, you should use ECDH key generation from pointycastle
    final random = Random.secure();
    final privateKey = List<int>.generate(32, (_) => random.nextInt(256));
    final publicKey = _hash(privateKey);

    return {
      'privateKey': _bytesToHex(privateKey),
      'publicKey': _bytesToHex(publicKey),
    };
  }

  // Simulate ECDH public key generation via a hash (SHA256)
  static List<int> _hash(List<int> data) {
    final digest = Digest("SHA-256");
    return digest.process(Uint8List.fromList(data));
  }

  // Convert bytes to Hex
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  // Encrypt message using AES
  static String encryptMessage(String message, String secret) {
    final key = encrypt.Key.fromUtf8(
      secret.padRight(32, ' '),
    ); // Ensure key is 32 bytes
    final iv = encrypt.IV.fromLength(16); // 16 bytes IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(message, iv: iv);
    return encrypted.base64;
  }

  // Decrypt message using AES
  static String decryptMessage(String encryptedMessage, String secret) {
    final key = encrypt.Key.fromUtf8(
      secret.padRight(32, ' '),
    ); // Ensure key is 32 bytes
    final iv = encrypt.IV.fromLength(16); // 16 bytes IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final decrypted = encrypter.decrypt64(encryptedMessage, iv: iv);
    return decrypted;
  }
}
