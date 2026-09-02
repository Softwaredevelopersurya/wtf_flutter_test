import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class TrainerViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final ChatService _chat = ChatService();
  final CallService _call = CallService();
  final SyncBridge _sync = SyncBridge();

  User? _currentUser;
  bool _isLoading = true;

  StreamSubscription? _messagesSub;
  StreamSubscription? _callsSub;
  StreamSubscription? _sessionsSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _usersSub;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  List<User> get members => _sync.users.where((u) => u.role == UserRole.member).toList();

  User? get primaryMember {
    final list = members;
    return list.isNotEmpty ? list.first : null;
  }

  List<Message> get messagesForPrimaryMember {
    if (_currentUser == null || primaryMember == null) return [];
    return _chat.getMessagesForChat('${primaryMember!.id}_${_currentUser!.id}');
  }

  List<CallRequest> get pendingRequests {
    if (_currentUser == null) return [];
    return _call.allRequests.where((r) => r.trainerId == _currentUser!.id && r.status == CallRequestStatus.pending).toList();
  }

  List<CallRequest> get allRequests {
    if (_currentUser == null) return [];
    return _call.allRequests.where((r) => r.trainerId == _currentUser!.id).toList();
  }

  List<SessionLog> get completedSessions {
    if (_currentUser == null) return [];
    return _call.allSessionLogs.where((s) => s.trainerId == _currentUser!.id).toList();
  }

  bool isMemberTyping(String memberId) {
    return _sync.typingStatus[memberId] ?? false;
  }

  int get unreadChatCount {
    if (_currentUser == null || primaryMember == null) return 0;
    return _chat.getUnreadCount(
      chatId: '${primaryMember!.id}_${_currentUser!.id}',
      currentUserId: _currentUser!.id,
    );
  }

  Message? get lastChatMessage {
    if (_currentUser == null || primaryMember == null) return null;
    return _chat.getLastMessage('${primaryMember!.id}_${_currentUser!.id}');
  }

  CallRequest? get nextUpcomingApprovedCall {
    final approved = allRequests.where((r) => r.status == CallRequestStatus.approved).toList();
    if (approved.isEmpty) return null;
    approved.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return approved.first;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _sync.initialize();
    _currentUser = await _auth.loadSession(UserRole.trainer);

    _messagesSub = _sync.messagesStream.listen((_) => notifyListeners());
    _callsSub = _sync.callRequestsStream.listen((_) => notifyListeners());
    _sessionsSub = _sync.sessionLogsStream.listen((_) => notifyListeners());
    _typingSub = _sync.typingStream.listen((_) => notifyListeners());
    _usersSub = _sync.usersStream.listen((_) => notifyListeners());

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(User user) async {
    _currentUser = user;
    await _auth.saveSession(user);
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? attachmentUrl}) async {
    if (_currentUser == null || primaryMember == null || text.trim().isEmpty) return;

    await _chat.sendMessage(
      chatId: '${primaryMember!.id}_${_currentUser!.id}',
      senderId: _currentUser!.id,
      receiverId: primaryMember!.id,
      text: text.trim(),
      attachmentUrl: attachmentUrl,
    );
  }

  Future<void> markMessagesAsRead() async {
    if (_currentUser == null || primaryMember == null) return;
    await _chat.markAsRead(
      chatId: '${primaryMember!.id}_${_currentUser!.id}',
      currentUserId: _currentUser!.id,
    );
  }

  Future<void> approveCallRequest(String requestId) async {
    await _call.approveCallRequest(requestId);
    notifyListeners();
  }

  Future<void> declineCallRequest(String requestId, String reason) async {
    await _call.declineCallRequest(requestId, reason);
    notifyListeners();
  }

  Future<SessionLog> recordCompletedSession({
    required String memberId,
    required DateTime startedAt,
    required DateTime endedAt,
    String? trainerNotes,
  }) async {
    return await _call.completeSession(
      memberId: memberId,
      trainerId: _currentUser!.id,
      startedAt: startedAt,
      endedAt: endedAt,
      trainerNotes: trainerNotes,
    );
  }

  Future<void> submitTrainerNotes(String logId, String trainerNotes) async {
    await _call.updateSessionLogRatingAndNotes(
      logId: logId,
      trainerNotes: trainerNotes,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _callsSub?.cancel();
    _sessionsSub?.cancel();
    _typingSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }
}


