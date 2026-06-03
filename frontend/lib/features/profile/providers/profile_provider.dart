import 'package:flutter/foundation.dart';
import 'package:frontend/features/newfeed/models/post_model.dart';
import 'package:frontend/features/profile/services/profile_service.dart';
import 'package:frontend/features/friends/services/friend_service.dart';

class ProfileProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  List<FriendSummaryModel> _friends = [];
  bool _isLoading = false;
  String? _errorMessage;
  UserProfileModel? _userProfile;

  String? userName;
  String? birthday;
  String? gender;

  List<PostModel> get posts => List.unmodifiable(_posts);
  List<FriendSummaryModel> get friends => List.unmodifiable(_friends);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfileModel? get userProfile => _userProfile;

  int get photoCount => _posts.where((p) => p.mediaUrls.isNotEmpty).length;
  int get friendCount => _friends.length;
  int get postCount => _posts.length;

  void setExternalPosts(List<PostModel> posts) {
    _posts = posts;
    notifyListeners();
  }

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ProfileService.getUserPosts(userId),
        ProfileService.getFriends(),
        ProfileService.getCurrentUserProfile(),
      ]);

      _posts = results[0] as List<PostModel>;
      _friends = results[1] as List<FriendSummaryModel>;
      _userProfile = results[2] as UserProfileModel;

      userName = _userProfile?.fullName;
      if (_userProfile?.dateOfBirth != null) {
        final dob = _userProfile!.dateOfBirth!;
        birthday = '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
      }
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<void> refreshProfile(String userId) async {
    try {
      final results = await Future.wait([
        ProfileService.getUserPosts(userId),
        ProfileService.getFriends(),
      ]);

      _posts = results[0] as List<PostModel>;
      _friends = results[1] as List<FriendSummaryModel>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void updateUserProfile(UserProfileModel updated) {
    _userProfile = updated;
    userName = updated.fullName;
    if (updated.dateOfBirth != null) {
      final dob = updated.dateOfBirth!;
      birthday = '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
    }
    notifyListeners();
  }

  void clear() {
    _posts = [];
    _friends = [];
    _isLoading = false;
    _errorMessage = null;
    _userProfile = null;
    userName = null;
    birthday = null;
    gender = null;
    notifyListeners();
  }
}
