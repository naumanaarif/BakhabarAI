import 'package:intl/intl.dart';

class TimeUtils {
  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  static String formatFullDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }
}
