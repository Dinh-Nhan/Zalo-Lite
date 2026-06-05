enum CallStatus { dialing, ringing, active, ended, rejected, missed }

class CallModel {
  final String conversationId;
  final String callerId;
  final String calleeId;
  final String remoteName;
  final String remoteAvatar;
  final bool isVideo;
  final bool isIncoming; // true = mình đang nhận
  CallStatus status;

  CallModel({
    required this.conversationId,
    required this.callerId,
    required this.calleeId,
    required this.remoteName,
    required this.remoteAvatar,
    required this.isIncoming,
    this.isVideo = false,
    this.status = CallStatus.dialing,
  });

  String get remoteUserId => isIncoming ? callerId : calleeId;
}
