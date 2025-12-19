import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'aes_crypto.dart';
import 'hash_utils.dart';
import 'uuid_utils.dart';
import 'm3u8_utils.dart';
import '../date_utils.dart';

/// Crypto 工具类 - 提供统一的加密解密、哈希、UUID 等功能入口
class CryptoUtils {
  // AES 加密解密配置
  static const String _aesKey = 'gFzviOY0zOxVq1cu';
  static const String _aesIv = 'ZmA0Osl677UdSrl0';

  /// AES 加密（CBC模式，PKCS7填充）
  static Future<String> aesEncrypt(String plaintext) async {
    return await AESCrypto.encrypt(_aesKey, _aesIv, plaintext);
  }

  /// AES 解密（CBC模式，PKCS7填充）
  static Future<String> aesDecrypt(String ciphertext) async {
    return await AESCrypto.decrypt(_aesKey, _aesIv, ciphertext);
  }

  /// AES 解密（使用自定义密钥和IV）
  static Future<String> aesDecryptKey(String ciphertext, String key, String iv) async {
    return await AESCrypto.decrypt(key, iv, ciphertext);
  }

  /// MD5 哈希
  static String md5(String input) {
    return HashUtils.md5(input);
  }

  /// SHA256 哈希
  static String sha256(String input) {
    return HashUtils.sha256(input);
  }

  /// SHA1 哈希
  static String sha1(String input) {
    return HashUtils.sha1(input);
  }

  /// UUID v4 生成
  static String generateUUID() {
    return UUIDUtils.generateV4();
  }

  /// Base64 编码
  static String base64Encode(String input) {
    return base64.encode(utf8.encode(input));
  }

  /// Base64 解码
  static String base64Decode(String input) {
    return utf8.decode(base64.decode(input));
  }

  /// 生成随机字符串
  static String generateRandomString({
    int length = 16,
    bool includeNumbers = true,
    bool includeUpper = true,
    bool includeLower = true,
    bool includeSymbols = false,
  }) {
    const numbers = '0123456789';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeNumbers) chars += numbers;
    if (includeUpper) chars += upper;
    if (includeLower) chars += lower;
    if (includeSymbols) chars += symbols;

    if (chars.isEmpty) {
      throw ArgumentError('至少需要选择一种字符类型');
    }

    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// 生成时间戳字符串
  static String generateTimestamp({int? millisecondsSinceEpoch}) {
    final timestamp = millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    return timestamp.toString();
  }

  /// 格式化日期
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    return DateUtils.format(date, format: format);
  }

  /// 从日期字符串获取时间戳
  static int? getTimestampFromDateString(String dateString, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    return DateUtils.parseToTimestamp(dateString, format: format);
  }

  /// 生成 M3U8 签名 URL
  static String generateM3U8Url({
    required String baseUrl,
    required String path,
    String salt = 'wB760Vqpk76oRSVA1TNz',
  }) {
    return M3U8Utils.generateSignedUrl(
      baseUrl: baseUrl,
      path: path,
      salt: salt,
    );
  }

  /// 验证 M3U8 URL 签名
  static bool validateM3U8Signature(String url, {String salt = 'wB760Vqpk76oRSVA1TNz'}) {
    return M3U8Utils.validateSignature(url, salt: salt);
  }

  /// HMAC 签名
  static String generateHMAC(String key, String data, {String algorithm = 'sha256'}) {
    switch (algorithm) {
      case 'sha256':
        return HashUtils.hmacSha256(key, data);
      case 'sha1':
        return HashUtils.hmacSha1(key, data);
      case 'md5':
        return HashUtils.hmacMd5(key, data);
      default:
        throw ArgumentError('不支持的哈希算法: $algorithm');
    }
  }

  /// 生成短 ID（基于时间戳和随机数）
  static String generateShortId({int length = 8}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = generateRandomString(length: length, includeSymbols: false);
    return (timestamp + random).substring(0, length);
  }

  /// 检查字符串是否为 Base64 格式
  static bool isBase64(String input) {
    try {
      base64.decode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// URL 编码
  static String urlEncode(String input) {
    return Uri.encodeComponent(input);
  }

  /// URL 解码
  static String urlDecode(String input) {
    return Uri.decodeComponent(input);
  }

  /// HTML 编码
  static String htmlEncode(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// HTML 解码
  static String htmlDecode(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}