import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../data/models/models.dart';

class PostCard extends StatelessWidget {
  final FeedModel feed;
  final String authorName;
  final String? authorAvatar;
  final VoidCallback onLike;
  final VoidCallback? onDelete;
  final bool isDark;

  const PostCard({
    super.key,
    required this.feed,
    required this.authorName,
    this.authorAvatar,
    required this.onLike,
    this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (feed.content.caption.isNotEmpty) _buildCaption(),
          if (feed.content.media.isNotEmpty) _buildMedia(),
          _buildSeparator(),
          _buildActionBar(),
          _buildBottomPadding(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 0),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    if (feed.privacy == 'friends') ...[
                      const SizedBox(width: 4),
                      Icon(Icons.group, size: 14, color: AppColors.getTextSecondary(isDark)),
                    ] else if (feed.privacy == 'private') ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock, size: 14, color: AppColors.getTextSecondary(isDark)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(feed.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                    if (feed.privacy != 'public' && feed.privacy != 'private' && feed.privacy != 'friends') ...[
                      Text(' \u00B7 ', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
                      Icon(Icons.public, size: 12, color: AppColors.getTextSecondary(isDark)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: AppColors.getTextSecondary(isDark),
                size: 22,
              ),
              onPressed: _showOptionsMenu,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (authorAvatar != null && authorAvatar!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: Image.network(
            authorAvatar!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          ),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    final parts = authorName.trim().split(' ');
    String initials = '?';
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    } else if (authorName.isNotEmpty) {
      initials = authorName[0].toUpperCase();
    }
    final colors = [
      AppColors.primaryBlue,
      AppColors.lightBlue,
      AppColors.darkBlue,
      const Color(0xFF8A2BE2),
      const Color(0xFFFF6B6B),
    ];
    final color = colors[authorName.hashCode % colors.length];

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(
        feed.content.caption,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.getTextPrimary(isDark),
          height: 1.38,
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (feed.content.media.isEmpty) return const SizedBox.shrink();
    final media = feed.content.media;
    if (media.length == 1) {
      return _buildSingleMedia(media[0]);
    } else if (media.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildSingleMedia(media[0])),
          const SizedBox(width: 2),
          Expanded(child: _buildSingleMedia(media[1])),
        ],
      );
    } else {
      return _buildMultiMediaGrid(media);
    }
  }

  Widget _buildSingleMedia(MediaModel item) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      width: double.infinity,
      child: item.type == 'video'
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: AppColors.darkBackground,
                child: const Center(
                  child: Icon(Icons.play_circle_fill, size: 56, color: Colors.white),
                ),
              ),
            )
          : Image.network(
              item.url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.backgroundGray,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
    );
  }

  Widget _buildMultiMediaGrid(List<MediaModel> items) {
    final displayItems = items.take(4).toList();
    final showCount = items.length > 4 ? items.length - 4 : 0;

    return SizedBox(
      height: 300,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 2) / 2;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: itemWidth / 150,
            children: [
              for (int i = 0; i < displayItems.length; i++)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      displayItems[i].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.backgroundGray,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 32),
                        ),
                      ),
                    ),
                    if (i == 3 && showCount > 0)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            '+$showCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.getDivider(isDark),
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(child: _buildActionItem(Icons.favorite_border, Icons.favorite, 'Thích', feed.stats.isLiked, Colors.red, onLike)),
          Container(width: 1, height: 24, color: AppColors.getDivider(isDark)),
          Expanded(child: _buildActionItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Bình luận', false, AppColors.primaryBlue, () {})),
          Container(width: 1, height: 24, color: AppColors.getDivider(isDark)),
          Expanded(child: _buildActionItem(Icons.share_outlined, Icons.share, 'Chia sẻ', false, AppColors.primaryBlue, () {})),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, IconData activeIcon, String label, bool isActive, Color activeColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? activeColor : AppColors.getTextSecondary(isDark),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? activeColor : AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPadding() {
    return Container(
      height: 8,
      color: AppColors.getDivider(isDark).withValues(alpha: 0.3),
    );
  }

  void _showOptionsMenu() {
    // Placeholder
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
