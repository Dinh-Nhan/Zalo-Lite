import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/chat/conversation.dart';
import '../../widgets/chat/conversation_tile.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Conversation> _allConversations = [];
  List<Conversation> _conversations = [];
  List<Conversation> _groups = [];
  bool _isLoading = true;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {});
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load from API
      // final conversations = await chatService.getConversations();

      // Mock data for demo
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _allConversations = [];
        _filterConversations();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Không thể tải danh sách hội thoại');
    }
  }

  void _filterConversations() {
    final query = _searchQuery.toLowerCase();

    final filtered = _allConversations.where((conv) {
      if (query.isEmpty) return true;
      return conv.displayName.toLowerCase().contains(query);
    }).toList();

    _conversations = filtered.where((c) => c.type == 'private').toList();
    _groups = filtered.where((c) => c.type == 'group').toList();

    // Sort: pinned first, then by update time
    _conversations.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    _groups.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tin nhắn',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.black),
            onPressed: _showNewConversationOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: 'Tất cả'),
            Tab(text: 'Nhóm'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConversationList(_conversations),
                _buildConversationList(_groups),
              ],
            ),
    );
  }

  Widget _buildConversationList(List<Conversation> conversations) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'Chưa có cuộc hội thoại nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showNewConversationOptions,
              icon: Icon(Icons.add),
              label: Text('Tạo cuộc hội thoại mới'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return ConversationTile(
            conversation: conversation,
            onTap: () => _openChat(conversation),
            onDelete: _deleteConversation,
            onPin: _togglePin,
            onMute: _toggleMute,
          );
        },
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: ConversationSearchDelegate(_allConversations),
    );
  }

  void _showNewConversationOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.person_add, color: Colors.blue),
              ),
              title: Text('Tin nhắn mới'),
              subtitle: Text('Bắt đầu cuộc trò chuyện 1-1'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NewConversationScreen(type: 'private'),
                  ),
                );
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.group_add, color: Colors.green),
              ),
              title: Text('Tạo nhóm'),
              subtitle: Text('Tạo nhóm chat mới'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewConversationScreen(type: 'group'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    ).then((_) => _loadConversations());
  }

  void _deleteConversation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa cuộc hội thoại'),
        content: Text('Bạn có chắc chắn muốn xóa cuộc hội thoại này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete conversation
              Navigator.pop(context);
              _showSuccess('Đã xóa cuộc hội thoại');
              _loadConversations();
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _togglePin(String conversationId) {
    // TODO: Toggle pin
    _showSuccess('Đã ghim cuộc hội thoại');
    _loadConversations();
  }

  void _toggleMute(String conversationId) {
    // TODO: Toggle mute
    _showSuccess('Đã tắt thông báo');
    _loadConversations();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}

class ConversationSearchDelegate extends SearchDelegate<Conversation?> {
  final List<Conversation> conversations;

  ConversationSearchDelegate(this.conversations);

  @override
  String get searchFieldLabel => 'Tìm kiếm...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = conversations.where((conv) {
      return conv.displayName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final conversation = results[index];
        return ConversationTile(
          conversation: conversation,
          onTap: () => close(context, conversation),
        );
      },
    );
  }
}
