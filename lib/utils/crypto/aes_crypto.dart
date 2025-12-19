import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// AES 加密解密工具类
/// 支持 CBC 模式，PKCS7 填充
class AESCrypto {
  /// AES 加密（CBC模式，PKCS7填充）
  ///
  /// [key] 加密密钥（16、24或32字节）
  /// [iv] 初始化向量（16字节）
  /// [plaintext] 明文
  ///
  /// 返回 Base64 编码的密文
  static Future<String> encrypt(String key, String iv, String plaintext) async {
    try {
      // 验证密钥长度
      final keyBytes = utf8.encode(key);
      if (keyBytes.length != 16 && keyBytes.length != 24 && keyBytes.length != 32) {
        throw ArgumentError('密钥长度必须是16、24或32字节');
      }

      // 验证IV长度
      final ivBytes = utf8.encode(iv);
      if (ivBytes.length != 16) {
        throw ArgumentError('IV长度必须是16字节');
      }

      // 创建密钥参数
      final keyParameter = KeyParameter(Uint8List.fromList(keyBytes));

      // 创建IV参数
      final ivParameter = ParametersWithIV<KeyParameter>(
        keyParameter,
        Uint8List.fromList(ivBytes),
      );

      // 创建AES CBC加密器
      final encryptor = CBCBlockCipher(AESEngine());
      final paddedPlaintext = _pkcs7Pad(utf8.encode(plaintext));

      // 初始化加密器
      encryptor.init(
        true, // 加密模式
        ivParameter,
      );

      // 执行加密
      final cipherText = encryptor.process(Uint8List.fromList(paddedPlaintext));

      // 返回Base64编码
      return base64.encode(cipherText);
    } catch (e) {
      throw Exception('AES加密失败: $e');
    }
  }

  /// AES 解密（CBC模式，PKCS7填充）
  ///
  /// [key] 解密密钥（16、24或32字节）
  /// [iv] 初始化向量（16字节）
  /// [ciphertext] Base64 编码的密文
  ///
  /// 返回明文
  static Future<String> decrypt(String key, String iv, String ciphertext) async {
    try {
      // 验证密钥长度
      final keyBytes = utf8.encode(key);
      if (keyBytes.length != 16 && keyBytes.length != 24 && keyBytes.length != 32) {
        throw ArgumentError('密钥长度必须是16、24或32字节');
      }

      // 验证IV长度
      final ivBytes = utf8.encode(iv);
      if (ivBytes.length != 16) {
        throw ArgumentError('IV长度必须是16字节');
      }

      // 解码Base64
      final cipherBytes = base64.decode(ciphertext);

      // 创建密钥参数
      final keyParameter = KeyParameter(Uint8List.fromList(keyBytes));

      // 创建IV参数
      final ivParameter = ParametersWithIV<KeyParameter>(
        keyParameter,
        Uint8List.fromList(ivBytes),
      );

      // 创建AES CBC解密器
      final decryptor = CBCBlockCipher(AESEngine());

      // 初始化解密器
      decryptor.init(
        false, // 解密模式
        ivParameter,
      );

      // 执行解密
      final paddedPlaintext = decryptor.process(Uint8List.fromList(cipherBytes));

      // 移除PKCS7填充
      final plaintext = _pkcs7Unpad(paddedPlaintext);

      return utf8.decode(plaintext);
    } catch (e) {
      throw Exception('AES解密失败: $e');
    }
  }

  /// PKCS7 填充
  static List<int> _pkcs7Pad(List<int> data) {
    final blockSize = 16; // AES块大小
    final padding = blockSize - (data.length % blockSize);
    final padded = List<int>.from(data);
    for (var i = 0; i < padding; i++) {
      padded.add(padding);
    }
    return padded;
  }

  /// 移除 PKCS7 填充
  static List<int> _pkcs7Unpad(List<int> paddedData) {
    if (paddedData.isEmpty) {
      throw ArgumentError('数据为空');
    }

    final padding = paddedData.last;
    if (padding > 16 || padding == 0) {
      throw ArgumentError('无效的PKCS7填充');
    }

    // 验证填充是否正确
    for (var i = 0; i < padding; i++) {
      if (paddedData[paddedData.length - padding + i] != padding) {
        throw ArgumentError('PKCS7填充验证失败');
      }
    }

    return paddedData.sublist(0, paddedData.length - padding);
  }

  /// 生成随机密钥
  ///
  /// [length] 密钥长度（16、24或32，对应AES-128、192、256）
  static String generateKey({int length = 16}) {
    if (length != 16 && length != 24 && length != 32) {
      throw ArgumentError('密钥长度必须是16、24或32');
    }

    final random = Random.secure();
    final keyBytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return base64.encode(keyBytes);
  }

  /// 生成随机IV
  static String generateIV() {
    final random = Random.secure();
    final ivBytes = Uint8List(16); // AES块大小
    for (var i = 0; i < 16; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    return base64.encode(ivBytes);
  }

  /// 计算HMAC-SHA256
  static String calculateHMAC(String key, String data) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return base64.encode(digest.bytes);
  }
}