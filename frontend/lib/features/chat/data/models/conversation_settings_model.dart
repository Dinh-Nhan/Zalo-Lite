class ConversationSettingsModel {
  final bool isMuted;
  final String theme;

  ConversationSettingsModel({
    required this.isMuted,
    required this.theme,
  });

  factory ConversationSettingsModel.fromJson(Map<String, dynamic> json) {
    return ConversationSettingsModel(
      isMuted: json['isMuted'] ?? false,
      theme: json['theme'] ?? 'classic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isMuted': isMuted,
      'theme': theme,
    };
  }
}