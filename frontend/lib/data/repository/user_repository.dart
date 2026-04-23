import '../models/user_model.dart';
import '../services/user_service.dart';

class UserRepository {
  final UserService _service = UserService();

  Future<List<UserModel>> fetchUsers() async {
    final data = await _service.getUsers();
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> addUser(UserModel user) async {
    await _service.createUser(user.toJson());
  }

  Future<void> editUserPut(UserModel user) async {
    await _service.updateUserPut(user.id!, user.toJson());
  }

  Future<void> editUserPatch({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    await _service.updateUserPatch(id, body);
  }

  Future<void> removeUser(String id) async {
    await _service.deleteUser(id);
  }
}