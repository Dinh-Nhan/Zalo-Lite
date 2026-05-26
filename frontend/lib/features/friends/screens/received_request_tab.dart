import 'package:flutter/material.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:provider/provider.dart';
import 'package:frontend/views/chat/chat_detail_view.dart';
import 'request_item.dart';

class ReceivedRequestsTab extends StatefulWidget {
  const ReceivedRequestsTab({super.key});

  @override
  State<ReceivedRequestsTab> createState() =>
      _ReceivedRequestsTabState();
}

class _ReceivedRequestsTabState
    extends State<ReceivedRequestsTab> {
  int _visibleCount = 2;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final provider =
          context.read<FriendProvider>();

      await provider.loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<FriendProvider>();

    final requests =
        provider.pendingReceived;

    // Loading
    if (provider.requestsState ==
        LoadingState.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error
    if (provider.requestsState ==
        LoadingState.error) {
      return Center(
        child: Text(
          provider.errorMessage ??
              'Có lỗi xảy ra',
        ),
      );
    }

    // Empty
    if (requests.isEmpty) {
      return const Center(
        child: Text(
          'Không có lời mời kết bạn',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final visibleRequests =
        requests.take(_visibleCount).toList();

    return ListView(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          color: const Color(0xFFF4F5F7),
          child: Text(
            'Lời mời (${requests.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),

        // Danh sách request
        ...visibleRequests.map(
          (request) => RequestItemWidget(
            name:
                request.senderName ??
                'Người dùng',

            message:
                request.status == 'accepted'
                    ? 'Các bạn đã trở thành bạn bè'
                    : 'Muốn kết bạn',

            avatar:
                request.senderAvatar ?? '',

            isReceived: true,

            isAccepted:
                request.status == 'accepted',

            // =====================
            // ACCEPT
            // =====================

            onAccept: () async {
              await provider.acceptFriendRequest(
                request.senderId,
              );
            },

            // =====================
            // DECLINE
            // =====================

            onDecline: () async {
              await provider.declineFriendRequest(
                request.senderId,
              );
            },

            // =====================
            // MESSAGE
            // =====================

            onMessage: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailView(
                    conversationId:
                        request.senderId,

                    contactName:
                        request.senderName ??
                        'Người dùng',

                    avatarColor:
                        Colors.blue,
                  ),
                ),
              );
            },
          ),
        ),
        // Xem thêm
        if (_visibleCount < requests.length)
          InkWell(
            onTap: () {
              setState(() {
                _visibleCount += 10;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    "XEM THÊM ",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}