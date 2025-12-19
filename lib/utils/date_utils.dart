import 'package:intl/intl.dart';

/// 日期工具类
/// 提供日期格式化、解析和转换功能
class DateUtils {
  /// 默认日期格式
  static const String defaultFormat = 'yyyy-MM-dd HH:mm:ss';

  /// 日期格式化
  ///
  /// [date] 日期对象
  /// [format] 格式字符串，默认 'yyyy-MM-dd HH:mm:ss'
  /// 返回格式化后的字符串
  static String format(DateTime date, {String format = defaultFormat}) {
    return DateFormat(format).format(date);
  }

  /// 格式化当前日期
  ///
  /// [format] 格式字符串，默认 'yyyy-MM-dd HH:mm:ss'
  /// 返回格式化后的字符串
  static String now({String format = defaultFormat}) {
    return DateFormat(format).format(DateTime.now());
  }

  /// 从字符串解析日期
  ///
  /// [dateString] 日期字符串
  /// [format] 格式字符串，默认 'yyyy-MM-dd HH:mm:ss'
  /// 返回 DateTime 对象，如果解析失败返回 null
  static DateTime? parse(String dateString, {String format = defaultFormat}) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// 从时间戳解析日期
  ///
  /// [timestamp] 时间戳（毫秒）
  /// 返回 DateTime 对象
  static DateTime fromTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 获取当前时间戳
  ///
  /// 返回毫秒级时间戳
  static int get nowTimestamp => DateTime.now().millisecondsSinceEpoch;

  /// 格式化时间戳为日期字符串
  ///
  /// [timestamp] 时间戳（毫秒）
  /// [format] 格式字符串，默认 'yyyy-MM-dd HH:mm:ss'
  /// 返回格式化后的字符串
  static String formatTimestamp(int timestamp, {String format = defaultFormat}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat(format).format(date);
  }

  /// 从日期字符串获取时间戳
  ///
  /// [dateString] 日期字符串
  /// [format] 格式字符串，默认 'yyyy-MM-dd HH:mm:ss'
  /// 返回时间戳（毫秒），如果解析失败返回 null
  static int? parseToTimestamp(String dateString, {String format = defaultFormat}) {
    final date = parse(dateString, format: format);
    return date?.millisecondsSinceEpoch;
  }

  /// 格式化相对时间
  ///
  /// [date] 日期对象
  /// 返回相对时间描述（如：刚刚、5分钟前、1小时前等）
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return '${months}个月前';
    } else {
      final years = difference.inDays ~/ 365;
      return '${years}年前';
    }
  }

  /// 格式化日期范围
  ///
  /// [start] 开始日期
  /// [end] 结束日期
  /// [format] 日期格式，默认 'yyyy-MM-dd'
  /// 返回 "开始日期 - 结束日期" 格式的字符串
  static String formatRange(DateTime start, DateTime end, {String format = 'yyyy-MM-dd'}) {
    return '${DateUtils.format(start, format: format)} - ${DateUtils.format(end, format: format)}';
  }

  /// 格式化时间段
  ///
  /// [start] 开始日期
  /// [end] 结束日期
  /// 返回时间段描述（如：2小时30分钟）
  static String formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    return _formatDuration(duration);
  }

  /// 格式化 Duration
  ///
  /// [duration] 时间段
  /// 返回时间段描述
  static String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}分${duration.inSeconds % 60}秒';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}小时${duration.inMinutes % 60}分';
    } else {
      return '${duration.inDays}天${duration.inHours % 24}小时';
    }
  }

  /// 格式化今天
  static String get today => format(DateTime.now(), format: 'yyyy-MM-dd');

  /// 格式化昨天
  static String get yesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return format(yesterday, format: 'yyyy-MM-dd');
  }

  /// 格式化明天
  static String get tomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return format(tomorrow, format: 'yyyy-MM-dd');
  }

  /// 获取星期几
  ///
  /// [date] 日期对象
  /// 返回星期几的字符串（周一、周二...周日）
  static String getWeekday(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  /// 获取月份名称
  ///
  /// [date] 日期对象
  /// 返回月份名称（一月、二月...十二月）
  static String getMonthName(DateTime date) {
    const months = [
      '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'
    ];
    return months[date.month - 1];
  }

  /// 判断是否为今天
  ///
  /// [date] 日期对象
  /// 返回是否为今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// 判断是否为昨天
  ///
  /// [date] 日期对象
  /// 返回是否为昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
           date.month == yesterday.month &&
           date.day == yesterday.day;
  }

  /// 判断是否为同一天
  ///
  /// [date1] 第一个日期
  /// [date2] 第二个日期
  /// 返回是否为同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// 添加天数
  ///
  /// [date] 原日期
  /// [days] 天数
  /// 返回新的日期
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// 减少天数
  ///
  /// [date] 原日期
  /// [days] 天数
  /// 返回新的日期
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// 获取月份的第一天
  ///
  /// [date] 日期对象
  /// 返回当月第一天
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取月份的最后一天
  ///
  /// [date] 日期对象
  /// 返回当月最后一天
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 获取年份的第一天
  ///
  /// [date] 日期对象
  /// 返回当年第一天
  static DateTime getFirstDayOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// 获取年份的最后一天
  ///
  /// [date] 日期对象
  /// 返回当年最后一天
  static DateTime getLastDayOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  /// 获取本星期一的日期
  ///
  /// [date] 日期对象
  /// 返回本周一
  static DateTime getMondayOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// 获取本周日的日期
  ///
  /// [date] 日期对象
  /// 返回本周日
  static DateTime getSundayOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  /// 计算两个日期之间的天数
  ///
  /// [start] 开始日期
  /// [end] 结束日期
  /// 返回天数差
  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// 判断日期是否在范围内
  ///
  /// [date] 要判断的日期
  /// [start] 开始日期
  /// [end] 结束日期
  /// 返回是否在范围内
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// 获取时间描述
  ///
  /// [date] 日期对象
  /// 返回时间描述（如：早上、下午、晚上等）
  static String getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= 6 && hour < 12) {
      return '早上';
    } else if (hour >= 12 && hour < 18) {
      return '下午';
    } else if (hour >= 18 && hour < 24) {
      return '晚上';
    } else {
      return '凌晨';
    }
  }

  /// 获取季度
  ///
  /// [date] 日期对象
  /// 返回季度（1-4）
  static int getQuarter(DateTime date) {
    return ((date.month - 1) ~/ 3) + 1;
  }

  /// 格式化季度
  ///
  /// [date] 日期对象
  /// 返回季度字符串（如：2024-Q1）
  static String formatQuarter(DateTime date) {
    return '${date.year}-Q${getQuarter(date)}';
  }
}