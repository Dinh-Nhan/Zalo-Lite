import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class StoryAvatarItem extends StatelessWidget {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final bool isOwn;
  final bool isViewed;
  final VoidCallback onTap;

  const StoryAvatarItem({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.isOwn,
    this.isViewed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (isOwn) {
      return _buildOwnAvatar(isDark);
    }
    return _buildStoryAvatar(isDark);
  }

  Widget _buildOwnAvatar(bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkCard : AppColors.backgroundGray,
                border: Border.all(
                  color: AppColors.getDivider(isDark),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl!.isNotEmpty
                            ? Image.network(
                                avatarUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildInitialsAvatar(),
                              )
                            : _buildInitialsAvatar()
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tạo mới',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextSecondary(isDark),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(bool isDark) {
    final borderColors = isViewed
        ? [
            AppColors.getDivider(isDark),
            AppColors.getDivider(isDark),
          ]
        : [
            AppColors.primaryBlue,
            AppColors.lightBlue,
          ];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: borderColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  border: Border.all(
                    color: isDark ? AppColors.darkBackground : Colors.white,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? Image.network(
                          avatarUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildInitialsAvatar(large: true),
                        )
                      : _buildInitialsAvatar(large: true),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              userName.isEmpty ? userId.substring(0, 8) : userName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isViewed ? FontWeight.normal : FontWeight.w500,
                color: isViewed
                    ? AppColors.getTextSecondary(isDark)
                    : AppColors.getTextPrimary(isDark),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar({bool large = false}) {
    final size = large ? 52.0 : 58.0;
    final fontSize = large ? 18.0 : 20.0;
    final initials = _getInitials(userName);
    final colors = [
      AppColors.primaryBlue,
      AppColors.lightBlue,
      AppColors.darkBlue,
      const Color(0xFF8A2BE2),
      const Color(0xFFFF6B6B),
    ];
    final colorIndex = userId.hashCode % colors.length;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[colorIndex.abs()],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
