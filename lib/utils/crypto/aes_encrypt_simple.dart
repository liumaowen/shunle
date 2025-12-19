import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// 简化的 AES 加密解密工具类（使用 encrypt 包）
class AesEncryptSimple {
  /// AES 加密（CBC模式，PKCS7填充）
  static Future<String> encrypt(String key, String iv, String plaintext) async {
    try {
      // 将字符串转换为 Uint8List
      final keyBytes = Uint8List.fromList(utf8.encode(key));
      final ivBytes = Uint8List.fromList(utf8.encode(iv));
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

      // 创建密钥和IV
      final keyParameter = Key(keyBytes);
      final ivParameter = IV(ivBytes);

      // 创建加密器
      final encrypter = Encrypter(AES(keyParameter, mode: AESMode.cbc));

      // 执行加密
      final encrypted = encrypter.encryptBytes(
        plaintextBytes,
        iv: ivParameter,
      );

      // 返回 Base64 编码
      return base64.encode(encrypted.bytes);
    } catch (e) {
      throw Exception('AES加密失败: $e');
    }
  }

  /// AES 解密（CBC模式，PKCS7填充）
  static Future<String> decrypt(String key, String iv, String ciphertext) async {
    try {
      // 解码 Base64
      final cipherBytes = base64.decode(ciphertext);

      // 将字符串转换为 Uint8List
      final keyBytes = Uint8List.fromList(utf8.encode(key));
      final ivBytes = Uint8List.fromList(utf8.encode(iv));

      // 创建密钥和IV
      final keyParameter = Key(keyBytes);
      final ivParameter = IV(ivBytes);

      // 创建解密器
      final encrypter = Encrypter(AES(keyParameter, mode: AESMode.cbc));

      // 执行解密
      final decryptedBytes = encrypter.decryptBytes(
        Encrypted(cipherBytes),
        iv: ivParameter,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw Exception('AES解密失败: $e');
    }
  }

  /// 生成随机密钥
  static String generateKey({int length = 16}) {
    final key = Key.fromSecureRandom(length);
    return base64.encode(key.bytes);
  }

  /// 生成随机IV
  static String generateIV() {
    final iv = IV.fromSecureRandom(16);
    return base64.encode(iv.bytes);
  }
}