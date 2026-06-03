import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0091FF), // Màu xanh Zalo chuẩn
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => GoRouter.of(context).pop(),
          ),
          title: const Text("Lời mời kết bạn", style: TextStyle(color: Colors.white, fontSize: 18)),
          centerTitle: false,
          actions: [
            IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                indicatorColor: Colors.black,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                tabs: [
                  Tab(
                    text:
                        "Đã nhận ${provider.pendingReceived.length}",
                  ),

                  Tab(
                    text:
                        "Đã gửi ${provider.pendingSent.length}",
                  ),
                ],
              ),
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