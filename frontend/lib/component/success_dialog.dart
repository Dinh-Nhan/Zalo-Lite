import 'dart:async';
import 'package:flutter/material.dart';

class SuccessDialog extends StatefulWidget {
  final VoidCallback onRedirect;

  const SuccessDialog({super.key, required this.onRedirect});

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();

  // Hàm static để gọi dialog dễ dàng từ view
  static void show(BuildContext context, VoidCallback onRedirect) {
    showDialog(
      context: context,
      barrierDismissible: true, // Cho phép tap để vào tài khoản liền
      builder: (context) => SuccessDialog(onRedirect: onRedirect),
    ).then((_) => onRedirect()); // Nếu đóng dialog thì thực hiện redirect
  }
}

class _SuccessDialogState extends State<SuccessDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Sau 2 giây tự động đóng dialog và chuyển trang
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell( // Sử dụng InkWell để bắt sự kiện tap toàn vùng dialog
        onTap: () {
          _timer?.cancel();
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF66BB6A), // Màu xanh lá nhẹ chuẩn Zalo
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                "Tạo tài khoản mới thành công",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}