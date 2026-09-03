import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class TrainerViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final ChatService _chat = ChatService();
  final CallService _call = CallService();
  final SyncBridge _sync = SyncBridge();

  User? _currentUser;
  User? _selectedMember;
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

  User? get activeMember {
    if (_selectedMember != null) {
      return members.firstWhere((m) => m.id == _selectedMember!.id, orElse: () => _selectedMember!);
    }
    // Pick member with most recent message or call request if available
    if (_currentUser != null && _sync.messages.isNotEmpty) {
      final lastMsg = _sync.messages.last;
      final recentMemberId = lastMsg.senderId == _currentUser!.id ? lastMsg.receiverId : lastMsg.senderId;
      final found = members.where((m) => m.id == recentMemberId);
      if (found.isNotEmpty) return found.first;
    }
    return primaryMember;
  }

  void setSelectedMember(User? member) {
    _selectedMember = member;
    notifyListeners();
  }

  List<Message> getMessagesForMember(User member) {
    if (_currentUser == null) return [];
    return _chat.getMessagesForChat(
      '${member.id}_${_currentUser!.id}',
      user1Id: member.id,
      user2Id: _currentUser!.id,
    );
  }

  List<Message> get messagesForPrimaryMember {
    final target = activeMember ?? primaryMember;
    if (_currentUser == null || target == null) return [];
    return getMessagesForMember(target);
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
    final target = activeMember ?? primaryMember;
    if (_currentUser == null || target == null) return 0;
    return getUnreadCountForMember(target);
  }

  int getUnreadCountForMember(User member) {
    if (_currentUser == null) return 0;
    return _chat.getUnreadCount(
      chatId: '${member.id}_${_currentUser!.id}',
      currentUserId: _currentUser!.id,
      otherUserId: member.id,
    );
  }

  Message? get lastChatMessage {
    final target = activeMember ?? primaryMember;
    if (_currentUser == null || target == null) return null;
    return getLastMessageForMember(target);
  }

  Message? getLastMessageForMember(User member) {
    if (_currentUser == null) return null;
    return _chat.getLastMessage(
      '${member.id}_${_currentUser!.id}',
      user1Id: member.id,
      user2Id: _currentUser!.id,
    );
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

  Future<void> sendMessage(String text, {String? attachmentUrl, User? targetMember}) async {
    final target = targetMember ?? activeMember ?? primaryMember;
    if (_currentUser == null || target == null || text.trim().isEmpty) return;

    await _chat.sendMessage(
      chatId: '${target.id}_${_currentUser!.id}',
      senderId: _currentUser!.id,
      receiverId: target.id,
      text: text.trim(),
      attachmentUrl: attachmentUrl,
    );
  }

  Future<void> markMessagesAsRead({User? targetMember}) async {
    final target = targetMember ?? activeMember ?? primaryMember;
    if (_currentUser == null || target == null) return;
    await _chat.markAsRead(
      chatId: '${target.id}_${_currentUser!.id}',
      currentUserId: _currentUser!.id,
      otherUserId: target.id,
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


