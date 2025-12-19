import 'dart:math';
import 'package:uuid/uuid.dart';

/// UUID 工具类
/// 提供 UUID v4 生成和验证功能
class UUIDUtils {
  /// UUID 生成器实例
  static final Uuid _uuid = const Uuid();

  /// 生成 UUID v4
  ///
  /// 返回 UUID v4 格式的字符串
  static String generateV4() {
    return _uuid.v4();
  }

  /// 生成带 UUID 前缀的 ID
  ///
  /// [prefix] 前缀字符串
  /// 返回 "prefix-uuid" 格式的字符串
  static String generateWithPrefix(String prefix) {
    return '$prefix-${_uuid.v4()}';
  }

  /// 生成短 UUID（去除横线）
  ///
  /// 返回无横线的 UUID 字符串
  static String generateShort() {
    return _uuid.v4().replaceAll('-', '');
  }

  /// 生成数字 UUID（仅保留十六进制数字）
  ///
  /// 返回仅包含数字和字母的 UUID 字符串
  static String generateNumeric() {
    final uuid = _uuid.v4().replaceAll('-', '');
    return uuid;
  }

  /// 验证 UUID 格式
  ///
  /// [uuid] 要验证的 UUID 字符串
  /// [version] UUID 版本（可选，null 表示不检查版本）
  /// 返回是否为有效的 UUID
  static bool isValid(String uuid, {int? version}) {
    if (uuid == null || uuid.isEmpty) {
      return false;
    }

    // 标准 UUID 格式（带横线）
    final standardPattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
    // 短 UUID 格式（无横线）
    final shortPattern = r'^[0-9a-f]{32}$';

    final standardRegex = RegExp(standardPattern, caseSensitive: false);
    final shortRegex = RegExp(shortPattern, caseSensitive: false);

    final isStandard = standardRegex.hasMatch(uuid.toLowerCase());
    final isShort = shortRegex.hasMatch(uuid.toLowerCase());

    if (!isStandard && !isShort) {
      return false;
    }

    // 如果指定了版本号，检查版本
    if (version != null && isStandard) {
      // 从 UUID 中提取版本号
      final versionPart = uuid.substring(14, 15);
      final actualVersion = int.parse(versionPart, radix: 16);
      return actualVersion == version;
    }

    return true;
  }

  /// 验证是否为 UUID v4
  ///
  /// [uuid] 要验证的 UUID 字符串
  /// 返回是否为有效的 UUID v4
  static bool isV4(String uuid) {
    return isValid(uuid, version: 4);
  }

  /// 获取 UUID 的版本号
  ///
  /// [uuid] UUID 字符串
  /// 返回版本号（1-5），如果无效返回 null
  static int? getVersion(String uuid) {
    if (!isValid(uuid)) {
      return null;
    }

    if (!uuid.contains('-')) {
      return null;
    }

    try {
      final versionPart = uuid.substring(14, 15);
      return int.parse(versionPart, radix: 16);
    } catch (e) {
      return null;
    }
  }

  /// 从 UUID 提取时间戳（仅适用于 v1）
  ///
  /// [uuid] UUID 字符串
  /// 返回时间戳（毫秒），如果不是 v1 返回 null
  static int? getTimestamp(String uuid) {
    if (getVersion(uuid) != 1) {
      return null;
    }

    try {
      // UUID v1 的时间戳在第一个部分的前 8 个十六进制字符中
      final timestampHex = uuid.substring(0, 8);
      final timestamp = int.parse(timestampHex, radix: 16);
      // UUID v1 使用 100 纳秒精度，需要转换为毫秒
      return timestamp * 10;
    } catch (e) {
      return null;
    }
  }

  /// 生成基于时间的 UUID（v1）
  ///
  /// [clockSeq] 时钟序列（可选）
  /// [node] 节点 ID（可选）
  /// 返回 UUID v1 字符串
  static String generateV1({int? clockSeq, String? node}) {
    // UUID v1 需要更复杂的实现，这里简化处理
    // 实际使用时可以考虑使用专门的库
    return _uuid.v1();
  }

  /// 生成基于随机数的 UUID（v4）
  ///
  /// [random] 随机数生成器（可选，使用默认）
  /// 返回 UUID v4 字符串
  static String generateV4Random({Random? random}) {
    // 使用提供的随机数生成器或默认生成器
    final rng = random ?? Random.secure();

    // 生成 UUID v4 的各个部分
    final hex = rng.nextInt(0xffffffff);
    final clockSeq = rng.nextInt(0x0fff);
    final node = rng.nextInt(0xffffffffffff);

    // 构建 UUID v4 字符串
    return '${hex.toRadixString(16).padLeft(8, '0')}-'
           '${rng.nextInt(0x0fff | 0x4000).toRadixString(16).padLeft(4, '0')}-'
           '${rng.nextInt(0x0fff | 0x8000).toRadixString(16).padLeft(4, '0')}-'
           '${rng.nextInt(0x0fff).toRadixString(16).padLeft(4, '0')}-'
           '${rng.nextInt(0xffffffff).toRadixString(16).padLeft(8, '0')}'
           '${rng.nextInt(0xffffffff).toRadixString(16).padLeft(8, '0')}';
  }

  /// 批量生成 UUID
  ///
  /// [count] 要生成的 UUID 数量
  /// 返回 UUID 列表
  static List<String> generateMultiple(int count) {
    if (count <= 0) {
      throw ArgumentError('数量必须大于 0');
    }

    return List.generate(count, (_) => generateV4());
  }

  /// 格式化 UUID（添加横线）
  ///
  /// [uuid] 无横线的 UUID 字符串
  /// 返回格式化后的 UUID 字符串
  static String format(String uuid) {
    if (uuid.length != 32) {
      throw ArgumentError('UUID 必须为 32 个字符');
    }

    if (uuid.contains('-')) {
      return uuid; // 已经格式化
    }

    return '${uuid.substring(0, 8)}-'
           '${uuid.substring(8, 12)}-'
           '${uuid.substring(12, 16)}-'
           '${uuid.substring(16, 20)}-'
           '${uuid.substring(20)}';
  }

  /// 压缩 UUID（移除横线）
  ///
  /// [uuid] 格式化的 UUID 字符串
  /// 返回无横线的 UUID 字符串
  static String compress(String uuid) {
    return uuid.replaceAll('-', '');
  }

  /// 生成有序 UUID（基于时间 + 随机数）
  /// 返回有序的 UUID 字符串
  static String generateOrdered() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();

    // 使用时间戳和随机数生成有序 UUID
    final hex1 = (timestamp & 0xffffffff).toRadixString(16).padLeft(8, '0');
    final hex2 = ((timestamp >> 32) & 0xffff).toRadixString(16).padLeft(4, '0');
    final hex3 = (random.nextInt(0x0fff) | 0x4000).toRadixString(16).padLeft(4, '0');
    final rest = List.generate(12, (_) => random.nextInt(16).toRadixString(16)).join();

    return '$hex1$hex2$hex3-${rest.substring(0,4)}-${rest.substring(4,8)}-${rest.substring(8,12)}';
  }

  /// 比较两个 UUID
  ///
  /// [uuid1] 第一个 UUID
  /// [uuid2] 第二个 UUID
  /// 返回比较结果
  static int compare(String uuid1, String uuid2) {
    return uuid1.compareTo(uuid2);
  }

  /// 检查 UUID 是否为空或无效
  ///
  /// [uuid] 要检查的 UUID
  /// 返回是否为空或无效
  static bool isNullOrEmpty(String? uuid) {
    return uuid == null || uuid.isEmpty || !isValid(uuid);
  }
}