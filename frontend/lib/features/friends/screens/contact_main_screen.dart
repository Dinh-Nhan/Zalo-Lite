import 'package:flutter/material.dart';
import 'package:frontend/component/friend_search_page.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/screens/add_friend_screen.dart';
import 'package:frontend/features/friends/screens/friend_tab_content.dart';
import 'package:frontend/features/friends/screens/group_tab_content.dart';
import 'package:frontend/features/friends/screens/qr_friend_screen.dart';
import 'package:frontend/widgets/search_overlay_screen.dart';

class ContactsMainScreen extends StatefulWidget {
  const ContactsMainScreen({super.key});

  @override
  State<ContactsMainScreen> createState() => _ContactsMainScreenState();
}

class _ContactsMainScreenState extends State<ContactsMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendSearchPage(),
              ),
            );
          },

          child: Container(
            height: 40,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),

            child: Row(
              children: [
                const SizedBox(width: 12),

                Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),

                const SizedBox(width: 10),

                Text(
                  'Tìm kiếm',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrFriendScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 24),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddFriendScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0091FF),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label, 
              indicatorPadding: const EdgeInsets.symmetric(horizontal: -80),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: const [
                Tab(text: "Bạn bè"),
                Tab(text: "Nhóm"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                 FriendTabView(),
                 GroupTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}