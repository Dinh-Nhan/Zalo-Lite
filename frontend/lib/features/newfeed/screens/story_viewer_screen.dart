import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/app_colors.dart';
import '../models/story_model.dart';
import '../providers/story_provider.dart';

class StoryViewerScreen extends StatefulWidget {
  final int startIndex;

  const StoryViewerScreen({
    super.key,
    required this.startIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  bool _isPaused = false;

  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );
    _progressController.addStatusListener(_onAnimationStatus);
    _startProgress();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void _togglePause() {
    if (_isPaused) {
      _progressController.forward();
      setState(() => _isPaused = false);
    } else {
      _progressController.stop();
      setState(() => _isPaused = true);
    }
  }

  void _nextStory() {
    final provider = context.read<StoryProvider>();
    final stories = provider.userStories;
    if (_currentUserIndex >= stories.length) {
      context.pop();
      return;
    }

    final userStory = stories[_currentUserIndex];
    if (_currentStoryIndex < userStory.stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _startProgress();
    } else if (_currentUserIndex < stories.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    } else {
      context.pop();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startProgress();
    } else if (_currentUserIndex > 0) {
      final provider = context.read<StoryProvider>();
      final stories = provider.userStories;
      setState(() {
        _currentUserIndex--;
        _currentStoryIndex = stories[_currentUserIndex].stories.length - 1;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    }
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    final dx = details.globalPosition.dx;
    final width = MediaQuery.of(context).size.width;
    if (dx < width * 0.3) {
      _previousStory();
    } else if (dx > width * 0.7) {
      _nextStory();
    } else {
      _togglePause();
    }
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onAnimationStatus);
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<StoryProvider>(
        builder: (context, provider, _) {
          final stories = provider.userStories;
          if (stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_stories_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có tin nào',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Quay lại',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTapDown: (details) =>
                    _onTapDown(details, BoxConstraints.tight(Size.zero)),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: stories.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentUserIndex = index;
                      _currentStoryIndex = 0;
                    });
                    _startProgress();
                  },
                  itemBuilder: (context, userIndex) {
                    final userStory = stories[userIndex];
                    if (_currentStoryIndex >= userStory.stories.length) {
                      return const SizedBox();
                    }
                    final story = userStory.stories[_currentStoryIndex];

                    if (userIndex == _currentUserIndex) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        provider.markStorySeen(userStory.oderId, story.id);
                      });
                    }

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          story.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFF2C2C2C),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF2C2C2C),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.white38,
                                    size: 64,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Không thể tải hình ảnh',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildHeader(stories),
                        _buildProgressBars(stories),
                        if (_isPaused) _buildPausedOverlay(),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBars(List<UserStory> stories) {
    if (_currentUserIndex >= stories.length) return const SizedBox();
    final userStory = stories[_currentUserIndex];
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(userStory.stories.length, (storyIndex) {
          final isCompleted = storyIndex < _currentStoryIndex;
          final isCurrent = storyIndex == _currentStoryIndex;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: isCurrent
                  ? AnimatedBuilder(
                      animation: _progressController,
                      builder: (_, __) {
                        return LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 2.5,
                        );
                      },
                    )
                  : LinearProgressIndicator(
                      value: isCompleted ? 1.0 : 0.0,
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation(
                        isCompleted ? Colors.white : Colors.white30,
                      ),
                      minHeight: 2.5,
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(List<UserStory> stories) {
    if (_currentUserIndex >= stories.length) return const SizedBox();
    final userStory = stories[_currentUserIndex];
    if (_currentStoryIndex >= userStory.stories.length) return const SizedBox();
    final story = userStory.stories[_currentStoryIndex];
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 22,
      left: 12,
      right: 12,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _avatarColor(userStory.userName),
            backgroundImage: userStory.userAvatar.isNotEmpty
                ? NetworkImage(userStory.userAvatar)
                : null,
            child: userStory.userAvatar.isEmpty
                ? Text(
                    _initials(userStory.userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userStory.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatTime(story.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(
          Icons.pause,
          color: Colors.white70,
          size: 64,
        ),
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
    } else {
      return '${diff.inDays} ngày';
    }
  }
}
