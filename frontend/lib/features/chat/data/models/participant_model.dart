import 'package:frontend/features/chat/data/models/enums/participant_role.dart';

class ParticipantModel {
  final String userId;
  final ParticipantRole role;

  ParticipantModel({required this.userId, required this.role});

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      userId: json['userId'] as String,
      role: ParticipantRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => ParticipantRole.member,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'role': role.name};
  }
}
