/// 全局配置管理（静态变量方式）
library;

/// 配置类
class Mgtvconfig {
  final int shortVideoRandomMax;
  final int shortVideoRandomMin;
  final String playDomain;
  final bool initialized;

  const Mgtvconfig({
    this.shortVideoRandomMax = 200,
    this.shortVideoRandomMin = 1,
    this.playDomain = 'https://qcwotewlno9.rj2345.com',
    this.initialized = false,
  });
}

/// mgtv请求体
class FormType {
  // ignore: non_constant_identifier_names
  String? PageIndex;
  // ignore: non_constant_identifier_names
  String? PageSize;
  // ignore: non_constant_identifier_names
  String? VideoType;
  // ignore: non_constant_identifier_names
  String? SortType;
}

/// 全局配置类
class GlobalConfig {
  static Mgtvconfig? _instance;
  static String apiBase = 'https://api.mgtv109.cc'; // 请求API域名

  // 私有构造函数，防止实例化
  GlobalConfig._();

  /// 获取配置实例
  static Mgtvconfig get instance {
    _instance ??= Mgtvconfig();
    return _instance!;
  }

  /// 初始化配置
  static void initialize(Mgtvconfig config) {
    _instance = config;
  }

  /// 更新播放域名
  static void updatePlayDomain(String domain) {
    _instance = Mgtvconfig(
      shortVideoRandomMax: _instance?.shortVideoRandomMax ?? 200,
      shortVideoRandomMin: _instance?.shortVideoRandomMin ?? 1,
      playDomain: domain,
      initialized: true,
    );
  }

  /// 便捷访问器
  static int get shortVideoRandomMax => instance.shortVideoRandomMax;
  static int get shortVideoRandomMin => instance.shortVideoRandomMin;
  static String get playDomain => instance.playDomain;
  static bool get initialized => instance.initialized;

  /// 便捷重置方法
  static void reset() {
    _instance = null;
  }
}
