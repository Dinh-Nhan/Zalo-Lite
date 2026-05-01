import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/component/loading_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_colors.dart';

class EnterNameView extends StatefulWidget {
  const EnterNameView({super.key});

  @override
  State<EnterNameView> createState() => _EnterNameViewState();
}

class _EnterNameViewState extends State<EnterNameView> {
  final TextEditingController _nameController = TextEditingController();
  
  // Các biến trạng thái điều kiện
  bool _isLongEnough = false;
  bool _hasNoNumbers = true;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
  }

  void _validateName() {
    final text = _nameController.text.trim();
    
    setState(() {
      // 1. Kiểm tra độ dài 2-40
      _isLongEnough = text.length >= 2 && text.length <= 40;
      
      // 2. Kiểm tra không chứa số
      _hasNoNumbers = !RegExp(r'\d').hasMatch(text);
      
      // Nút sáng khi thỏa mãn tất cả (và không để trống)
      _isButtonEnabled = text.isNotEmpty && _isLongEnough && _hasNoNumbers;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => context.go('/reset-password'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Nhập tên Zalo",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "Hãy dùng tên thật để bạn bè dễ nhận ra bạn",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 30),
            
            // TextField nhập tên
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: "Nguyễn Văn A",
                hintStyle: TextStyle(color: Colors.grey.shade300),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                // Thêm đoạn này để hiện nút X xóa nhanh
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                        onPressed: () {
                          _nameController.clear();
                          _validateName(); 
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Các dòng điều kiện
            _buildConditionItem("Dài từ 2 đến 40 ký tự", _isLongEnough),
            _buildConditionItem("Không chứa số", _hasNoNumbers),
            _buildConditionItem("Tuân thủ các quy định đặt tên Zalo", true, isLink: true),

            const Spacer(),
            
            // Nút Tiếp tục
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isButtonEnabled
                    ? () async {
                        // 1. Hiện loading
                        LoadingDialog.show(context, message: "Đang xử lý...");

                        // 2. GIẢ LẬP ĐỢI 2 giây để thấy loading xoay
                        await Future.delayed(const Duration(seconds: 2));

                        // 3. Tắt loading
                        if (context.mounted) {
                          LoadingDialog.hide(context);
                        }

                        // 4. Chuyển trang
                        if (context.mounted) {
                          context.go('/personal-info');
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  disabledBackgroundColor: Colors.grey.shade200, // Màu khi chưa đủ điều kiện
                  elevation: 0,
                  shape: const StadiumBorder(), // Bo góc tròn chuẩn Zalo
                ),
                // THIẾU CÁI NÀY LÀ BỊ LỖI:
                child: Text(
                  "Tiếp tục",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isButtonEnabled ? Colors.white : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionItem(String text, bool isMet, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "• ",
            style: TextStyle(color: isMet ? Colors.grey : Colors.red),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(
                    text: text.replaceAll("quy định đặt tên Zalo", ""),
                  ),
                  if (isLink)
                    const TextSpan(
                      text: "quy định đặt tên Zalo",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}