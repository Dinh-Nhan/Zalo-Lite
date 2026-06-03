import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/widgets/search_overlay_screen.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/story_list.dart';
import '../widgets/comment_sheet.dart';
import 'create_post_screen.dart';

class NewfeedScreen extends StatefulWidget {
  const NewfeedScreen({super.key});

  @override
  State<NewfeedScreen> createState() => _NewfeedScreenState();
}

class _NewfeedScreenState extends State<NewfeedScreen> {
  String _currentUserId = '';
  String _currentUserName = '';
  String _currentUserAvatar = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadData();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUserName = user.displayName ?? 'User';
      _currentUserAvatar = user.photoURL ?? '';
    }
  }

  void _loadData() {
    Future.microtask(() {
      context.read<FeedProvider>().loadFeed();
      context.read<StoryProvider>().loadStories();
    });
  }

  void _openSearch() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SearchOverlayScreen(
          onBack: () => Navigator.of(context).pop(),
          onSearchResultTap: ({required userId, required name, avatar}) {
            Navigator.of(context).pop();
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _showCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostScreen(
        currentUserName: _currentUserName,
        currentUserAvatar: _currentUserAvatar,
      ),
    );
  }

  Color get _avatarColor {
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
    if (_currentUserName.isEmpty) return colors[0];
    return colors[_currentUserName.codeUnitAt(0) % colors.length];
  }

  String get _userInitials {
    if (_currentUserName.isEmpty) return '?';
    final parts = _currentUserName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return _currentUserName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () async {
                  await context.read<FeedProvider>().refreshFeed();
                  await context.read<StoryProvider>().loadStories();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildPostInput()),
                    SliverToBoxAdapter(child: _buildDivider()),
                    SliverToBoxAdapter(child: _buildStorySection()),
                    SliverToBoxAdapter(child: _buildStoryDivider()),
                    _buildPostList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0068FF),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _openSearch,
              child: Text(
                'Tìm kiếm',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _showCreatePost,
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_outlined,
                color: Colors.white,
                size: 26,
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      height: 48,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Nhật Ký',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1E21),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1E21),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Zalo Video',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xFFE4E6EB),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _avatarColor,
                ),
                child: Center(
                  child: _currentUserAvatar.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _currentUserAvatar,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              _userInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          _userInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _showCreatePost,
                  child: Text(
                    'Hôm nay bạn thế nào?',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildInputTypeButton(
                Icons.image,
                const Color(0xFF4CAF50),
                'Ảnh',
                _showCreatePost,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputTypeButton(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdateWidget() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Colors.grey.shade300,
          strokeWidth: 1.2,
          gap: 5,
        ),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.sentiment_satisfied_alt_outlined,
                color: Color(0xFF65676B),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Cập nhật trạng thái 24 giờ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 16,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.local_fire_department,
                color: Color(0xFF65676B),
                size: 18,
              ),
              const SizedBox(width: 4),
              const Text(
                '0',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1E21),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF65676B),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFE4E6EB),
    );
  }

  Widget _buildStoryDivider() {
    return Container(
      height: 8,
      color: const Color(0xFFEFF1F4),
    );
  }

  Widget _buildStorySection() {
    return StoryList(
      currentUserId: _currentUserId,
      currentUserName: _currentUserName,
      currentUserAvatar: _currentUserAvatar,
    );
  }

  Widget _buildPostList() {
    return Consumer<FeedProvider>(
      builder: (context, provider, _) {
        if (provider.state == FeedLoadingState.loading && provider.posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đang tải...',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.state == FeedLoadingState.error && provider.posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Không thể tải bài viết',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.loadFeed(),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài viết nào',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy là người đầu tiên đăng bài!',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == provider.posts.length) {
                if (provider.hasMore) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: TextButton(
                        onPressed: () => provider.loadMore(),
                        child: const Text('Xem thêm bài viết'),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              return _PostCard(post: provider.posts[index]);
            },
            childCount: provider.posts.length + (provider.hasMore ? 1 : 0),
          ),
        );
      },
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}

class _PostCard extends StatefulWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
              child: widget.post.userAvatar.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.post.userAvatar,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
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
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      _formatTime(widget.post.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF65676B),
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(color: Color(0xFF65676B)),
                    ),
                    Icon(
                      widget.post.visibility == 'public'
                          ? Icons.public
                          : widget.post.visibility == 'friends'
                              ? Icons.group
                              : Icons.lock,
                      size: 12,
                      color: const Color(0xFF65676B),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz,
              color: Color(0xFF65676B),
              size: 20,
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
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1C1E21),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count == 2 ? 2 : 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: count > 4 ? 4 : count,
      itemBuilder: (context, index) {
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
              child: const Icon(
                Icons.thumb_up,
                color: Colors.white,
                size: 10,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.post.likeCount}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF65676B),
              ),
            ),
          ],
          const Spacer(),
          if (widget.post.commentCount > 0)
            Text(
              '${widget.post.commentCount} bình luận',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF65676B),
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
                widget.post.isLiked
                    ? Icons.thumb_up
                    : Icons.thumb_up_outlined,
                size: 18,
                color: widget.post.isLiked
                    ? AppColors.primaryBlue
                    : const Color(0xFF65676B),
              ),
              label: Text(
                'Thích',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.post.isLiked
                      ? AppColors.primaryBlue
                      : const Color(0xFF65676B),
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
                  builder: (context) => CommentSheet(post: widget.post),
                );
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: Color(0xFF65676B),
              ),
              label: const Text(
                'Bình luận',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF65676B),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.share_outlined,
                size: 18,
                color: Color(0xFF65676B),
              ),
              label: const Text(
                'Chia sẻ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF65676B),
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

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
