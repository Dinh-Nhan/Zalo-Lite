import 'package:flutter/material.dart';
import 'package:frontend/features/friends/widgets/group_item.dart';
import 'package:frontend/views/chat/new_conversation_screen.dart';

class GroupTabView extends StatelessWidget {
  const GroupTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Mục Tạo nhóm mới
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NewConversationScreen(type: 'group'),
              ),
            ),
            highlightColor: Colors.black.withOpacity(0.05),
            splashColor: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD), 
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.group_add, color: Colors.blue, size: 24),
              ),
              title: const Text(
                "Tạo nhóm mới", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue)
              ),
            ),
          ),
        ),

        const Divider(thickness: 8, color: Color(0xFFF4F5F7), height: 8),

        // Header danh sách nhóm
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Nhóm đang tham gia (114)", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
              ),
              Row(
                children: [
                  Icon(Icons.sort, size: 16, color: Colors.grey),
                  Text(" Sắp xếp", style: TextStyle(color: Colors.grey))
                ]
              ),
            ],
          ),
        ),

        GroupItemWidget(
          name: "VIỆC LÀM THỜI VỤ",
          sub: "đã đủ cảm ơn anh em, chúc anh em...",
          time: "1 phút",
          isMute: true,
        ),
        GroupItemWidget(
          name: "LONGHOUSE 10",
          sub: "20H back 30% max 50K...",
          time: "50 phút",
          isMute: false,
        ),
      ],
    );
  }
}