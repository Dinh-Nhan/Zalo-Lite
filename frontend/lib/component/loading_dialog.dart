import 'package:flutter/material.dart';

class LoadingDialog {
  static void show(BuildContext context, {String message = "Đang xử lý..."}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép đóng khi chạm ra ngoài
      barrierColor: Colors.black26, // Làm tối nền một chút
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9), // Trắng mờ nhẹ
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}