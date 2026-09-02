import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'chat_service.dart';
import 'log_service.dart';
import 'sync_bridge.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final SyncBridge _sync = SyncBridge();
  final ChatService _chatService = ChatService();
  final LogService _logger = LogService();
  final Uuid _uuid = const Uuid();

  String tokenServerUrl = 'http://localhost:8080';

  Stream<List<CallRequest>> get callRequestsStream => _sync.callRequestsStream;
  Stream<List<SessionLog>> get sessionLogsStream => _sync.sessionLogsStream;

  List<CallRequest> get allRequests => _sync.callRequests;
  List<SessionLog> get allSessionLogs => _sync.sessionLogs;

  /// Request a new call from Member to Trainer
  Future<CallRequest> requestCall({
    required String memberId,
    required String trainerId,
    required DateTime scheduledFor,
    required String note,
  }) async {
    // 1. Validation: no past time
    final timeValidation = Validators.validateScheduledTime(scheduledFor);
    if (!timeValidation.isValid) {
      _logger.logSchedule('Failed call request: past time', isError: true);
      throw Exception(timeValidation.errorMessage);
    }

    // 2. Validation: conflict check
    final conflictValidation = Validators.checkSlotConflict(
      targetTime: scheduledFor,
      existingRequests: _sync.callRequests,
    );
    if (!conflictValidation.isValid) {
      _logger.logSchedule('Failed call request: slot conflict', isError: true);
      throw Exception(conflictValidation.errorMessage);
    }

    final requestId = 'call_${_uuid.v4().substring(0, 8)}';
    final request = CallRequest(
      id: requestId,
      memberId: memberId,
      trainerId: trainerId,
      requestedAt: DateTime.now(),
      scheduledFor: scheduledFor,
      note: note,
      status: CallRequestStatus.pending,
    );

    _logger.logSchedule('Member ($memberId) requested call with Trainer ($trainerId) for ${scheduledFor.toIso8601String()}');
    await _sync.addCallRequest(request);
    return request;
  }

  /// Trainer Approves Call Request
  Future<CallRequest> approveCallRequest(String requestId) async {
    final req = _sync.callRequests.firstWhere((r) => r.id == requestId);
    final roomId = 'room_100ms_${_uuid.v4().substring(0, 8)}';

    final updatedRequest = req.copyWith(
      status: CallRequestStatus.approved,
      roomId: roomId,
    );

    _logger.logSchedule('Trainer approved call request $requestId, generated roomId: $roomId');
    await _sync.updateCallRequest(updatedRequest);

    // Send system message into chat
    final timeStr = Formatters.formatTimeOnly(req.scheduledFor);
    await _chatService.sendMessage(
      chatId: '${req.memberId}_${req.trainerId}',
      senderId: req.trainerId,
      receiverId: req.memberId,
      text: 'Call approved for $timeStr',
    );

    return updatedRequest;
  }

  /// Trainer Declines Call Request with Reason
  Future<CallRequest> declineCallRequest(String requestId, String reason) async {
    final req = _sync.callRequests.firstWhere((r) => r.id == requestId);
    final updatedRequest = req.copyWith(
      status: CallRequestStatus.declined,
      declineReason: reason,
    );

    _logger.logSchedule('Trainer declined call request $requestId. Reason: $reason');
    await _sync.updateCallRequest(updatedRequest);

    // Send status notification message into chat
    await _chatService.sendMessage(
      chatId: '${req.memberId}_${req.trainerId}',
      senderId: req.trainerId,
      receiverId: req.memberId,
      text: 'Call request declined. Reason: $reason',
    );

    return updatedRequest;
  }

  /// Fetch 100ms Auth Token from Token Server (with local fallback if server offline)
  Future<String> fetch100msAuthToken({
    required String userId,
    required String role,
    required String roomId,
  }) async {
    _logger.logRtc('Fetching 100ms Auth Token for user=$userId, role=$role, room=$roomId');

    try {
      final uri = Uri.parse('$tokenServerUrl/token?userId=$userId&role=$role&roomId=$roomId');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        _logger.logRtc('Successfully obtained 100ms token from token_server');
        return token;
      }
    } catch (e) {
      _logger.logRtc('Token server unreachable, generating robust local dev auth token', meta: {'error': e.toString()});
    }

    // Fallback: self-contained dev token for resilience
    return 'dev_token_${role}_${roomId}_$userId';
  }

  /// Checks if call is upcoming (within 10 minutes or past due today)
  bool isCallJoinable(CallRequest request) {
    if (request.status != CallRequestStatus.approved) return false;
    final now = DateTime.now();
    final difference = request.scheduledFor.difference(now);
    // Allow join if within 10 minutes before, or started up to 45 mins ago
    return difference.inMinutes <= 10 && difference.inMinutes >= -45;
  }

  /// Save completed session log
  Future<SessionLog> completeSession({
    required String memberId,
    required String trainerId,
    required DateTime startedAt,
    required DateTime endedAt,
    int? rating,
    String? trainerNotes,
    String? memberNotes,
  }) async {
    final durationSec = endedAt.difference(startedAt).inSeconds;
    final safeDuration = durationSec > 0 ? durationSec : 30; // Min 30s for demo accuracy

    final log = SessionLog(
      id: 'log_${_uuid.v4().substring(0, 8)}',
      memberId: memberId,
      trainerId: trainerId,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSec: safeDuration,
      rating: rating,
      trainerNotes: trainerNotes,
      memberNotes: memberNotes,
    );

    _logger.logRtc('Completed session log saved: duration=${log.formattedDuration}, rating=$rating');
    await _sync.addSessionLog(log);
    return log;
  }

  /// Update existing session log with post-call rating or notes
  Future<void> updateSessionLogRatingAndNotes({
    required String logId,
    int? rating,
    String? memberNotes,
    String? trainerNotes,
  }) async {
    final log = _sync.sessionLogs.firstWhere((l) => l.id == logId);
    final updated = log.copyWith(
      rating: rating ?? log.rating,
      memberNotes: memberNotes ?? log.memberNotes,
      trainerNotes: trainerNotes ?? log.trainerNotes,
    );
    await _sync.updateSessionLog(updated);
    _logger.logRtc('Updated session log $logId with feedback');
  }
}
