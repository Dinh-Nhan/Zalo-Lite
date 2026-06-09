import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import 'story_avatar.dart';

class StoryList extends StatelessWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;

  const StoryList({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Consumer<StoryProvider>(
        builder: (context, provider, _) {
          final stories = provider.userStories;

          return SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stories.length + (provider.hasMore ? 2 : 1),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStory(context);
                }
                if (index <= stories.length) {
                  final userStory = stories[index - 1];
                  return StoryAvatar(
                    userStory: userStory,
                    onTap: () => _openStoryViewer(context, index - 1),
                  );
                }
                return _buildSeeMoreButton(context, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeeMoreButton(BuildContext context, StoryProvider provider) {
    return GestureDetector(
      onTap: () => provider.loadMore(),
      child: Container(
        width: 104,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade200,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward, color: Colors.grey, size: 28),
            SizedBox(height: 4),
            Text(
              'Xem thêm',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStory(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/create-story'),
      child: Container(
        width: 104,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF1E1E1E),
          image: currentUserAvatar.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(currentUserAvatar),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.25),
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // Center blue circle with camera icon
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            // Text "Tạo mới" at the bottom
            const Positioned(
              left: 6,
              right: 6,
              bottom: 8,
              child: Text(
                'Tạo mới',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStoryViewer(BuildContext context, int startIndex) {
    context.push('/story-viewer', extra: startIndex);
  }
}
