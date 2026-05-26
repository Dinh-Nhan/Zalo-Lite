import 'package:flutter/material.dart';

class RequestItemWidget extends StatelessWidget {
  final String name;
  final String message;
  final String avatar;

  final bool isReceived;

  final bool isAccepted;

  final bool isRecalled;

  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  final VoidCallback? onRecall;
  final VoidCallback? onAddFriend;

  final VoidCallback? onMessage;

  const RequestItemWidget({
    super.key,
    required this.name,
    required this.message,
    required this.avatar,
    required this.isReceived,

    this.isAccepted = false,

    this.isRecalled = false,

    this.onAccept,
    this.onDecline,

    this.onRecall,
    this.onAddFriend,

    this.onMessage,
  });

  @override
Widget build(BuildContext context) {
  final bool showTwoButtons =
      isReceived && !isAccepted;

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(
        bottom: BorderSide(
          color: Color(0xFFEAEAEA),
        ),
      ),
    ),

    child: Column(
      children: [
        // =========================================
        // HÀNG CHÍNH
        // =========================================

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            // AVATAR
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  const Color(0xFFDDEBFF),

              backgroundImage:
                  avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,

              child:
                  avatar.isEmpty
                      ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF0091FF),
                          fontWeight:
                              FontWeight.bold,
                        ),
                      )
                      : null,
            ),

            const SizedBox(width: 12),

            // =====================================
            // TEXT
            // =====================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // =====================================
            // NÚT 1 BUTTON
            // =====================================

            if (!showTwoButtons)
              _buildSingleActionButton(),
          ],
        ),

        // =========================================
        // 2 BUTTONS
        // =========================================

        if (showTwoButtons) ...[
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildZaloButton(
                  text: 'Từ chối',
                  bgColor:
                      const Color(0xFFF1F2F4),
                  textColor: Colors.black87,
                  onTap: onDecline,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildZaloButton(
                  text: 'Đồng ý',
                  bgColor:
                      const Color(0xFFE5F2FF),
                  textColor:
                      const Color(0xFF0091FF),
                  onTap: onAccept,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
Widget _buildSingleActionButton() {
  // =========================
  // NHẮN TIN
  // =========================

  if (isAccepted) {
    return _buildZaloButton(
      text: 'Nhắn tin',
      bgColor: const Color(0xFFE5F2FF),
      textColor: const Color(0xFF0091FF),
      onTap: onMessage,
      width: 100,
    );
  }

  // =========================
  // THU HỒI
  // =========================

  if (!isReceived && !isRecalled) {
    return _buildZaloButton(
      text: 'Thu hồi',
      bgColor: const Color(0xFFF1F2F4),
      textColor: Colors.black87,
      onTap: onRecall,
      width: 100,
    );
  }

  // =========================
  // KẾT BẠN LẠI
  // =========================

  if (!isReceived && isRecalled) {
    return _buildZaloButton(
      text: 'Kết bạn lại',
      bgColor: const Color(0xFFE5F2FF),
      textColor: const Color(0xFF0091FF),
      onTap: onAddFriend,
      width: 110,
    );
  }

  return const SizedBox();
}

Widget _buildZaloButton({
  required String text,
  required Color bgColor,
  required Color textColor,
  required VoidCallback? onTap,
  double width = double.infinity,
}) {
  return SizedBox(
    height: 36,
    width: width,
    child: ElevatedButton(
      onPressed: onTap,

      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(18),
        ),
      ),

      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
}