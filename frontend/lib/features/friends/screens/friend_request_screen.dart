import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/received_request_tab.dart';
import 'package:frontend/features/friends/screens/sent_request_tab.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FriendRequestScreen extends StatelessWidget {
  const FriendRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => GoRouter.of(context).pop(),
          ),
          titleSpacing: 8,
          title: const Text(
            'Lời mời kết bạn',
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
              decoration: const BoxDecoration(color: Colors.white),
              child: TabBar(
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 3.5),
                  insets: EdgeInsets.symmetric(horizontal: 16),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: Colors.grey[500],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                tabs: [
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
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            ReceivedRequestsTab(),
            SentRequestsTab(),
          ],
        ),
      ),
    );
  }
}
