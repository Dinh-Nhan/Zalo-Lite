import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';

class ConfirmPhoneSheet extends StatelessWidget {
  final String phone;
  final VoidCallback onContinue;

  const ConfirmPhoneSheet({
    super.key,
    required this.phone,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 290,
          padding: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// TITLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Nhận mã xác thực qua số $phone",
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// DESCRIPTION
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Zalo sẽ gửi mã xác thực cho bạn qua số điện thoại này",
                  textAlign: TextAlign.start,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),

              /// BUTTON CONTINUE
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: onContinue,
                  child: const Text(
                    "Tiếp tục",
                    style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const Divider(height: 1),

              /// BUTTON CHANGE NUMBER
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Đổi số khác",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}