import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

enum StoryLoadingState { idle, loading, success, error }

class StoryProvider extends ChangeNotifier {
  List<UserStory> _allUserStories = [];
  int _displayedCount = 6;
  StoryLoadingState _state = StoryLoadingState.idle;
  String? _errorMessage;
  bool _isCreating = false;

  List<UserStory> get userStories =>
      List.unmodifiable(_allUserStories.take(_displayedCount).toList());
  List<UserStory> get allUserStories => List.unmodifiable(_allUserStories);
  StoryLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isCreating => _isCreating;
  bool get hasMore => _displayedCount < _allUserStories.length;

  Future<void> loadStories() async {
    _state = StoryLoadingState.loading;
    _errorMessage = null;
    _displayedCount = 6;
    notifyListeners();

    try {
      _allUserStories = await StoryService.getStories();
      _state = StoryLoadingState.success;
    } catch (e) {
      _state = StoryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  void loadMore() {
    if (_displayedCount < _allUserStories.length) {
      _displayedCount += 6;
      notifyListeners();
    }
  }

  Future<StoryModel?> createStory(XFile imageFile) async {
    _isCreating = true;
    notifyListeners();

    try {
      final story = await StoryService.createStory(imageFile: imageFile);

      final ownerIndex = _allUserStories.indexWhere((u) => u.isOwner);
      if (ownerIndex != -1) {
        final owner = _allUserStories[ownerIndex];
        _allUserStories[ownerIndex] = UserStory(
          oderId: owner.oderId,
          userName: owner.userName,
          userAvatar: owner.userAvatar,
          stories: [story, ...owner.stories],
          isOwner: true,
        );
      } else {
        _allUserStories.insert(
          0,
          UserStory(
            oderId: story.userId,
            userName: story.userName,
            userAvatar: story.userAvatar,
            stories: [story],
            isOwner: true,
          ),
        );
      }

      _isCreating = false;
      notifyListeners();
      return story;
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void markStorySeen(String oderId, String storyId) {
    final userIndex = _allUserStories.indexWhere((u) => u.oderId == oderId);
    if (userIndex == -1) return;

    final user = _allUserStories[userIndex];
    final updatedStories = user.stories.map((s) {
      if (s.id == storyId) {
        return s.copyWith(isSeen: true);
      }
      return s;
    }).toList();

    _allUserStories[userIndex] = UserStory(
      oderId: user.oderId,
      userName: user.userName,
      userAvatar: user.userAvatar,
      stories: updatedStories,
      isOwner: user.isOwner,
    );
    notifyListeners();
  }

  void removeUserStory(String oderId) {
    _allUserStories.removeWhere((u) => u.oderId == oderId);
    notifyListeners();
  }

  void clear() {
    _allUserStories = [];
    _displayedCount = 6;
    _state = StoryLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
