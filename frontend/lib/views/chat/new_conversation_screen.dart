import 'package:flutter/material.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/services/chat/chat_service.dart';
import 'package:frontend/views/chat/chat_screen.dart';

class NewConversationScreen extends StatefulWidget {
  final String type;

  const NewConversationScreen({super.key, required this.type});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  List<UserItem> _allUsers = [];
  List<UserItem> _filteredUsers = [];
  final List<UserItem> _selectedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final friends = await FriendService.getFriends();
      setState(() {
        _allUsers = friends
            .map((f) => UserItem(id: f.friendId, name: f.fullName, avatar: f.avatar))
            .toList();
        _filteredUsers = _allUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers
            .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleUser(UserItem user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        if (widget.type == 'private' && _selectedUsers.isNotEmpty) {
          _selectedUsers.clear();
        }
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _createConversation() async {
    if (_selectedUsers.isEmpty) {
      _showError('Vui lòng chọn ít nhất một người');
      return;
    }

    if (widget.type == 'group' && _selectedUsers.length < 2) {
      _showError('Nhóm phải có ít nhất 3 thành viên (bao gồm bạn)');
      return;
    }

    if (widget.type == 'group' && _groupNameController.text.trim().isEmpty) {
      _showError('Vui lòng nhập tên nhóm');
      return;
    }

    try {
      final conversation = await ChatService().createConversation(
        type: widget.type,
        participantIds: _selectedUsers.map((u) => u.id).toList(),
        groupName: widget.type == 'group' ? _groupNameController.text.trim() : null,
      );

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(conversation: conversation)),
      );
    } catch (e) {
      _showError('Không thể tạo ${widget.type == 'group' ? 'nhóm' : 'cuộc hội thoại'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.type == 'group' ? 'Tạo nhóm' : 'Tin nhắn mới',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          if (widget.type == 'group' ? _selectedUsers.length >= 2 : _selectedUsers.isNotEmpty)
            TextButton(
              onPressed: widget.type == 'group' ? _showGroupNameDialog : _createConversation,
              child: Text(
                widget.type == 'group' ? 'Tiếp' : 'Tạo',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          if (_selectedUsers.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
                              backgroundColor: Colors.grey[300],
                              child: user.avatar.isEmpty ? Text(user.name[0].toUpperCase()) : null,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _toggleUser(user),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            user.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Không tìm thấy người dùng', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected = _selectedUsers.contains(user);
                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
                                  backgroundColor: Colors.grey[300],
                                  child: user.avatar.isEmpty ? Text(user.name[0].toUpperCase()) : null,
                                ),
                                if (user.isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              user.isOnline ? 'Đang hoạt động' : 'Không hoạt động',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: widget.type == 'group'
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleUser(user),
                                    shape: const CircleBorder(),
                                  )
                                : null,
                            onTap: () => _toggleUser(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showGroupNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tên nhóm'),
        content: TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            hintText: 'Nhập tên nhóm...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createConversation();
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class UserItem {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;

  UserItem({
    required this.id,
    required this.name,
    required this.avatar,
    this.isOnline = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
