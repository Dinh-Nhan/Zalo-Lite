import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/profile/providers/profile_provider.dart';
import 'package:frontend/features/profile/services/profile_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/features/newfeed/models/post_model.dart';
import 'package:frontend/features/newfeed/providers/feed_provider.dart';
import 'package:frontend/features/newfeed/widgets/comment_sheet.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String? targetUserId;

  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late String _currentUserId;
  late String _currentUserName;
  late String _currentUserAvatar;

  String? _targetUserId;
  bool _isOwnProfile = true;
  String _targetUserName = '';
  String _targetUserAvatar = '';
  String? _targetUserEmail;

  bool _isLoadingRelationship = false;
  String _relationshipStatus = '';
  String? _friendshipId;

  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedAvatarBytes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCurrentUser();
    _setupTargetUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialProfile();
    });
  }

  void _loadInitialProfile() {
    if (_isOwnProfile) {
      _loadOwnProfile();
    } else {
      _loadOtherUserProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUserName = user.displayName ?? 'User';
      _currentUserAvatar = user.photoURL ?? '';
    } else {
      _currentUserId = '';
      _currentUserName = '';
      _currentUserAvatar = '';
    }
  }

  void _setupTargetUser() {
    _targetUserId = widget.targetUserId;
    _isOwnProfile =
        _targetUserId == null || _targetUserId == _currentUserId;

    if (_isOwnProfile) {
      _targetUserId = _currentUserId;
      _targetUserName = _currentUserName;
      _targetUserAvatar = _currentUserAvatar;
    }
  }

  Future<void> _loadOwnProfile() async {
    if (_targetUserId == null) return;
    if (!mounted) return;
    await context.read<ProfileProvider>().loadProfile(_targetUserId!);
  }

  Future<void> _loadOtherUserProfile() async {
    if (_targetUserId == null) return;

    setState(() => _isLoadingRelationship = true);

    try {
      final provider = context.read<ProfileProvider>();
      final results = await Future.wait([
        ProfileService.getUserPosts(_targetUserId!),
        FriendService.getRelationshipStatus(_targetUserId!),
      ]);

      final posts = results[0] as List<PostModel>;
      final relationship = results[1] as FriendshipModel?;

      provider.setExternalPosts(posts);

      if (!mounted) return;
      setState(() {
        if (posts.isNotEmpty) {
          _targetUserName = posts.first.userName;
          _targetUserAvatar = posts.first.userAvatar;
        }
        _relationshipStatus = relationship?.status ?? '';
        _friendshipId = relationship?.id;
        _isLoadingRelationship = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRelationship = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_isOwnProfile) {
      await context.read<ProfileProvider>().loadProfile(_targetUserId!);
    } else {
      await _loadOtherUserProfile();
    }
  }

  Future<void> _pickAvatarAndPost() async {
    if (!_isOwnProfile) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (!mounted) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AvatarChoiceSheet(imageBytes: bytes),
    );

    if (choice == null || !mounted) return;

    if (choice == 'avatar_only' || choice == 'both') {
      setState(() => _selectedAvatarBytes = bytes);

      try {
        final newAvatarUrl = await AuthService.updateAvatar(image);

        setState(() {
          _currentUserAvatar = newAvatarUrl;
          _selectedAvatarBytes = null;
        });

        await FirebaseAuth.instance.currentUser?.reload();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi ảnh đại diện thành công!'),
            backgroundColor: AppColors.primaryBlue,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _selectedAvatarBytes = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đổi avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (choice == 'post_only' || choice == 'both') {
      context.push('/create-post-avatar', extra: {
        'imageBytes': bytes,
        'imagePath': image.path,
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_targetUserId == null) return;
    setState(() => _isLoadingRelationship = true);
    try {
      await FriendService.sendRequest(addresseeId: _targetUserId!);
      if (!mounted) return;
      await context.read<FriendProvider>().loadFriends();
      if (!mounted) return;
      setState(() {
        _relationshipStatus = 'pending';
        _isLoadingRelationship = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRelationship = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _unfriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text('Bạn có chắc muốn hủy kết bạn với $_targetUserName không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy kết bạn'),
          ),
        ],
      ),
    );

    if (confirmed != true || _targetUserId == null) return;

    setState(() => _isLoadingRelationship = true);
    try {
      await FriendService.unfriend(_targetUserId!);
      if (!mounted) return;
      await context.read<FriendProvider>().loadFriends();
      if (!mounted) return;
      setState(() {
        _relationshipStatus = '';
        _friendshipId = null;
        _isLoadingRelationship = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRelationship = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _cancelRequest() async {
    if (_friendshipId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi lời mời'),
        content: Text('Thu hồi lời mời kết bạn đã gửi đến $_targetUserName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed != true || _friendshipId == null) return;

    setState(() => _isLoadingRelationship = true);
    try {
      await FriendService.cancelRequest(_friendshipId!);
      if (!mounted) return;
      setState(() {
        _relationshipStatus = '';
        _friendshipId = null;
        _isLoadingRelationship = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRelationship = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildProfileHeader(),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              const _PostsTab(),
              _InfoTab(isOwnProfile: _isOwnProfile),
              _ImagesTab(),
              const _SettingsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        color: Colors.white,
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 12),
            Text(
              _isOwnProfile ? _currentUserName : _targetUserName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (!_isOwnProfile && _targetUserEmail != null) ...[
              const SizedBox(height: 4),
              Text(
                _targetUserEmail!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_isOwnProfile)
              _buildOwnProfileActions()
            else
              _buildOtherProfileActions(),
            const SizedBox(height: 12),
            _buildStatRow(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarColor = _avatarColor(
      _isOwnProfile ? _currentUserName : _targetUserName,
    );
    final avatarUrl =
        _isOwnProfile ? _currentUserAvatar : _targetUserAvatar;
    final initials = _getInitials(
      _isOwnProfile ? _currentUserName : _targetUserName,
    );

    Widget avatarWidget = Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 63,
        backgroundColor: avatarColor,
        backgroundImage: _selectedAvatarBytes != null
            ? MemoryImage(_selectedAvatarBytes!)
            : null,
        child: avatarUrl.isNotEmpty && _selectedAvatarBytes == null
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: 126,
                  height: 126,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 42,
                    ),
                  ),
                ),
              )
            : _selectedAvatarBytes == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 42,
                    ),
                  )
                : null,
      ),
    );

    if (_isOwnProfile) {
      return GestureDetector(
        onTap: _pickAvatarAndPost,
        child: Stack(
          children: [
            avatarWidget,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return avatarWidget;
  }

  Widget _buildOwnProfileActions() {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit,
            label: 'Chỉnh sửa',
            filled: true,
            onTap: () {
              _tabController.animateTo(1);
            },
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildOtherProfileActions() {
    if (_isLoadingRelationship) {
      return const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final isPending = _relationshipStatus == 'pending';
    final isAccepted = _relationshipStatus == 'accepted';
    final isNotFriend = _relationshipStatus.isEmpty;

    return Row(
      children: [
        if (isNotFriend)
          Expanded(
            child: _buildActionButton(
              icon: Icons.person_add,
              label: 'Kết bạn',
              filled: true,
              onTap: _sendFriendRequest,
            ),
          )
        else if (isPending)
          Expanded(
            child: _buildActionButton(
              icon: Icons.person_remove,
              label: 'Thu hồi',
              filled: true,
              onTap: _cancelRequest,
            ),
          )
        else if (isAccepted)
          Expanded(
            child: _buildActionButton(
              icon: Icons.person,
              label: 'Hủy kết bạn',
              filled: true,
              onTap: _unfriend,
            ),
          ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: '',
          filled: false,
          onTap: () {},
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    if (filled) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E6EB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E6EB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final photoCount = provider.photoCount;
        final friendCount = provider.friendCount;

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.photo_library_outlined,
                value: '$photoCount',
                label: 'Ảnh',
                onTap: photoCount > 0 ? () => _tabController.animateTo(2) : null,
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: AppColors.backgroundGray,
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.people_outline,
                value: '$friendCount',
                label: 'Bạn bè',
                onTap: friendCount > 0
                    ? () {
                        if (_isOwnProfile) {
                          _tabController.animateTo(1);
                        } else {
                          _showFriendCountSheet(context, friendCount);
                        }
                      }
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFriendCountSheet(BuildContext context, int count) {
    final friends = context.read<ProfileProvider>().friends;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Bạn bè ($count)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: friends.isEmpty
                        ? Center(
                            child: Text(
                              'Chưa có bạn bè',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: friends.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              final initials = _getInitials(friend.fullName);
                              final avatarColor = _avatarColor(friend.fullName);
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                tileColor: const Color(0xFFF7F8FA),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: avatarColor,
                                  backgroundImage: friend.avatar.isNotEmpty
                                      ? NetworkImage(friend.avatar)
                                      : null,
                                  child: friend.avatar.isEmpty
                                      ? Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  friend.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  friend.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
// _TabBarDelegate removed — tab bar now inline in build()

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _TabBarDelegate({required this.tabController});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 1,
            color: AppColors.backgroundGray,
          ),
          TabBar(
            controller: tabController,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryBlue,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Bài viết'),
              Tab(text: 'Thông tin'),
              Tab(text: 'Ảnh'),
              Tab(text: 'Cài đặt'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 92;

  @override
  double get minExtent => 92;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => true;
}

// ============================================================
// TAB 0: BÀI VIẾT
// ============================================================
class _PostsTab extends StatefulWidget {
  const _PostsTab();

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  int _displayedPostCount = 6;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.posts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );
        }

        if (provider.errorMessage != null && provider.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Không thể tải bài viết',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
                TextButton(
                  onPressed: () => provider.loadProfile(
                    FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final allPosts = provider.posts;
        if (allPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bài viết nào',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final displayedPosts = allPosts.take(_displayedPostCount).toList();
        final hasMore = _displayedPostCount < allPosts.length;

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadProfile(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            );
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProfilePostCard(post: allPosts[index]),
                    childCount: displayedPosts.length,
                  ),
                ),
              ),
              if (hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _displayedPostCount += 6;
                          });
                        },
                        child: const Text('Xem thêm bài viết'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// TAB 1: THÔNG TIN (Editable)
// ============================================================
class _InfoTab extends StatelessWidget {
  final bool isOwnProfile;

  const _InfoTab({required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final profile = provider.userProfile;
        final email = FirebaseAuth.instance.currentUser?.email ?? '';
        final fullName = profile?.fullName ?? provider.userName ?? '';
        final bio = profile?.bio ?? '';
        final birthday = provider.birthday ?? '';

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _InfoEditableTile(
                    icon: Icons.person_outline,
                    label: 'Tên',
                    value: fullName.isEmpty ? 'Chưa cập nhật' : fullName,
                    isOwnProfile: isOwnProfile,
                    onTap: isOwnProfile
                        ? () => _showNameDialog(context, provider, fullName)
                        : null,
                  ),
                  _InfoEditableTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: email.isEmpty ? 'Chưa cập nhật' : email,
                    isOwnProfile: false,
                    onTap: null,
                  ),
                  _InfoEditableTile(
                    icon: Icons.cake_outlined,
                    label: 'Ngày sinh',
                    value: birthday.isEmpty ? 'Chưa cập nhật' : birthday,
                    isOwnProfile: isOwnProfile,
                    onTap: isOwnProfile
                        ? () => _showDateDialog(context, provider, birthday)
                        : null,
                  ),
                  _InfoEditableTile(
                    icon: Icons.info_outline,
                    label: 'Giới thiệu',
                    value: bio.isEmpty ? 'Chưa cập nhật' : bio,
                    isOwnProfile: isOwnProfile,
                    onTap: isOwnProfile
                        ? () => _showBioDialog(context, provider, bio)
                        : null,
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNameDialog(
    BuildContext context,
    ProfileProvider provider,
    String currentName,
  ) async {
    final parts = currentName.trim().split(' ');
    final firstNameController = TextEditingController(
      text: parts.isNotEmpty ? parts.first : '',
    );
    final lastNameController = TextEditingController(
      text: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa tên'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Họ không được trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Tên không được trống' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    try {
      await AuthService.updateUserInfo(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: provider.birthday,
        bio: provider.userProfile?.bio,
      );

      if (!context.mounted) return;
      final updated = provider.userProfile;
      if (updated != null) {
        provider.updateUserProfile(UserProfileModel(
          id: updated.id,
          fullName: '$firstName $lastName',
          email: updated.email,
          avatar: updated.avatar,
          dateOfBirth: updated.dateOfBirth,
          bio: updated.bio,
        ));
      } else {
        await provider.loadProfile(
          FirebaseAuth.instance.currentUser?.uid ?? '',
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật tên thành công!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showDateDialog(
    BuildContext context,
    ProfileProvider provider,
    String currentBirthday,
  ) async {
    DateTime? selected;
    if (currentBirthday.isNotEmpty) {
      try {
        final parts = currentBirthday.split('-');
        selected = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } catch (_) {}
    }

    selected ??= DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );

    if (picked == null) return;

    final dateStr =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    try {
      await AuthService.updateUserInfo(
        firstName: provider.userProfile?.firstName ?? '',
        lastName: provider.userProfile?.lastName ?? '',
        dateOfBirth: dateStr,
        bio: provider.userProfile?.bio,
      );

      if (!context.mounted) return;
      await provider.loadProfile(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật ngày sinh thành công!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showBioDialog(
    BuildContext context,
    ProfileProvider provider,
    String currentBio,
  ) async {
    final bioController = TextEditingController(text: currentBio);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa giới thiệu'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: bioController,
            decoration: const InputDecoration(
              labelText: 'Giới thiệu',
              border: OutlineInputBorder(),
              hintText: 'Viết gì đó về bản thân...',
            ),
            maxLines: 3,
            maxLength: 200,
            validator: (v) =>
                v != null && v.length > 200 ? 'Tối đa 200 ký tự' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await AuthService.updateUserInfo(
        firstName: provider.userProfile?.firstName ?? '',
        lastName: provider.userProfile?.lastName ?? '',
        dateOfBirth: provider.birthday,
        bio: bioController.text.trim(),
      );

      if (!context.mounted) return;
      await provider.loadProfile(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật giới thiệu thành công!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _InfoEditableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isOwnProfile;
  final VoidCallback? onTap;

  const _InfoEditableTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isOwnProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = isOwnProfile && onTap != null;

    return InkWell(
      onTap: canEdit ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.backgroundGray),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: canEdit ? AppColors.primaryBlue : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? 'Chưa cập nhật' : value,
                    style: TextStyle(
                      fontSize: 15,
                      color: value.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (canEdit)
              Icon(
                Icons.edit,
                color: AppColors.primaryBlue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB 2: ẢNH
// ============================================================
class _ImagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final posts = provider.posts;
        final imagePosts = posts
            .where((p) => p.mediaUrls.isNotEmpty)
            .toList();

        if (imagePosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Chưa có ảnh nào',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(4),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = imagePosts[index];
                    final firstImage = post.mediaUrls.first;
                    return GestureDetector(
                      onTap: () => _showImagePostSheet(context, post),
                      child: Image.network(
                        firstImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                        ),
                      ),
                    );
                  },
                  childCount: imagePosts.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImagePostSheet(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImagePostSheet(post: post),
    );
  }
}

class _ImagePostSheet extends StatelessWidget {
  final PostModel post;

  const _ImagePostSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Bài viết có ảnh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildPostHeader(post),
                    if (post.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          post.content,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: post.mediaUrls.length == 1
                            ? 1
                            : post.mediaUrls.length == 2
                                ? 2
                                : 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: post.mediaUrls.length,
                      itemBuilder: (context, idx) {
                        return Image.network(
                          post.mediaUrls[idx],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: Icon(Icons.broken_image,
                                color: Colors.grey.shade400),
                          ),
                        );
                      },
                    ),
                    _buildPostActions(context, post),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostHeader(PostModel post) {
    final color = _avatarColor(post.userName);
    final initials = _initials(post.userName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            backgroundImage: post.userAvatar.isNotEmpty
                ? NetworkImage(post.userAvatar)
                : null,
            child: post.userAvatar.isEmpty
                ? Text(initials, style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (post.isOwner) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatTime(post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostActions(BuildContext context, PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                context.read<FeedProvider>().toggleLike(post.id);
              },
              icon: Icon(
                post.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 18,
                color: post.isLiked
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
              ),
              label: Text(
                'Thích',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => CommentSheet(post: post),
                );
              },
              icon: Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              label: Text(
                'Bình luận',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

// ============================================================
// TAB 3: CÀI ĐẶT (rút gọn inline, ko dùng dialog)
// ============================================================
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  int _selectedSettingsIndex = 0;
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Container(
            color: Colors.grey.shade50,
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildSettingsMenuItem(
                  index: 0,
                  icon: Icons.settings_outlined,
                  label: 'Cài đặt chung',
                ),
                _buildSettingsMenuItem(
                  index: 1,
                  icon: Icons.palette_outlined,
                  label: 'Giao diện',
                ),
                _buildSettingsMenuItem(
                  index: 2,
                  icon: Icons.language,
                  label: 'Ngôn ngữ',
                ),
                const Spacer(),
                _buildSettingsMenuItem(
                  index: 3,
                  icon: Icons.logout,
                  label: 'Đăng xuất',
                  isLogout: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildSettingsContent(),
        ),
      ],
    );
  }

  Widget _buildSettingsMenuItem({
    required int index,
    required IconData icon,
    required String label,
    bool isLogout = false,
  }) {
    final isSelected = _selectedSettingsIndex == index;
    return InkWell(
      onTap: () {
        if (isLogout) {
          _handleLogout();
        } else {
          setState(() => _selectedSettingsIndex = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isLogout
                  ? Colors.red
                  : (isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isLogout
                      ? Colors.red
                      : (isSelected
                          ? AppColors.primaryBlue
                          : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final friendProvider = context.read<FriendProvider>();
    await friendProvider.disposeRealtime();
    friendProvider.clear();
    if (!mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Widget _buildSettingsContent() {
    switch (_selectedSettingsIndex) {
      case 0:
        return _buildGeneralSettings();
      case 1:
        return _buildAppearanceSettings();
      case 2:
        return _buildLanguageSettings();
      case 3:
        return const SizedBox();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGeneralSettings() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Cài đặt chung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Quản lý các cài đặt cơ bản cho tài khoản của bạn.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giao diện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildThemeOption('Chế độ sáng', false),
          const SizedBox(height: 12),
          _buildThemeOption('Chế độ tối', true),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, bool isDarkOption) {
    final isSelected = _isDark == isDarkOption;
    return InkWell(
      onTap: () {
        setState(() => _isDark = isDarkOption);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.backgroundGray,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.backgroundGray,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettings() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ngôn ngữ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chọn ngôn ngữ hiển thị',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.backgroundGray),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<String>(
              value: 'Tiếng Việt',
              underline: const SizedBox(),
              isDense: true,
              isExpanded: true,
              dropdownColor: Colors.white,
              items: ['Tiếng Việt', 'English'].map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// POST CARD
// ============================================================
class _ProfilePostCard extends StatefulWidget {
  final PostModel post;

  const _ProfilePostCard({required this.post});

  @override
  State<_ProfilePostCard> createState() => _ProfilePostCardState();
}

class _ProfilePostCardState extends State<_ProfilePostCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          if (widget.post.content.isNotEmpty) _buildPostContent(),
          if (widget.post.mediaUrls.isNotEmpty) _buildPostMedia(),
          _buildPostStats(),
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    final name = widget.post.userName;
    final color = _avatarColor(name);
    final initials = _initials(name);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            backgroundImage: widget.post.userAvatar.isNotEmpty
                ? NetworkImage(widget.post.userAvatar)
                : null,
            child: widget.post.userAvatar.isEmpty
                ? Text(initials, style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.post.isOwner) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatTime(widget.post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Text(
        widget.post.content,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPostMedia() {
    final mediaCount = widget.post.mediaUrls.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: mediaCount == 1
            ? _buildSingleImage(widget.post.mediaUrls.first)
            : _buildMultiImage(mediaCount),
      ),
    );
  }

  Widget _buildSingleImage(String url) {
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 200,
          color: const Color(0xFFF0F0F0),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryBlue,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: const Color(0xFFF0F0F0),
        child: Center(
          child: Icon(Icons.broken_image, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildMultiImage(int count) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: count == 2 ? 2 : 3,
      crossAxisSpacing: 2,
      mainAxisSpacing: 2,
      childAspectRatio: 1,
      children: List.generate(
        count > 4 ? 4 : count,
        (index) {
          final isLastWithMore = count > 4 && index == 3;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.post.mediaUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                ),
              ),
              if (isLastWithMore)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Text(
                      '+${count - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostStats() {
    if (widget.post.likeCount == 0 && widget.post.commentCount == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          if (widget.post.likeCount > 0) ...[
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.thumb_up, color: Colors.white, size: 10),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.post.likeCount}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const Spacer(),
          if (widget.post.commentCount > 0)
            Text(
              '${widget.post.commentCount} bình luận',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                context.read<FeedProvider>().toggleLike(widget.post.id);
              },
              icon: Icon(
                widget.post.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 18,
                color: widget.post.isLiked
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
              ),
              label: Text(
                'Thích',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => CommentSheet(post: widget.post),
                );
              },
              icon: Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              label: Text(
                'Bình luận',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.share_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              label: Text(
                'Chia sẻ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

// ============================================================
// BOTTOM SHEET CHỌN HÀNH ĐỘNG AVATAR
// ============================================================
class _AvatarChoiceSheet extends StatelessWidget {
  final Uint8List imageBytes;

  const _AvatarChoiceSheet({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageBytes,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bạn muốn làm gì với ảnh này?',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          _buildChoiceTile(
            context,
            icon: Icons.camera_alt,
            iconColor: AppColors.primaryBlue,
            title: 'Đổi ảnh đại diện',
            subtitle: 'Cập nhật avatar trên hồ sơ của bạn',
            value: 'avatar_only',
          ),
          _buildChoiceTile(
            context,
            icon: Icons.article_outlined,
            iconColor: Colors.green,
            title: 'Đăng bài viết mới',
            subtitle: 'Chia sẻ ảnh này lên trang cá nhân',
            value: 'post_only',
          ),
          _buildChoiceTile(
            context,
            icon: Icons.check_circle_outline,
            iconColor: Colors.orange,
            title: 'Cả hai',
            subtitle: 'Đổi avatar và đăng bài viết',
            value: 'both',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}
