import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'log_service.dart';
import 'sync_bridge.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final SyncBridge _sync = SyncBridge();
  final LogService _logger = LogService();
  final Uuid _uuid = const Uuid();

  Stream<List<Message>> get messagesStream => _sync.messagesStream;
  Stream<Map<String, bool>> get typingStream => _sync.typingStream;

  List<Message> getMessagesForChat(String chatId, {String? user1Id, String? user2Id}) {
    return _sync.messages.where((m) {
      if (m.chatId == chatId) return true;
      if (user1Id != null && user2Id != null) {
        return (m.senderId == user1Id && m.receiverId == user2Id) ||
            (m.senderId == user2Id && m.receiverId == user1Id);
      }
      final parts = chatId.split('_user_');
      if (parts.length == 2) {
        final u1 = parts[0];
        final u2 = 'user_${parts[1]}';
        return (m.senderId == u1 && m.receiverId == u2) ||
            (m.senderId == u2 && m.receiverId == u1) ||
            m.chatId == '${u2}_$u1';
      }
      return false;
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Sends a message and simulates the typing indicator on the receiver's side
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    String? attachmentUrl,
  }) async {
    final messageId = 'msg_${_uuid.v4().substring(0, 8)}';
    final message = Message(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
      attachmentUrl: attachmentUrl,
    );

    _logger.logChat('Sending message: "${message.text}" from $senderId to $receiverId');

    // 1. Save message to sync bridge
    await _sync.addMessage(message);

    // 2. Simulate typing indicator on receiver side (400-800ms) for realism if needed
    _simulateTypingForSender(senderId);

    return message;
  }

  void _simulateTypingForSender(String senderId) {
    _sync.setTypingStatus(senderId, true);
    Timer(const Duration(milliseconds: 650), () {
      _sync.setTypingStatus(senderId, false);
    });
  }

  /// Mark all unread messages for this user in this chat as read
  Future<void> markAsRead({required String chatId, required String currentUserId, String? otherUserId}) async {
    _logger.logChat('Marking messages as read in chat $chatId for user $currentUserId');
    await _sync.markMessagesAsRead(chatId: chatId, currentUserId: currentUserId, otherUserId: otherUserId);
  }

  /// Computes unread message count for current user in a chat
  int getUnreadCount({required String chatId, required String currentUserId, String? otherUserId}) {
    return _sync.messages.where((m) {
      final matchesChat = m.chatId == chatId ||
          (otherUserId != null &&
              ((m.senderId == currentUserId && m.receiverId == otherUserId) ||
                  (m.senderId == otherUserId && m.receiverId == currentUserId)));
      return matchesChat && m.receiverId == currentUserId && m.status != MessageStatus.read;
    }).length;
  }

  /// Gets the last message for a chat
  Message? getLastMessage(String chatId, {String? user1Id, String? user2Id}) {
    final chatMsgs = getMessagesForChat(chatId, user1Id: user1Id, user2Id: user2Id);
    return chatMsgs.isNotEmpty ? chatMsgs.last : null;
  }
}
