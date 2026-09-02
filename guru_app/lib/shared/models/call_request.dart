import 'dart:convert';

enum CallRequestStatus {
  pending,
  approved,
  declined,
  cancelled;

  static CallRequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return CallRequestStatus.approved;
      case 'declined':
        return CallRequestStatus.declined;
      case 'cancelled':
        return CallRequestStatus.cancelled;
      case 'pending':
      default:
        return CallRequestStatus.pending;
    }
  }

  String toValue() => name;
}

class CallRequest {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final String note;
  final CallRequestStatus status;
  final String? declineReason;
  final String? roomId;

  const CallRequest({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.requestedAt,
    required this.scheduledFor,
    required this.note,
    this.status = CallRequestStatus.pending,
    this.declineReason,
    this.roomId,
  });

  bool get isPending => status == CallRequestStatus.pending;
  bool get isApproved => status == CallRequestStatus.approved;
  bool get isDeclined => status == CallRequestStatus.declined;
  bool get isCancelled => status == CallRequestStatus.cancelled;

  CallRequest copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? requestedAt,
    DateTime? scheduledFor,
    String? note,
    CallRequestStatus? status,
    String? declineReason,
    String? roomId,
  }) {
    return CallRequest(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      trainerId: trainerId ?? this.trainerId,
      requestedAt: requestedAt ?? this.requestedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      note: note ?? this.note,
      status: status ?? this.status,
      declineReason: declineReason ?? this.declineReason,
      roomId: roomId ?? this.roomId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'trainerId': trainerId,
      'requestedAt': requestedAt.toIso8601String(),
      'scheduledFor': scheduledFor.toIso8601String(),
      'note': note,
      'status': status.toValue(),
      'declineReason': declineReason,
      'roomId': roomId,
    };
  }

  factory CallRequest.fromMap(Map<String, dynamic> map) {
    return CallRequest(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      trainerId: map['trainerId'] as String,
      requestedAt: DateTime.tryParse(map['requestedAt'] as String? ?? '') ?? DateTime.now(),
      scheduledFor: DateTime.tryParse(map['scheduledFor'] as String? ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
      note: map['note'] as String? ?? '',
      status: CallRequestStatus.fromString(map['status'] as String? ?? 'pending'),
      declineReason: map['declineReason'] as String?,
      roomId: map['roomId'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory CallRequest.fromJson(String source) => CallRequest.fromMap(json.decode(source) as Map<String, dynamic>);
}
