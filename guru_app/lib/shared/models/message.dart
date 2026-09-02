import 'dart:convert';

enum MessageStatus {
  sending,
  sent,
  read;

  static MessageStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'read':
        return MessageStatus.read;
      case 'sent':
        return MessageStatus.sent;
      case 'sending':
      default:
        return MessageStatus.sending;
    }
  }

  String toValue() => name;
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;
  final String? attachmentUrl;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.attachmentUrl,
  });

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? createdAt,
    MessageStatus? status,
    String? attachmentUrl,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toValue(),
      'attachmentUrl': attachmentUrl,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chatId'] as String? ?? 'default_chat',
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      text: map['text'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      status: MessageStatus.fromString(map['status'] as String? ?? 'sent'),
      attachmentUrl: map['attachmentUrl'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) => Message.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          senderId == other.senderId &&
          receiverId == other.receiverId &&
          text == other.text &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ text.hashCode ^ status.hashCode;
}
