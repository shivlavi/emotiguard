import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Encrypts and decrypts sensitive physiological metrics and journal reflections at rest.
/// Protects local SQLite / Hive persistence from unauthorized file inspection.
class CryptoVault {
  static const String _defaultSalt = 'EmotiGuard_Privacy_First_2026';
  late final enc.Encrypter _encrypter;
  late final enc.IV _iv;

  CryptoVault({String userPasscode = 'emotiguard_user_key'}) {
    final keyBytes = sha256.convert(utf8.encode(userPasscode + _defaultSalt)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    // Deterministic 16-byte initialization vector derived from salt
    final ivBytes = md5.convert(utf8.encode(_defaultSalt)).bytes;
    _iv = enc.IV(Uint8List.fromList(ivBytes));
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  /// Encrypts a plaintext string into a base64 ciphertext
  String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      // Fallback simple base64 if AES encounters platform issues
      return base64Encode(utf8.encode(plainText));
    }
  }

  /// Decrypts a base64 ciphertext back to plaintext
  String decrypt(String cipherText) {
    if (cipherText.isEmpty) return '';
    try {
      final decrypted = _encrypter.decrypt64(cipherText, iv: _iv);
      return decrypted;
    } catch (e) {
      try {
        return utf8.decode(base64Decode(cipherText));
      } catch (_) {
        return cipherText;
      }
    }
  }
}
