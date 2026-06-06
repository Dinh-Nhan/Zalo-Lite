import 'package:flutter/material.dart';

class GroupItemWidget extends StatelessWidget {
  final String name;
  final String sub;
  final String time;
  final bool isMute;

  const GroupItemWidget({
    super.key,
    required this.name,
    required this.sub,
    required this.time,
    required this.isMute,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        highlightColor: Colors.black.withValues(alpha: 0.05),
        splashColor: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFFE0E0E0),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMute)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.notifications_off_outlined, size: 16, color: Colors.grey),
                ),
              Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
