import 'package:flutter/material.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:provider/provider.dart';

enum RelationStatus {
  none,
  received,
  sent,
  friend,
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.user});

  final UserSearchModel user;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const Color primaryColor = Color(0xFF0068FF);
  static const Color lightBlue = Color(0xFFE5EFFF);
  static const Color backgroundColor = Color(0xFFF1F2F4);
  static const Color greyText = Color(0xFF767E89);

  RelationStatus _getRelationshipStatus(FriendProvider provider) {
    final userId = widget.user.id;

    if (provider.isFriend(userId)) {
      return RelationStatus.friend;
    }

    if (provider.getSentRequest(userId) != null) {
      return RelationStatus.sent;
    }

    if (provider.getReceivedRequest(userId) != null) {
      return RelationStatus.received;
    }

    return RelationStatus.none;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    final status = _getRelationshipStatus(provider);
    final isFriend = status == RelationStatus.friend;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 50),
            _buildUserInfo(provider),
            SizedBox(height: isFriend ? 10 : 24),
            _buildDynamicActionArea(status),
          ],
        ),
      ),
    );
  }

  // ================= APP BAR =================

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://picsum.photos/800/500'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const Positioned(
          bottom: -40,
          child: CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage('https://picsum.photos/200'),
          ),
        ),
      ],
    );
  }

  // ================= USER INFO =================

  Widget _buildUserInfo(FriendProvider provider) {
    final status = _getRelationshipStatus(provider);
    final isFriend = status == RelationStatus.friend;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.user.fullName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 20),
          ],
        ),

        if (!isFriend) ...[
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Bạn chưa thể xem nhật ký của đối phương khi chưa là bạn bè",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: greyText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ================= VIEW SWITCH =================

  Widget _buildDynamicActionArea(RelationStatus status) {
    switch (status) {
      case RelationStatus.received:
        return _buildReceivedView();
      case RelationStatus.sent:
        return _buildSentView();
      case RelationStatus.friend:
        return _buildFriendView();
      default:
        return _buildNoneView();
    }
  }

  // ================= NONE =================

  Widget _buildNoneView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              text: "Nhắn tin",
              icon: Icons.chat_bubble_outline,
              bgColor: lightBlue,
              textColor: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(
            icon: Icons.person_add_alt_1_outlined,
            onTap: () async {
              try {
                await context
                    .read<FriendProvider>()
                    .sendFriendRequest(widget.user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi lời mời kết bạn')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= RECEIVED =================

  Widget _buildReceivedView() {
    return _buildInfoCard(
      title: "Lời mời kết bạn",
      message: "Người này muốn kết bạn với bạn.",
      bottomWidget: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await context
                    .read<FriendProvider>()
                    .declineFriendRequest(widget.user.id);
              },
              child: _buildButton(
                text: "Từ chối",
                bgColor: backgroundColor,
                textColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await context
                    .read<FriendProvider>()
                    .acceptFriendRequest(widget.user.id);
              },
              child: _buildButton(
                text: "Đồng ý",
                bgColor: primaryColor,
                textColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SENT =================

  Widget _buildSentView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              text: "Nhắn tin",
              icon: Icons.chat_bubble_outline,
              bgColor: lightBlue,
              textColor: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await context
                    .read<FriendProvider>()
                    .cancelFriendRequest(widget.user.id);
              },
              child: _buildButton(
                text: "Hủy lời mời",
                bgColor: Colors.white,
                textColor: Colors.black,
                hasBorder: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= FRIEND =================

  Widget _buildFriendView() {
    return _buildInfoCard(
      title: "Bạn bè",
      message: "Hai bạn đã trở thành bạn bè.",
    );
  }

  // ================= CARD =================

  Widget _buildInfoCard({
    required String title,
    required String message,
    Widget? bottomWidget,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
<<<<<<< HEAD
            color: Colors.black.withValues(alpha: 0.05),
=======
            color: Colors.black.withOpacity(0.05),
>>>>>>> origin/dev
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(fontSize: 14)),
          if (bottomWidget != null) ...[
            const SizedBox(height: 20),
            bottomWidget,
          ]
        ],
      ),
    );
  }

  // ================= BUTTON =================

  Widget _buildButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    IconData? icon,
    bool hasBorder = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: hasBorder ? Border.all(color: Colors.black12) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 8),
          ],
          Text(text,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 48,
            decoration: BoxDecoration(
              color: isHovered
<<<<<<< HEAD
                  ? primaryColor.withValues(alpha: 0.15)
=======
                  ? Colors.blue.withOpacity(0.15)
>>>>>>> origin/dev
                  : backgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHovered
<<<<<<< HEAD
                    ? primaryColor.withValues(alpha: 0.4)
=======
                    ? primaryColor.withOpacity(0.4)
>>>>>>> origin/dev
                    : Colors.transparent,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: Icon(
                  icon,
                  color: isHovered ? primaryColor : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}