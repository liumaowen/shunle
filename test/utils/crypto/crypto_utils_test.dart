import 'package:flutter_test/flutter_test.dart';
import 'package:shunle/utils/crypto/crypto_utils.dart';
import 'package:shunle/utils/crypto/aes_crypto.dart';
import 'package:shunle/utils/crypto/hash_utils.dart';
import 'package:shunle/utils/crypto/uuid_utils.dart';
import 'package:shunle/utils/crypto/m3u8_utils.dart';
import 'package:shunle/utils/date_utils.dart';

void main() {
  group('CryptoUtils Tests', () {
    group('AES 加密解密测试', () {
      test('AES 加密解密', () async {
        const plaintext = 'Hello, World!';
        final encrypted = await CryptoUtils.aesEncrypt(plaintext);
        final decrypted = await CryptoUtils.aesDecrypt(encrypted);

        expect(encrypted, isNotNull);
        expect(encrypted, isNot(plaintext));
        expect(decrypted, plaintext);
      });

      test('AES 加密空字符串', () async {
        final encrypted = await CryptoUtils.aesEncrypt('');
        final decrypted = await CryptoUtils.aesDecrypt(encrypted);
        expect(decrypted, '');
      });
    });

    group('哈希测试', () {
      test('MD5 哈希', () {
        const input = 'Hello, World!';
        final hash = HashUtils.md5(input);

        expect(hash, isNotNull);
        expect(hash.length, equals(32));
        expect(hash, equals('65a8e27d8879283831b664bd8b7f0ad4'));
      });

      test('SHA256 哈希', () {
        const input = 'Hello, World!';
        final hash = HashUtils.sha256(input);

        expect(hash, isNotNull);
        expect(hash.length, equals(64));
      });

      test('SHA1 哈希', () {
        const input = 'Hello, World!';
        final hash = HashUtils.sha1(input);

        expect(hash, isNotNull);
        expect(hash.length, equals(40));
      });

      test('哈希验证', () {
        const input = 'Hello, World!';
        const expectedHash = '65a8e27d8879283831b664bd8b7f0ad4';

        expect(HashUtils.verifyMd5(input, expectedHash), isTrue);
        expect(HashUtils.verifyMd5(input, 'wrong'), isFalse);
      });
    });

    group('UUID 测试', () {
      test('生成 UUID v4', () {
        final uuid = UUIDUtils.generateV4();

        expect(uuid, isNotNull);
        expect(uuid.length, equals(36));
        expect(uuid, matches(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));
      });

      test('生成短 UUID', () {
        final uuid = UUIDUtils.generateShort();

        expect(uuid, isNotNull);
        expect(uuid.length, equals(32));
        expect(uuid, matches(r'^[0-9a-f]{32}$'));
      });

      test('验证 UUID 格式', () {
        expect(UUIDUtils.isValid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
        expect(UUIDUtils.isValid('550e8400e29b41d4a716446655440000'), isTrue);
        expect(UUIDUtils.isValid('invalid-uuid'), isFalse);
        expect(UUIDUtils.isValid(''), isFalse);
      });

      test('验证 UUID v4', () {
        expect(UUIDUtils.isV4('550e8400-e29b-41d4-a716-446655440000'), isTrue);
        expect(UUIDUtils.isV4('550e8400-e29b-41d4-8166-446655440000'), isFalse); // 版本号应该是 4
      });

      test('批量生成 UUID', () {
        final uuids = UUIDUtils.generateMultiple(5);

        expect(uuids.length, equals(5));
        for (final uuid in uuids) {
          expect(UUIDUtils.isValid(uuid), isTrue);
        }
      });
    });

    group('M3U8 签名 URL 测试', () {
      test('生成签名 URL', () {
        final baseUrl = 'https://example.com';
        final path = 'video.ts';
        final signedUrl = M3U8Utils.generateSignedUrl(
          baseUrl: baseUrl,
          path: path,
        );

        expect(signedUrl, contains(baseUrl));
        expect(signedUrl, contains(path));
        expect(signedUrl, contains('t='));
        expect(signedUrl, contains('sign='));
      });

      test('生成 Master URL', () {
        final baseUrl = 'https://example.com';
        final masterUrl = M3U8Utils.generateMasterUrl(baseUrl: baseUrl);

        expect(masterUrl, contains(baseUrl));
        expect(masterUrl, contains('master.m3u8'));
        expect(masterUrl, contains('t='));
        expect(masterUrl, contains('sign='));
      });

      test('验证签名', () {
        final baseUrl = 'https://example.com';
        final path = 'video.ts';
        final signedUrl = M3U8Utils.generateSignedUrl(
          baseUrl: baseUrl,
          path: path,
        );

        expect(M3U8Utils.validateSignature(signedUrl), isTrue);
        expect(M3U8Utils.validateSignature('invalid-url'), isFalse);
      });

      test('检查过期时间', () {
        final baseUrl = 'https://example.com';
        final path = 'video.ts';
        final expiredUrl = M3U8Utils.generateSignedUrl(
          baseUrl: baseUrl,
          path: path,
          expireSeconds: -1, // 已过期
        );

        expect(M3U8Utils.isExpired(expiredUrl), isTrue);
      });

      test('获取过期时间', () {
        final baseUrl = 'https://example.com';
        final path = 'video.ts';
        final signedUrl = M3U8Utils.generateSignedUrl(
          baseUrl: baseUrl,
          path: path,
          expireSeconds: 3600, // 1小时后过期
        );

        final expireTime = M3U8Utils.getExpireTime(signedUrl);
        expect(expireTime, isNotNull);
        expect(expireTime!.isAfter(DateTime.now()), isTrue);
      });
    });

    group('DateUtils 测试', () {
      test('日期格式化', () {
        final date = DateTime(2024, 1, 1, 12, 0, 0);
        final formatted = DateUtils.format(date);

        expect(formatted, equals('2024-01-01 12:00:00'));
      });

      test('日期解析', () {
        const dateString = '2024-01-01 12:00:00';
        final date = DateUtils.parse(dateString);

        expect(date, isNotNull);
        expect(date!.year, equals(2024));
        expect(date.month, equals(1));
        expect(date.day, equals(1));
        expect(date.hour, equals(12));
      });

      test('时间戳转换', () {
        final date = DateTime(2024, 1, 1, 12, 0, 0);
        final timestamp = date.millisecondsSinceEpoch;
        final formatted = DateUtils.formatTimestamp(timestamp);

        expect(formatted, equals('2024-01-01 12:00:00'));
      });

      test('相对时间格式化', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(minutes: 5));
        final formatted = DateUtils.formatRelative(past);

        expect(formatted, contains('分钟前'));
      });

      test('同一天判断', () {
        final date1 = DateTime(2024, 1, 1, 10, 0, 0);
        final date2 = DateTime(2024, 1, 1, 15, 0, 0);

        expect(DateUtils.isSameDay(date1, date2), isTrue);
      });

      test('日期计算', () {
        final date = DateTime(2024, 1, 1);
        final nextDay = DateUtils.addDays(date, 1);

        expect(nextDay.year, equals(2024));
        expect(nextDay.month, equals(1));
        expect(nextDay.day, equals(2));
      });

      test('时间属性', () {
        expect(DateUtils.today, matches(r'^\d{4}-\d{2}-\d{2}$'));
        expect(DateUtils.yesterday, matches(r'^\d{4}-\d{2}-\d{2}$'));
        expect(DateUtils.tomorrow, matches(r'^\d{4}-\d{2}-\d{2}$'));
      });

      test('星期几', () {
        final date = DateTime(2024, 1, 1); // 假设是周一
        expect(DateUtils.getWeekday(date), equals('周一'));
      });

      test('月份名称', () {
        final date = DateTime(2024, 1, 1);
        expect(DateUtils.getMonthName(date), equals('一月'));
      });

      test('今天判断', () {
        final now = DateTime.now();
        expect(DateUtils.isToday(now), isTrue);
      });
    });

    group('CryptoUtils 工具方法测试', () {
      test('生成随机字符串', () {
        final randomString = CryptoUtils.generateRandomString(length: 10);

        expect(randomString.length, equals(10));
        expect(randomString, matches(r'^[a-zA-Z0-9]+$'));
      });

      test('生成时间戳', () {
        final timestamp = CryptoUtils.generateTimestamp();

        expect(timestamp, isNotNull);
        expect(int.tryParse(timestamp), isNotNull);
      });

      test('格式化日期', () {
        final date = DateTime(2024, 1, 1, 12, 30, 45);
        final formatted = CryptoUtils.formatDate(date);

        expect(formatted, equals('2024-01-01 12:30:45'));
      });

      test('生成 M3U8 URL', () {
        final baseUrl = 'https://example.com';
        final path = 'video.ts';
        final url = CryptoUtils.generateM3U8Url(
          baseUrl: baseUrl,
          path: path,
        );

        expect(url, contains(baseUrl));
        expect(url, contains(path));
        expect(url, contains('sign='));
      });

      test('验证 M3U8 签名', () {
        const baseUrl = 'https://example.com';
        const path = 'video.ts';
        final url = CryptoUtils.generateM3U8Url(
          baseUrl: baseUrl,
          path: path,
        );

        expect(CryptoUtils.validateM3U8Signature(url), isTrue);
      });

      test('生成短 ID', () {
        final shortId = CryptoUtils.generateShortId(length: 8);

        expect(shortId.length, equals(8));
      });

      test('Base64 编码解码', () {
        const original = 'Hello, World!';
        final encoded = CryptoUtils.base64Encode(original);
        final decoded = CryptoUtils.base64Decode(encoded);

        expect(decoded, equals(original));
        expect(encoded, isNot(equals(original)));
      });

      test('URL 编码解码', () {
        const original = 'Hello World & More';
        final encoded = CryptoUtils.urlEncode(original);
        final decoded = CryptoUtils.urlDecode(encoded);

        expect(decoded, equals(original));
      });

      test('HTML 编码解码', () {
        const original = '<div>Hello "World"</div>';
        final encoded = CryptoUtils.htmlEncode(original);
        final decoded = CryptoUtils.htmlDecode(encoded);

        expect(decoded, equals(original));
        expect(encoded, contains('&lt;'));
      });

      test('生成 HMAC', () {
        const key = 'secret-key';
        const data = 'test-data';
        final hmac = CryptoUtils.generateHMAC(key, data);

        expect(hmac, isNotNull);
        expect(hmac.length, greaterThan(0));
      });

      test('检查 Base64 格式', () {
        const validBase64 = 'SGVsbG8gV29ybGQh';
        const invalidBase64 = 'Hello World!';

        expect(CryptoUtils.isBase64(validBase64), isTrue);
        expect(CryptoUtils.isBase64(invalidBase64), isFalse);
      });
    });

    group('集成测试', () {
      test('完整的加密解密流程', () async {
        // 1. 生成随机数据
        final original = '这是一段秘密消息 ${DateTime.now()}';

        // 2. 加密
        final encrypted = await CryptoUtils.aesEncrypt(original);

        // 3. 解密
        final decrypted = await CryptoUtils.aesDecrypt(encrypted);

        // 4. 验证
        expect(decrypted, equals(original));
        expect(encrypted, isNot(equals(original)));
      });

      test('UUID 与哈希集成', () {
        // 1. 生成 UUID
        final uuid = UUIDUtils.generateV4();

        // 2. 计算 UUID 的哈希
        final hash = HashUtils.sha256(uuid);

        // 3. 验证
        expect(uuid, isNotNull);
        expect(hash.length, equals(64));
        expect(UUIDUtils.isValid(uuid), isTrue);
      });

      test('日期与时间戳集成', () {
        // 1. 创建日期
        final date = DateTime(2024, 12, 25, 15, 30, 0);

        // 2. 转换时间戳
        final timestamp = DateUtils.parseToTimestamp(DateUtils.format(date));

        // 3. 验证
        expect(timestamp, isNotNull);
        expect(timestamp, equals(date.millisecondsSinceEpoch));
      });
    });
  });
}