enum RoleType { admin, client }
RoleType roleFromString(String role) {
  switch (role) {
    case 'admin':
      return RoleType.admin;
    case 'client':
      return RoleType.client;
    default:
      return RoleType.client;
  }
}
class UserModel {
  final String? id;
  final RoleType role;
  final String firstName;
  final String lastName;
  final String phone;
  final String? avatar;
  final DateTime? dob;
  final String bio;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  UserModel({
    this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.avatar,
    this.dob,
    required this.bio,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });
  //Convert từ JSON -> Object
  factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['_id'] ?? '',

    role: roleFromString(json['role'] ?? 'client'),

    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    phone: json['phone'] ?? '',

    avatar: json['avatar'] ?? 'avatarDefault.jpg',

    dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,

    bio: json['bio'] ?? '',
    status: json['status'] == true ? 'active' : 'inactive',

    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,

    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'])
        : null,
  );
}
  // Convert từ Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'avatar': avatar,
      'dob': dob?.toIso8601String(),
      'bio': bio,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  //PATCH 1 phần thông tin người dùng
  Map<String, dynamic> toPatchJson({
    bool updateFirstName = false,
    bool updateLastName = false,
    bool updatePhone = false,
    bool updateAvatar = false,
    bool updateBio = false,
  }) {
    final Map<String, dynamic> data = {};

    if (updateFirstName) data['first_name'] = firstName;
    if (updateLastName) data['last_name'] = lastName;
    if (updatePhone) data['phone'] = phone;
    if (updateAvatar) data['avatar'] = avatar;
    if (updateBio) data['bio'] = bio;

    return data;
  }
}