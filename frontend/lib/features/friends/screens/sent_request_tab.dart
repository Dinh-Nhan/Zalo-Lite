import 'package:flutter/material.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:provider/provider.dart';

import 'request_item.dart';

class SentRequestsTab extends StatefulWidget {
  const SentRequestsTab({super.key});

  @override
  State<SentRequestsTab> createState() => _SentRequestsTabState();
}

class _SentRequestsTabState extends State<SentRequestsTab> {
  int _visibleCount = 10;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final provider = context.read<FriendProvider>();
      await provider.loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    final requests = provider.pendingSent;

    // Loading
    if (provider.requestsState == LoadingState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (provider.requestsState == LoadingState.error) {
      return Center(
        child: Text(provider.errorMessage ?? 'Có lỗi xảy ra'),
      );
    }

    // Empty
    if (requests.isEmpty) {
      return const Center(
        child: Text(
          'Không có lời mời đã gửi',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final visibleRequests = requests.take(_visibleCount).toList();

    return ListView(
      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          color: const Color(0xFFF4F5F7),
          child: Text(
            'Đã gửi (${requests.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),

        // LIST
        ...visibleRequests.map((request) {
          final isLoading = provider.isActionLoading(request.addresseeId);

          return RequestItemWidget(
            name: request.addresseeName,
            message: 'Đã gửi lời mời kết bạn',
            avatar: '',
            isReceived: false,
            isRecalled: false, // 🔥 không fake state nữa

            // THU HỒI
            onRecall: isLoading
                ? null
                : () async {
                    try {
                      await provider.cancelFriendRequest(
                        request.addresseeId,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },

            // GỬI LẠI
            onAddFriend: isLoading
                ? null
                : () async {
                    try {
                      await provider.sendFriendRequest(
                        request.addresseeId,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
          );
        }),

        // XEM THÊM
        if (_visibleCount < requests.length)
          InkWell(
            onTap: () {
              setState(() {
                _visibleCount += 10;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "XEM THÊM ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}