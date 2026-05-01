import 'package:flutter/material.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Button action nhanh để hiển thị lời mời kết bạn
          _buildFriendRequest(),
        ],
      ),
    );
  }
}

Widget _buildFriendRequest() {
  return Container(
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        ElevatedButton(
          onPressed: null,
          child: Row(
            children: [
              Icon(Icons.person, size: 40),
              const SizedBox(width: 10),
              const Text("Lời mời kết bạn"),
            ],
          ),
        ),
      ],
    ),
  );
}
