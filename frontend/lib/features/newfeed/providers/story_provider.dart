import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../services/cloudinary_service.dart';

enum StoryLoadingState { idle, loading, success, error }

class StoryProvider extends ChangeNotifier {
  List<UserStory> _userStories = [];
  StoryLoadingState _state = StoryLoadingState.idle;
  String? _errorMessage;
  bool _isCreating = false;

  List<UserStory> get userStories => List.unmodifiable(_userStories);
  StoryLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isCreating => _isCreating;

  Future<void> loadStories() async {
    _state = StoryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _userStories = await StoryService.getStories();
      _state = StoryLoadingState.success;
    } catch (e) {
      _state = StoryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<StoryModel?> createStory(XFile imageFile) async {
    _isCreating = true;
    notifyListeners();

    try {
      final story = await StoryService.createStory(imageFile: imageFile);

      final ownerIndex = _userStories.indexWhere((u) => u.isOwner);
      if (ownerIndex != -1) {
        final owner = _userStories[ownerIndex];
        _userStories[ownerIndex] = UserStory(
          oderId: owner.oderId,
          userName: owner.userName,
          userAvatar: owner.userAvatar,
          stories: [story, ...owner.stories],
          isOwner: true,
        );
      } else {
        _userStories.insert(
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
    final userIndex = _userStories.indexWhere((u) => u.oderId == oderId);
    if (userIndex == -1) return;

    final user = _userStories[userIndex];
    final updatedStories = user.stories.map((s) {
      if (s.id == storyId) {
        return s.copyWith(isSeen: true);
      }
      return s;
    }).toList();

    _userStories[userIndex] = UserStory(
      oderId: user.oderId,
      userName: user.userName,
      userAvatar: user.userAvatar,
      stories: updatedStories,
      isOwner: user.isOwner,
    );
    notifyListeners();
  }

  void removeUserStory(String oderId) {
    _userStories.removeWhere((u) => u.oderId == oderId);
    notifyListeners();
  }

  void clear() {
    _userStories = [];
    _state = StoryLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
