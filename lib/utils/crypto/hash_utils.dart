import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

/// 哈希工具类
/// 提供 MD5、SHA1、SHA256 等哈希算法
class HashUtils {
  /// MD5 哈希
  ///
  /// [input] 输入字符串
  /// 返回 MD5 哈希值的十六进制字符串
  static String md5(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.md5.convert(bytes);
    return digest.toString();
  }

  /// MD5 哈希（字节形式）
  ///
  /// [input] 输入字符串
  /// 返回 MD5 哈希的字节数组
  static List<int> md5Bytes(String input) {
    final bytes = utf8.encode(input);
    return crypto.md5.convert(bytes).bytes;
  }

  /// SHA1 哈希
  ///
  /// [input] 输入字符串
  /// 返回 SHA1 哈希值的十六进制字符串
  static String sha1(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha1.convert(bytes);
    return digest.toString();
  }

  /// SHA1 哈希（字节形式）
  ///
  /// [input] 输入字符串
  /// 返回 SHA1 哈希的字节数组
  static List<int> sha1Bytes(String input) {
    final bytes = utf8.encode(input);
    return crypto.sha1.convert(bytes).bytes;
  }

  /// SHA256 哈希
  ///
  /// [input] 输入字符串
  /// 返回 SHA256 哈希值的十六进制字符串
  static String sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  /// SHA256 哈希（字节形式）
  ///
  /// [input] 输入字符串
  /// 返回 SHA256 哈希的字节数组
  static List<int> sha256Bytes(String input) {
    final bytes = utf8.encode(input);
    return crypto.sha256.convert(bytes).bytes;
  }

  /// SHA512 哈希
  ///
  /// [input] 输入字符串
  /// 返回 SHA512 哈希值的十六进制字符串
  static String sha512(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha512.convert(bytes);
    return digest.toString();
  }

  /// SHA512 哈希（字节形式）
  ///
  /// [input] 输入字符串
  /// 返回 SHA512 哈希的字节数组
  static List<int> sha512Bytes(String input) {
    final bytes = utf8.encode(input);
    return crypto.sha512.convert(bytes).bytes;
  }

  /// HMAC-MD5 签名
  ///
  /// [key] 密钥
  /// [data] 数据
  /// 返回 HMAC-MD5 的十六进制字符串
  static String hmacMd5(String key, String data) {
    final hmac = crypto.Hmac(crypto.md5, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// HMAC-SHA1 签名
  ///
  /// [key] 密钥
  /// [data] 数据
  /// 返回 HMAC-SHA1 的十六进制字符串
  static String hmacSha1(String key, String data) {
    final hmac = crypto.Hmac(crypto.sha1, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// HMAC-SHA256 签名
  ///
  /// [key] 密钥
  /// [data] 数据
  /// 返回 HMAC-SHA256 的十六进制字符串
  static String hmacSha256(String key, String data) {
    final hmac = crypto.Hmac(crypto.sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// HMAC-SHA512 签名
  ///
  /// [key] 密钥
  /// [data] 数据
  /// 返回 HMAC-SHA512 的十六进制字符串
  static String hmacSha512(String key, String data) {
    final hmac = crypto.Hmac(crypto.sha512, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// 计算文件的 MD5 哈希
  ///
  /// [bytes] 文件的字节数组
  /// 返回 MD5 哈希值的十六进制字符串
  static String fileMd5(List<int> bytes) {
    final digest = crypto.md5.convert(bytes);
    return digest.toString();
  }

  /// 计算文件的 SHA1 哈希
  ///
  /// [bytes] 文件的字节数组
  /// 返回 SHA1 哈希值的十六进制字符串
  static String fileSha1(List<int> bytes) {
    final digest = crypto.sha1.convert(bytes);
    return digest.toString();
  }

  /// 计算文件的 SHA256 哈希
  ///
  /// [bytes] 文件的字节数组
  /// 返回 SHA256 哈希值的十六进制字符串
  static String fileSha256(List<int> bytes) {
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证 MD5 哈希
  ///
  /// [input] 输入字符串
  /// [expectedHash] 期望的哈希值
  /// 返回是否匹配
  static bool verifyMd5(String input, String expectedHash) {
    return md5(input) == expectedHash;
  }

  /// 验证 SHA256 哈希
  ///
  /// [input] 输入字符串
  /// [expectedHash] 期望的哈希值
  /// 返回是否匹配
  static bool verifySha256(String input, String expectedHash) {
    return sha256(input) == expectedHash;
  }

  /// 获取所有支持的哈希算法名称
  static List<String> get supportedAlgorithms => [
    'md5',
    'sha1',
    'sha256',
    'sha512',
  ];
}