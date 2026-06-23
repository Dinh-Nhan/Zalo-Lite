import 'package:flutter/material.dart';
import '../models/story_model.dart';

class StoryAvatar extends StatelessWidget {
  final UserStory userStory;
  final VoidCallback onTap;

  const StoryAvatar({
    super.key,
    required this.userStory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the first story's image url or a high-quality fallback gradient
    final latestStory = userStory.stories.isNotEmpty ? userStory.stories.first : null;
    final bgUrl = latestStory?.imageUrl ?? 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=800';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: NetworkImage(bgUrl),
            fit: BoxFit.cover,
          ),
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
            // User Avatar in the middle
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: userStory.hasUnseenStories ? const Color(0xFF0068FF) : Colors.white,
                    width: 2.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: userStory.userAvatar.isNotEmpty
                          ? Image.network(
                              userStory.userAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitials(),
                            )
                          : _buildInitials(),
                    ),
                  ),
                ),
              ),
            ),
            // User Name at the bottom
            Positioned(
              left: 6,
              right: 6,
              bottom: 8,
              child: Text(
                userStory.userName,
                style: const TextStyle(
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

  Widget _buildInitials() {
    final initials = userStory.userName.isNotEmpty ? userStory.userName[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFF0068FF),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
