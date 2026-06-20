// ============================================================
// CORE - DateTime Extensions
// ============================================================

extension DateTimeX on DateTime {
  String get formatted => _formatDate(this);
  String get formattedWithTime => _formatDateTime(this);
  String get timeAgo => _timeAgo(this);
  String get dateOnly => _dateOnly(this);

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  static String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _dateOnly(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

extension NullableDateTimeX on DateTime? {
  String get formattedOrEmpty => this == null ? '—' : this!.formatted;
  String get formattedWithTimeOrEmpty =>
      this == null ? '—' : this!.formattedWithTime;
}

extension IntX on int {
  String get compact {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K';
    return toString();
  }
}
