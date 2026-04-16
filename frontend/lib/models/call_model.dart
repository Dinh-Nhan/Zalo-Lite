enum CallStatus { dialing, ringing, active, ended }

class CallModel {
  final String id;
  final String remoteName;
  final String remoteAvatar;
  final bool isVideo;
  CallStatus status;

  CallModel({
    required this.id,
    required this.remoteName,
    required this.remoteAvatar,
    this.isVideo = false,
    this.status = CallStatus.dialing,
  });
}