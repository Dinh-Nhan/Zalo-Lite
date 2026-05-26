import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agora_token_generator/agora_token_generator.dart';

class AgoraConfig {
  static String get appId => dotenv.env['AGORA_APP_ID'] ?? '';
  static String get appCertificate => dotenv.env['AGORA_APP_CERTIFICATE'] ?? '';

  static String generateChannelName(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static String generateToken(String channelName) {
    return RtcTokenBuilder.buildTokenWithUid(
      appId: appId,
      appCertificate: appCertificate,
      channelName: channelName,
      uid: 0,
      tokenExpireSeconds: 3600, // 1 tiếng
    );
  }
}
