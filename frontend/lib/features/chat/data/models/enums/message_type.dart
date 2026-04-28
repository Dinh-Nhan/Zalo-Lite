enum MessageType {text, image, callLog, callMissed}

MessageType parseMessageType(String? raw) {
  switch (raw) {
    case 'image': return MessageType.image;
    case 'callLog': return MessageType.callLog;
    case 'callMissed': return MessageType.callMissed;
    default: return MessageType.text;
  }
}

String messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.image: return 'image';
    case MessageType.callLog: return 'callLog';
    case MessageType.callMissed: return 'callMissed';
    default: return 'text';
  }
}