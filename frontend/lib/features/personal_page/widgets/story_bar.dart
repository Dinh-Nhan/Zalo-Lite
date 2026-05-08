import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/app_colors.dart';
import '../data/models/models.dart';
import 'story_avatar_item.dart';

/// Thanh story bar nằm ngang phía trên - chứa "Tạo mới" + danh sách stories
class StoryBar extends StatelessWidget {
  final List<FeedModel> stories;
  final bool isLoading;
  final VoidCallback onCreateTap;
  final Function(FeedModel) onStoryTap;
  final String? currentUserAvatar;
  final String currentUserName;

  const StoryBar({
    super.key,
    required this.stories,
    required this.isLoading,
    required this.onCreateTap,
    required this.onStoryTap,
    this.currentUserAvatar,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          bottom: BorderSide(
            color: AppColors.getDivider(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Stories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  'Khoảnh khắc',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: stories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: StoryAvatarItem(
                            userId: currentUserId,
                            userName: currentUserName,
                            avatarUrl: currentUserAvatar,
                            isOwn: true,
                            isViewed: false,
                            onTap: onCreateTap,
                          ),
                        );
                      }

                      final story = stories[index - 1];
                      final isViewed = story.settings?.isExpired ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: StoryAvatarItem(
                          userId: story.userId,
                          userName: '',
                          avatarUrl: story.userId,
                          isOwn: false,
                          isViewed: isViewed,
                          onTap: () => onStoryTap(story),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
