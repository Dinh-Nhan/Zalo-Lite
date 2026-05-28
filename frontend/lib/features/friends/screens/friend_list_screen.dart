import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Danh sách bạn bè',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Chưa có bạn bè nào',
          style: TextStyle(color: Color(0xFF65676B), fontSize: 15),
        ),
      ),
    );
  }
}
