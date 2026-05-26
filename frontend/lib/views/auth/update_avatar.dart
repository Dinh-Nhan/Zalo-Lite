import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:frontend/component/loading_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:go_router/go_router.dart';

class UpdateAvatarView extends StatefulWidget {
  const UpdateAvatarView({super.key});


  @override
  State<UpdateAvatarView> createState() => _UpdateAvatarViewState();
}

class _UpdateAvatarViewState extends State<UpdateAvatarView> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      // Khi gọi hàm này, hệ thống sẽ tự động hiển thị popup xin quyền truy cập ảnh/tệp
      final XFile? selectedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (selectedImage != null) {
        setState(() {
          _imageFile = selectedImage;
        });
        // Sau khi chọn ảnh xong, bạn có thể tự động hiện SuccessDialog hoặc đợi bấm nút tiếp theo
      }
    } catch (e) {
      debugPrint("Lỗi truy cập kho ảnh: $e");
    }
  }
Future<void> _uploadAvatar() async {
  try {
    LoadingDialog.show(context, message: "Đang tải ảnh...");
    //Gọi API upload ảnh lên server, sau đó cập nhật URL ảnh đại diện vào Database
    // await AuthService.updateAvatar(_imageFile!);

    if (mounted) {
      LoadingDialog.hide(context);
      context.go('/chat-list');
    }
  } catch (e) {
    if (mounted) {
      LoadingDialog.hide(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi upload: $e")),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text("Cập nhật ảnh đại diện", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Đặt ảnh đại diện để mọi người nhận ra bạn", 
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 40),
            
            // Hiển thị Avatar (Ảnh đã chọn hoặc chữ cái mặc định)
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: _imageFile == null
                ? CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.green,
                    child: const Text(
                      "TH",
                      style: TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  )
                : Container(
                    width: 140,
                    height: 140,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: kIsWeb
                        ? Image.network(
                            _imageFile!.path, // web dùng network
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(_imageFile!.path), // mobile dùng file
                            fit: BoxFit.contain,
                          ),
                  ),
              ),
            ),
            // NÚT 1
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: const StadiumBorder(),
              ),
              child: Text(
                _imageFile == null ? "Cập nhật" : "Đổi ảnh khác",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            // NÚT THỨ HAI: BỎ QUA (Nhảy sang trang mới)
            ElevatedButton(
              onPressed: () async {
                if (_imageFile == null) {
                  // chưa chọn → skip
                  context.go('/chat-list');
                  return;
                }

                // đã chọn → upload
                await _uploadAvatar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                _imageFile == null ? "Bỏ qua" : "Tiếp tục",
                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}