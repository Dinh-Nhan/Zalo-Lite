class ChatHelpers {
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static String getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
           '${now.minute.toString().padLeft(2, '0')}';
  }

  static bool isSameGroup(
    Map<String, dynamic> msg1,
    Map<String, dynamic> msg2,
    bool isGroup,
  ) {
    if (msg1['isMe'] != msg2['isMe']) return false;

    if (isGroup && !msg1['isMe']) {
      if (msg1['senderName'] != msg2['senderName']) return false;
    }

    try {
      final p1 = msg1['time'].split(':');
      final p2 = msg2['time'].split(':');
      final m1 = int.parse(p1[0]) * 60 + int.parse(p1[1]);
      final m2 = int.parse(p2[0]) * 60 + int.parse(p2[1]);
      return (m2 - m1).abs() <= 5;
    } catch (_) {
      return false;
    }
  }
}