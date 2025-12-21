import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

/// 简化的 AES 加密解密工具类（使用 encrypt 包）
class AesEncryptSimple {
  // AES 加密解密配置
  static const String _aesKey = 'gFzviOY0zOxVq1cu';
  static const String _aesIv = 'ZmA0Osl677UdSrl0';

  /// AES 加密（CBC模式，PKCS7填充）
  static String encrypt(String plaintext) {
    try {
      // 将字符串转换为 Uint8List
      final keyBytes = Uint8List.fromList(utf8.encode(_aesKey));
      final ivBytes = Uint8List.fromList(utf8.encode(_aesIv));
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

      // 创建密钥和IV
      final keyParameter = Key(keyBytes);
      final ivParameter = IV(ivBytes);

      // 创建加密器
      final encrypter = Encrypter(AES(keyParameter, mode: AESMode.cbc));

      // 执行加密
      final encrypted = encrypter.encryptBytes(plaintextBytes, iv: ivParameter);

      // 返回 Base64 编码
      return base64.encode(encrypted.bytes);
    } catch (e) {
      throw Exception('AES加密失败: $e');
    }
  }

  /// AES 解密（CBC模式，PKCS7填充）
  static String decrypt(String ciphertext) {
    try {
      // 解码 Base64
      final cipherBytes = base64.decode(ciphertext);

      // 将字符串转换为 Uint8List
      final keyBytes = Uint8List.fromList(utf8.encode(_aesKey));
      final ivBytes = Uint8List.fromList(utf8.encode(_aesIv));

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

  /// 生成随机IV
  static String generateIV() {
    final iv = IV.fromSecureRandom(16);
    return base64.encode(iv.bytes);
  }

  /// 获取m3u8
  static String getm3u8(
    String baseapi,
    String path, {
    String key = 'wB760Vqpk76oRSVA1TNz',
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final r = (timestamp / 1000).floor().toString();
    final sign = creatMD5('$key/$path$r').toLowerCase();
    final hp = path.contains('http') ? path : '$baseapi$path';
    return '$hp?sign=$sign&t=$r';
  }

  static String creatMD5(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 解密图片
  static Future<Uint8List> fetchAndDecrypt(String url) async {
    try {
      // 1. 从URL中提取文件信息
      // final fileInfo = _extractFileInfo(url);

      // 2. 发起GET请求获取加密数据
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      // 3. 获取字节数据
      final encryptedBytes = response.bodyBytes;
      // 4. 解密数据
      Uint8List decryptedData;
      final dataString = utf8.decode(encryptedBytes, allowMalformed: true);

      if (_isBase64(dataString)) {
        decryptedData = _decryptBase64Data(dataString);
      } else {
        final base64String = base64Encode(encryptedBytes);
        decryptedData = _decryptBase64Data(base64String);
      }
      return decryptedData;
    } catch (e) {
      rethrow;
    }
  }

  // 提取文件信息（对应前端的 extractFileInfo）
  static FileInfo _extractFileInfo(String url) {
    final fileName = _extractFileName(url);
    final extension = path.extension(fileName).toLowerCase();

    return FileInfo(fileName: fileName, mimeType: _getMimeType(extension));
  }

  // 从URL提取文件名
  static String _extractFileName(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty ? pathSegments.last : 'downloaded_file';
  }

  // 获取MIME类型（对应前端的 getMimeType）
  static String _getMimeType(String extension) {
    final mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.ico': 'image/x-icon',
      '.mp4': 'video/mp4',
      '.flv': 'video/x-flv',
      '.webm': 'video/webm',
      '.mov': 'video/quicktime',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/x-wav',
      '.exe': 'application/octet-stream',
      '.apk': 'application/vnd.android.package-archive',
      '.zip': 'application/zip',
      '.gz': 'application/gzip',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  // 检查是否是Base64字符串（对应前端的 isBase64）
  static bool _isBase64(String input) {
    try {
      final decoded = base64Decode(input);
      final reencoded = base64Encode(decoded);
      return reencoded == input;
    } catch (e) {
      return false;
    }
  }

  // 解密Base64数据（对应前端的 decryptBase64Data）
  static Uint8List _decryptBase64Data(String base64Str) {
    // 1. 解密AES数据
    final decrypted = decrypt(base64Str);

    // 2. 将解密后的Base64字符串转换为字节数组
    final bytes = base64Decode(decrypted);

    return Uint8List.fromList(bytes);
  }
}

// 文件信息类
class FileInfo {
  final String fileName;
  final String mimeType;

  FileInfo({required this.fileName, required this.mimeType});
}
