import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/dark_mode_config.dart';
import '../../../apps/app_locale.dart';
import '../../../utils/app_localizations.dart';
import '../providers/personal_page_provider.dart';
import '../widgets/story_bar.dart';
import '../widgets/create_post_card.dart';
import '../widgets/post_card.dart';
import '../data/models/models.dart';

class PersonalPageScreen extends StatefulWidget {
  final bool isWideScreen;

  const PersonalPageScreen({super.key, this.isWideScreen = false});

  @override
  State<PersonalPageScreen> createState() => _PersonalPageScreenState();
}

class _PersonalPageScreenState extends State<PersonalPageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PersonalPageProvider>();
      if (!provider.hasLoaded) {
        provider.loadNewsfeed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return ValueListenableBuilder<String>(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            final t = AppLocalizations(locale);
            return Scaffold(
              backgroundColor: AppColors.getBackground(isDark),
              body: SafeArea(
                child: Column(
                  children: [
                    if (!widget.isWideScreen) _buildSearchHeader(isDark, t),
                    _buildAppBar(isDark),
                    Expanded(
                      child: _buildContent(isDark, t),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchHeader(bool isDark, AppLocalizations t) {
    final Color mobileHeaderBg = isDark
        ? const Color(0xFF1A1A1A)
        : AppColors.primaryBlue;
    final searchBg = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.white.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: mobileHeaderBg,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm bài viết...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Zalo Lite',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const Spacer(),
          _buildAppBarIcon(Icons.search, isDark, () {}),
          const SizedBox(width: 8),
          _buildAppBarIcon(Icons.notifications_outlined, isDark, () {}),
          const SizedBox(width: 8),
          _buildAppBarIcon(Icons.menu, isDark, () {}),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundGray,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.getTextPrimary(isDark),
        ),
      ),
    );
  }

  Widget _buildStoryBar(bool isDark) {
    final provider = context.watch<PersonalPageProvider>();
    return StoryBar(
      stories: provider.stories,
      isLoading: provider.isLoading,
      currentUserAvatar: null,
      currentUserName: 'Tôi',
      onCreateTap: () => _showCreateDialog(isDark, defaultType: 'story'),
      onStoryTap: (story) => _showStoryViewer(story, isDark),
    );
  }

  Widget _buildContent(bool isDark, AppLocalizations t) {
    final provider = context.watch<PersonalPageProvider>();

    if (provider.isLoading && provider.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.getTextSecondary(isDark),
            ),
            const SizedBox(height: 12),
            Text(
              provider.error!,
              style: TextStyle(color: AppColors.getTextSecondary(isDark)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.loadNewsfeed(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadNewsfeed(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildStoryBar(isDark),
          CreatePostCard(
            userName: 'Tôi',
            userAvatar: null,
            isDark: isDark,
            onTap: () => _showCreateDialog(isDark),
          ),
          if (provider.posts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Chưa có bài viết nào.\nHãy là người đầu tiên chia sẻ!',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDark),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...provider.posts.map((post) => PostCard(
                  feed: post,
                  authorName: 'Người dùng',
                  authorAvatar: null,
                  isDark: isDark,
                  onLike: () => provider.toggleLike(post),
                  onDelete: post.userId == provider.currentUserId
                      ? () => _confirmDelete(post, isDark)
                      : null,
                )),
        ],
      ),
    );
  }

  void _showCreateDialog(bool isDark, {String defaultType = 'post'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheet(isDark: isDark, initialType: defaultType),
    );
  }

  void _showStoryViewer(FeedModel story, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xem story: ${story.id}')),
    );
  }

  void _confirmDelete(FeedModel post, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(isDark),
        title: Text(
          'Xóa bài viết',
          style: TextStyle(color: AppColors.getTextPrimary(isDark)),
        ),
        content: Text(
          'Bạn có chắc muốn xóa bài viết này không?',
          style: TextStyle(color: AppColors.getTextSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PersonalPageProvider>().deleteFeed(post.id);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final bool isDark;
  final String initialType;

  const _CreatePostSheet({required this.isDark, this.initialType = 'post'});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController _captionController = TextEditingController();
  String _selectedPrivacy = 'public';
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalPageProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(widget.isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.getDivider(widget.isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Tạo bài viết',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(widget.isDark),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.getTextPrimary(widget.isDark)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.getDivider(widget.isDark)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTypeChip('post', 'Bài viết'),
                const SizedBox(width: 8),
                _buildTypeChip('story', 'Story'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _captionController,
              maxLines: 4,
              style: TextStyle(color: AppColors.getTextPrimary(widget.isDark)),
              decoration: InputDecoration(
                hintText: _selectedType == 'story'
                    ? 'Viết gì đó cho story...'
                    : 'Hôm nay bạn thế nào?',
                hintStyle: TextStyle(color: AppColors.getTextSecondary(widget.isDark)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.public, size: 16, color: AppColors.getTextSecondary(widget.isDark)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedPrivacy,
                  dropdownColor: AppColors.getSurface(widget.isDark),
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: AppColors.getTextPrimary(widget.isDark),
                    fontSize: 14,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Công khai')),
                    DropdownMenuItem(value: 'friends', child: Text('Bạn bè')),
                    DropdownMenuItem(value: 'private', child: Text('Riêng tư')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPrivacy = value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chọn ảnh từ thư viện...')),
                );
              },
              icon: const Icon(Icons.image),
              label: const Text('Thêm ảnh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isCreating ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: provider.isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selectedType == 'story' ? 'Đăng Story' : 'Đăng bài',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.getDivider(widget.isDark),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : AppColors.getTextPrimary(widget.isDark),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung')),
      );
      return;
    }

    final provider = context.read<PersonalPageProvider>();
    bool success;

    if (_selectedType == 'story') {
      success = await provider.createStory(
        caption: caption,
        media: [],
        privacy: _selectedPrivacy,
      );
    } else {
      success = await provider.createPost(
        caption: caption,
        media: [],
        privacy: _selectedPrivacy,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedType == 'story'
                ? 'Story đã được đăng!'
                : 'Bài viết đã được đăng!',
          ),
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }
}
