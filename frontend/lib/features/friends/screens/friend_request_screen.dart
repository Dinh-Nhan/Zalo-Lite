import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/received_request_tab.dart';
import 'package:frontend/features/friends/screens/sent_request_tab.dart';
import 'package:provider/provider.dart';

class FriendRequestScreen extends StatelessWidget {
  const FriendRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Chuyển sang xám nhẹ để làm nổi bật các thẻ bên trong Body
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leadingWidth: 50,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 8,
          title: const Text(
            "Lời mời kết bạn",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {},
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              // Đổ bóng nhẹ phía dưới TabBar để tạo layer phân tách mượt mà
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
  // Sử dụng UnderlineTabIndicator tùy biến để bo tròn góc thanh và chỉnh màu sắc nét
  indicator: const UnderlineTabIndicator(
    borderSide: BorderSide(
      color: AppColors.primaryBlue, // Đảm bảo lấy đúng màu xanh chủ đạo của bạn
      width: 3.5, // Độ dày vừa vặn, rất cao cấp
    ),
    insets: EdgeInsets.symmetric(horizontal: 16), // Tạo khoảng cách thụt lề để thanh không bị dính sát mép
  ),
  indicatorSize: TabBarIndicatorSize.label, // Thu gọn thanh indicator vừa bằng độ dài của chữ + badge, cực kỳ tinh tế
  
  labelColor: AppColors.primaryBlue, // Khi tab được chọn, chữ chuyển sang màu xanh
  unselectedLabelColor: Colors.grey[500], // Khi chưa chọn, chữ màu xám vừa phải
  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
  
  tabs: [
    // --- TAB 1: ĐÃ NHẬN ---
    Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Đã nhận'),
          const SizedBox(width: 6),
          if (provider.pendingReceived.isNotEmpty)
            Badge(
              label: Text(
                '${provider.pendingReceived.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              backgroundColor: Colors.redAccent, 
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
        ],
      ),
    ),

    // --- TAB 2: ĐÃ GỬI ---
    Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Đã gửi'),
          const SizedBox(width: 6),
          if (provider.pendingSent.isNotEmpty)
            Badge(
              label: Text(
                '${provider.pendingSent.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              backgroundColor: Colors.grey[600], 
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
        ],
      ),
    ),
  ],
)
              
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            ReceivedRequestsTab(), // Tab Đã nhận
            SentRequestsTab(),     // Tab Đã gửi
          ],
        ),
      ),
    );
  }
}
