import 'package:flutter/material.dart';
import '../../models/chat/conversation.dart';
import '../../models/chat/participant.dart';

class GroupInfoScreen extends StatefulWidget {
  final Conversation conversation;

  const GroupInfoScreen({Key? key, required this.conversation})
    : super(key: key);

  @override
  _GroupInfoScreenState createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late Conversation _conversation;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Thông tin nhóm', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Group header
            _buildGroupHeader(),
            SizedBox(height: 8),

            // Group actions
            _buildGroupActions(),
            SizedBox(height: 8),

            // Members
            _buildMembersSection(),
            SizedBox(height: 8),

            // Media & Files
            _buildMediaSection(),
            SizedBox(height: 8),

            // Settings
            _buildSettingsSection(),
            SizedBox(height: 8),

            // Danger zone
            _buildDangerZone(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    _conversation.groupAvatarUrl?.isNotEmpty == true
                    ? NetworkImage(_conversation.groupAvatarUrl!)
                    : null,
                backgroundColor: Colors.blue[100],
                child: _conversation.groupAvatarUrl?.isEmpty != false
                    ? Icon(Icons.group, size: 50, color: Colors.blue)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _conversation.groupName ?? 'Nhóm',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            '${_conversation.participants.length} thành viên',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          if (_conversation.groupDescription?.isNotEmpty == true) ...[
            SizedBox(height: 12),
            Text(
              _conversation.groupDescription!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupActions() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.search,
            label: 'Tìm kiếm',
            onTap: _searchInConversation,
          ),
          _buildActionButton(
            icon: _conversation.isMuted ? Icons.volume_off : Icons.volume_up,
            label: _conversation.isMuted ? 'Bật thông báo' : 'Tắt thông báo',
            onTap: () => _toggleMute(!_conversation.isMuted),
          ),
          _buildActionButton(
            icon: Icons.push_pin,
            label: 'Ghim',
            onTap: _togglePin,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thành viên (${_conversation.participants.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addMembers,
                  icon: Icon(Icons.person_add, size: 20),
                  label: Text('Thêm'),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _conversation.participants.length,
            itemBuilder: (context, index) {
              final participant = _conversation.participants[index];
              return _buildMemberTile(participant);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Participant participant) {
    final isAdmin = participant.role == 'admin';

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: participant.avatar.isNotEmpty
                ? NetworkImage(participant.avatar)
                : null,
            backgroundColor: Colors.grey[300],
            child: participant.avatar.isEmpty
                ? Text(participant.userName[0].toUpperCase())
                : null,
          ),
          if (participant.isOnline)
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              participant.displayName,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (isAdmin)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Quản trị viên',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        participant.isOnline ? 'Đang hoạt động' : 'Không hoạt động',
        style: TextStyle(fontSize: 12),
      ),
      trailing: PopupMenuButton(
        icon: Icon(Icons.more_vert),
        itemBuilder: (context) => [
          PopupMenuItem(child: Text('Xem trang cá nhân'), value: 'profile'),
          if (!isAdmin)
            PopupMenuItem(
              child: Text('Đặt làm quản trị viên'),
              value: 'make_admin',
            ),
          if (!isAdmin)
            PopupMenuItem(
              child: Text('Xóa khỏi nhóm', style: TextStyle(color: Colors.red)),
              value: 'remove',
            ),
        ],
        onSelected: (value) =>
            _handleMemberAction(participant, value.toString()),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.photo_library, color: Colors.blue),
            title: Text('Ảnh/Video'),
            trailing: Icon(Icons.chevron_right),
            onTap: _viewMedia,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.insert_drive_file, color: Colors.blue),
            title: Text('Tệp'),
            trailing: Icon(Icons.chevron_right),
            onTap: _viewFiles,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.link, color: Colors.blue),
            title: Text('Liên kết'),
            trailing: Icon(Icons.chevron_right),
            onTap: _viewLinks,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.edit, color: Colors.blue),
            title: Text('Chỉ quản trị viên có thể gửi tin nhắn'),
            value: _conversation.onlyAdminCanSend,
            onChanged: _toggleOnlyAdminCanSend,
          ),
          Divider(height: 1),
          SwitchListTile(
            secondary: Icon(Icons.info, color: Colors.blue),
            title: Text('Chỉ quản trị viên có thể sửa thông tin nhóm'),
            value: _conversation.onlyAdminCanEditInfo,
            onChanged: _toggleOnlyAdminCanEditInfo,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.color_lens, color: Colors.blue),
            title: Text('Đổi chủ đề'),
            trailing: Icon(Icons.chevron_right),
            onTap: _changeTheme,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.wallpaper, color: Colors.blue),
            title: Text('Đổi hình nền'),
            trailing: Icon(Icons.chevron_right),
            onTap: _changeBackground,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              'Xóa lịch sử trò chuyện',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _clearHistory,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Rời khỏi nhóm', style: TextStyle(color: Colors.red)),
            onTap: _leaveGroup,
          ),
        ],
      ),
    );
  }

  // Actions
  void _searchInConversation() {
    _showInfo('Tính năng tìm kiếm đang được phát triển');
  }

  void _toggleMute(bool value) {
    setState(() {
      // TODO: Update via API
    });
    _showSuccess(value ? 'Đã tắt thông báo' : 'Đã bật thông báo');
  }

  void _togglePin() {
    _showInfo('Đã ghim cuộc hội thoại');
  }

  void _addMembers() {
    _showInfo('Tính năng thêm thành viên đang được phát triển');
  }

  void _handleMemberAction(Participant participant, String action) {
    switch (action) {
      case 'profile':
        _showInfo('Xem trang cá nhân ${participant.displayName}');
        break;
      case 'make_admin':
        _confirmMakeAdmin(participant);
        break;
      case 'remove':
        _confirmRemoveMember(participant);
        break;
    }
  }

  void _confirmMakeAdmin(Participant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đặt làm quản trị viên'),
        content: Text(
          'Bạn có chắc chắn muốn đặt ${participant.displayName} làm quản trị viên?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess(
                'Đã đặt ${participant.displayName} làm quản trị viên',
              );
            },
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(Participant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa thành viên'),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${participant.displayName} khỏi nhóm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Đã xóa ${participant.displayName} khỏi nhóm');
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewMedia() {
    _showInfo('Tính năng xem ảnh/video đang được phát triển');
  }

  void _viewFiles() {
    _showInfo('Tính năng xem tệp đang được phát triển');
  }

  void _viewLinks() {
    _showInfo('Tính năng xem liên kết đang được phát triển');
  }

  void _toggleOnlyAdminCanSend(bool value) {
    setState(() {
      // TODO: Update via API
    });
    _showSuccess(
      value
          ? 'Chỉ quản trị viên có thể gửi tin nhắn'
          : 'Tất cả thành viên có thể gửi tin nhắn',
    );
  }

  void _toggleOnlyAdminCanEditInfo(bool value) {
    setState(() {
      // TODO: Update via API
    });
    _showSuccess(
      value
          ? 'Chỉ quản trị viên có thể sửa thông tin'
          : 'Tất cả thành viên có thể sửa thông tin',
    );
  }

  void _changeTheme() {
    _showInfo('Tính năng đổi chủ đề đang được phát triển');
  }

  void _changeBackground() {
    _showInfo('Tính năng đổi hình nền đang được phát triển');
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa lịch sử trò chuyện'),
        content: Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Đã xóa lịch sử trò chuyện');
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rời khỏi nhóm'),
        content: Text('Bạn có chắc chắn muốn rời khỏi nhóm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close group info
              Navigator.pop(context); // Close chat screen
              _showSuccess('Đã rời khỏi nhóm');
            },
            child: Text('Rời nhóm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
