import 'package:flutter/material.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:frontend/data/repository/user_repository.dart';

class UserController extends ChangeNotifier {
  final UserRepository repository = UserRepository();

  List<UserModel> users = [];
  bool isLoading = false;

  /// LOAD
  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();

    try {
      users = await repository.fetchUsers();
    } catch (e) {
      debugPrint("loadUsers error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// CREATE
  Future<void> createUser(UserModel user) async {
    try {
      await repository.addUser(user);
      await loadUsers();
    } catch (e) {
      debugPrint("createUser error: $e");
    }
  }

  /// UPDATE PUT
  Future<void> updateUserPut(UserModel user) async {
    try {
      await repository.editUserPut(user);
      await loadUsers();
    } catch (e) {
      debugPrint("update PUT error: $e");
    }
  }

  /// UPDATE PATCH
  Future<void> updateUserPatch({
    required UserModel user,
    required bool updateFirstName,
    required bool updateLastName,
    required bool updatePhone,
    required bool updateAvatar,
    required bool updateBio,
  }) async {
    final patchBody = user.toPatchJson(
      updateFirstName: updateFirstName,
      updateLastName: updateLastName,
      updatePhone: updatePhone,
      updateAvatar: updateAvatar,
      updateBio: updateBio,
    );

    if (patchBody.isEmpty) return;

    try {
      await repository.editUserPatch(
        id: user.id!,
        body: patchBody,
      );
      await loadUsers();
    } catch (e) {
      debugPrint("update PATCH error: $e");
    }
  }

  /// DELETE (optimistic)
  Future<void> deleteUser(String id) async {
    users.removeWhere((u) => u.id == id);
    notifyListeners();

    try {
      await repository.removeUser(id);
    } catch (e) {
      debugPrint("delete error: $e");
    }
  }
}