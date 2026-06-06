import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/features/friends/widgets/demo_bio.dart';
import 'package:frontend/features/friends/widgets/my_profile.dart';
import 'package:go_router/go_router.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isInputNotEmpty = false;
  bool _isLoading = false;

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
    if (_isLoading) return;

    final email = _phoneController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<FriendProvider>();
      final user = await provider.findUserByEmail(email);

      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Người dùng chưa đăng kí tài khoản hoặc không cho phép tìm kiếm'),
          ),
        );
        return;
      }

      context.push('/demo-profile', extra: user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text(
          'Thêm bạn',
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
        ),
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
                _buildOptionItem(Icons.qr_code_scanner_rounded, 'Quét mã QR'),
                _buildOptionItem(Icons.contacts_outlined, 'Danh bạ máy'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard() {
    return Center(
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.qr_code_2_rounded, size: 72, color: Color(0xFF0091FF)),
            SizedBox(height: 10),
            Text('Mã QR của tôi', style: TextStyle(fontWeight: FontWeight.w600)),
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
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Nhập email để tìm bạn',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _findUser(),
            ),
          ),
          TextButton(
            onPressed: _isInputNotEmpty && !_isLoading ? _findUser : null,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEAF4FF),
        child: Icon(icon, color: const Color(0xFF0091FF)),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (title == 'Quét mã QR') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfileScreen()));
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(
                user: UserSearchModel(
                  id: '',
                  fullName: 'Demo',
                  email: '',
                  avatar: '',
                  status: false,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
