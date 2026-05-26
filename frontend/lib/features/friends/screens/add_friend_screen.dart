import 'package:flutter/material.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isInputNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() => _isInputNotEmpty = _phoneController.text.trim().isNotEmpty);
    });
  }
  
  Future<void> _findUser() async {
    try {
      final email = _phoneController.text.trim();

      if (email.isEmpty) return;

      debugPrint("B1");

      final provider = context.read<FriendProvider>();

      final user = await provider.findUserByEmail(email);

      debugPrint("B4");

      if (user == null) {
        debugPrint("B5");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Người dùng chưa đăng kí tài khoản hoặc không cho phép tìm kiếm',
            ),
          ),
        );

        return;
      }

      debugPrint("B6");

      if (!mounted) return;

      context.push(
        '/demo-profile',
        extra: user,
      );
    } catch (e) {
      debugPrint("LOI: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4), // Nền xám nhạt tổng thể
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text("Thêm bạn", style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // --- VÙNG 1: Nền xám chứa Card QR ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: _buildQRCard(),
          ),

          // --- VÙNG 2: Dải trắng chứa Input SĐT ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _buildPhoneInput(),
          ),

          // const SizedBox(height: 12), // Khoảng đệm xám phân cách lớn hơn một chút
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16), // Divider thụt đầu dòng chuẩn
            child: Divider(height: 0.5, color: Color(0xFFE5E9F0)),
          ),
          // --- VÙNG 3: Dải trắng chứa các chức năng phụ ---
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildOptionItem(Icons.qr_code_scanner_rounded, "Quét mã QR"),
                // const SizedBox(height: 12),
                _buildOptionItem(Icons.person_search_rounded, "Bạn bè có thể quen"),
              ],
            ),
          ),

          // --- VÙNG 4: Nền xám cuối cùng ---
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24, top: 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Xem lời mời kết bạn đã gửi tại trang Danh bạ Zalo",
                  style: TextStyle(color: Color(0xFF767E89), fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.62,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF4A689A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Khánh Hà", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.black),
            ),
            const SizedBox(height: 16),
            const Text("Quét mã để thêm bạn Zalo với tôi", style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhoneInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0068FF).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: "Nhập email muốn tìm",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  if (_isInputNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
                      onPressed: () {
                        _phoneController.clear();
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: _isInputNotEmpty ? const Color(0xFF0068FF) : const Color(0xFFE5E9F0),
            child: IconButton(
              icon: Icon(Icons.arrow_forward, color: _isInputNotEmpty ? Colors.white : Colors.grey.shade400),
              onPressed: _isInputNotEmpty
              ? _findUser
              : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
      leading: Icon(icon, color: const Color(0xFF0068FF), size: 26),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
      // trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
      onTap: () {
        
      },
    );}
}