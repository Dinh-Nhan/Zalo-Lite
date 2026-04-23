import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = "http://localhost:5244/api/User";

  Future<List<dynamic>> getUsers() async {
    final res = await http.get(Uri.parse(baseUrl));
    print("Response body: ${res.body}");
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      print("Parsed data: $data");
      return data;
    }
    throw Exception("API getUsers failed");
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    if (res.statusCode != 201) {
      throw Exception("API createUser failed");
    }
  }

  Future<void> updateUserPut(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    if (res.statusCode != 200) {
      throw Exception("API updateUser PUT failed");
    }
  }

  Future<void> updateUserPatch(String id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    if (res.statusCode != 200) {
      throw Exception("API updateUser PATCH failed");
    }
  }

  Future<void> deleteUser(String id) async {
    final res = await http.delete(Uri.parse("$baseUrl/$id"));

    if (res.statusCode != 200) {
      throw Exception("API deleteUser failed");
    }
  }
}