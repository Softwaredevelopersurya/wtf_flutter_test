import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class GuruViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final ChatService _chat = ChatService();
  final CallService _call = CallService();
  final SyncBridge _sync = SyncBridge();

  User? _currentUser;
  User? _assignedTrainer;
  bool _isLoading = true;
  bool _isOnboarded = false;

  StreamSubscription? _messagesSub;
  StreamSubscription? _callsSub;
  StreamSubscription? _sessionsSub;
  StreamSubscription? _typingSub;

  User? get currentUser => _currentUser;
  User? get assignedTrainer => _assignedTrainer;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _isOnboarded;

  List<Message> get messages => _currentUser != null && _assignedTrainer != null
      ? _chat.getMessagesForChat('${_currentUser!.id}_${_assignedTrainer!.id}')
      : [];

  List<CallRequest> get myRequests => _currentUser != null
      ? _call.allRequests.where((r) => r.memberId == _currentUser!.id).toList()
      : [];

  List<SessionLog> get mySessions => _currentUser != null
      ? _call.allSessionLogs.where((s) => s.memberId == _currentUser!.id).toList()
      : [];

  bool get isTrainerTyping {
    if (_assignedTrainer == null) return false;
    return _sync.typingStatus[_assignedTrainer!.id] ?? false;
  }

  int get unreadChatCount {
    if (_currentUser == null || _assignedTrainer == null) return 0;
    return _chat.getUnreadCount(
      chatId: '${_currentUser!.id}_${_assignedTrainer!.id}',
      currentUserId: _currentUser!.id,
    );
  }

  Message? get lastChatMessage {
    if (_currentUser == null || _assignedTrainer == null) return null;
    return _chat.getLastMessage('${_currentUser!.id}_${_assignedTrainer!.id}');
  }

  CallRequest? get nextUpcomingApprovedCall {
    final approved = myRequests.where((r) => r.status == CallRequestStatus.approved).toList();
    if (approved.isEmpty) return null;
    approved.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return approved.first;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _sync.initialize();
    _isOnboarded = await _auth.isMemberOnboarded();
    _currentUser = await _auth.loadSession(UserRole.member);

    if (_currentUser != null && _currentUser!.assignedTrainerId != null) {
      _assignedTrainer = _sync.users.firstWhere(
        (u) => u.id == _currentUser!.assignedTrainerId,
        orElse: () => const User(
          id: 'user_trainer_aarav',
          role: UserRole.trainer,
          name: 'Aarav (Lead Trainer)',
          email: 'aarav.trainer@wtf.fitness',
        ),
      );
    }

    _messagesSub = _sync.messagesStream.listen((_) => notifyListeners());
    _callsSub = _sync.callRequestsStream.listen((_) => notifyListeners());
    _sessionsSub = _sync.sessionLogsStream.listen((_) => notifyListeners());
    _typingSub = _sync.typingStream.listen((_) => notifyListeners());

    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    required String email,
    required String trainerId,
  }) async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _auth.completeMemberOnboarding(
      name: name,
      email: email,
      assignedTrainerId: trainerId,
    );

    _assignedTrainer = _sync.users.firstWhere((u) => u.id == trainerId);
    _isOnboarded = true;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? attachmentUrl}) async {
    if (_currentUser == null || _assignedTrainer == null || text.trim().isEmpty) return;

    await _chat.sendMessage(
      chatId: '${_currentUser!.id}_${_assignedTrainer!.id}',
      senderId: _currentUser!.id,
      receiverId: _assignedTrainer!.id,
      text: text.trim(),
      attachmentUrl: attachmentUrl,
    );
  }

  Future<void> markMessagesAsRead() async {
    if (_currentUser == null || _assignedTrainer == null) return;
    await _chat.markAsRead(
      chatId: '${_currentUser!.id}_${_assignedTrainer!.id}',
      currentUserId: _currentUser!.id,
    );
  }

  Future<CallRequest> requestCall({required DateTime scheduledFor, required String note}) async {
    if (_currentUser == null || _assignedTrainer == null) {
      throw Exception('User or Trainer not initialized');
    }

    return await _call.requestCall(
      memberId: _currentUser!.id,
      trainerId: _assignedTrainer!.id,
      scheduledFor: scheduledFor,
      note: note,
    );
  }

  Future<SessionLog> recordCompletedSession({
    required DateTime startedAt,
    required DateTime endedAt,
    int? rating,
    String? memberNotes,
  }) async {
    return await _call.completeSession(
      memberId: _currentUser!.id,
      trainerId: _assignedTrainer!.id,
      startedAt: startedAt,
      endedAt: endedAt,
      rating: rating,
      memberNotes: memberNotes,
    );
  }

  Future<void> rateSession(String logId, int rating, String memberNotes) async {
    await _call.updateSessionLogRatingAndNotes(
      logId: logId,
      rating: rating,
      memberNotes: memberNotes,
    );
    notifyListeners();
  }

  Future<void> resetForTesting() async {
    await _auth.resetSession(UserRole.member);
    _currentUser = null;
    _isOnboarded = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _callsSub?.cancel();
    _sessionsSub?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }
}


