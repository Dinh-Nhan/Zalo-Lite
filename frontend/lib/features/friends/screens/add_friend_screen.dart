import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  bool _isLoading = false; // Biến trạng thái chặn spam và bật loading

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() => _isInputNotEmpty = _phoneController.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _findUser() async {
    // Nếu đang trong quá trình tìm kiếm thì block hoàn toàn, không chạy code phía dưới
    if (_isLoading) return; 

    setState(() {
      _isLoading = true;
    });

    // Tạo hiệu ứng đợi mượt mà và chặn spam tối thiểu trong 1-2 giây
    final Future delayFuture = Future.delayed(const Duration(milliseconds: 1500));

    try {
      final email = _phoneController.text.trim();

      if (email.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Email hiện tại của user đăng nhập
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

      // Trường hợp tự tìm chính mình
      if (currentUserEmail != null &&
          email.toLowerCase() == currentUserEmail.toLowerCase()) {
        
        await delayFuture; // Chờ đủ thời gian loading
        if (!mounted) return;
        
        setState(() => _isLoading = false); 
        context.push('/my-profile');
        return;
      }

      final provider = context.read<FriendProvider>();
      final user = await provider.findUserByEmail(email);

      await delayFuture; // Chờ đủ thời gian loading để UI không bị giật lag
      if (!mounted) return;

      if (user == null) {
        setState(() => _isLoading = false); // Mở khóa nút bấm

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Người dùng chưa đăng kí tài khoản hoặc không cho phép tìm kiếm',
            ),
          ),
        );
        return;
      }
      
      setState(() => _isLoading = false); // Mở khóa trước khi chuyển tiếp trang
      context.push(
        '/demo-profile',
        extra: user,
      );
    } catch (e) {
      debugPrint("LOI: $e");
      
      await delayFuture;
      if (mounted) {
        setState(() => _isLoading = false); // Giải phóng nút khi có lỗi hệ thống

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        titleSpacing: 8,
        title: const Text("Thêm bạn", style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: _buildQRCard(),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _buildPhoneInput(),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16),
            child: Divider(height: 0.5, color: Color(0xFFE5E9F0)),
          ),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildOptionItem(Icons.qr_code_scanner_rounded, "Quét mã QR"),
                _buildOptionItem(Icons.person_search_rounded, "Bạn bè có thể quen"),
              ],
            ),
          ),
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
    // Điều kiện active nút: Input có chữ VÀ hệ thống KHÔNG nằm trong trạng thái loading
    final bool isButtonEnabled = _isInputNotEmpty && !_isLoading;

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
                      enabled: !_isLoading, // Disable luôn ô nhập văn bản khi đang tìm kiếm
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
                  if (_isInputNotEmpty && !_isLoading)
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
            backgroundColor: isButtonEnabled ? const Color(0xFF0068FF) : const Color(0xFFE5E9F0),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : IconButton(
                    // Truyền null vào onPressed sẽ lập tức disable nút bấm theo cơ chế của Flutter
                    icon: Icon(
                      Icons.arrow_forward, 
                      color: isButtonEnabled ? Colors.white : Colors.grey.shade400
                    ),
                    onPressed: isButtonEnabled ? _findUser : null,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
      leading: Icon(icon, color: const Color(0xFF0068FF), size: 26),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
      // Vô hiệu hóa sự kiện bấm của các option khi đang trong quá trình tải dữ liệu
      onTap: _isLoading ? null : () {
        // Xử lý sự kiện bấm thông thường ở đây
      },
    );
  }
}