import 'dart:convert';

class SessionLog {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final int? rating; // 1-5
  final String? trainerNotes;
  final String? memberNotes;

  const SessionLog({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.rating,
    this.trainerNotes,
    this.memberNotes,
  });

  /// Formatted duration e.g. "12m 45s" or "45s" or "1h 15m"
  String get formattedDuration {
    if (durationSec < 60) {
      return '${durationSec}s';
    }
    final minutes = durationSec ~/ 60;
    final remainingSeconds = durationSec % 60;
    if (minutes < 60) {
      return remainingSeconds > 0 ? '${minutes}m ${remainingSeconds}s' : '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return remMinutes > 0 ? '${hours}h ${remMinutes}m' : '${hours}h';
  }

  SessionLog copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSec,
    int? rating,
    String? trainerNotes,
    String? memberNotes,
  }) {
    return SessionLog(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      trainerId: trainerId ?? this.trainerId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSec: durationSec ?? this.durationSec,
      rating: rating ?? this.rating,
      trainerNotes: trainerNotes ?? this.trainerNotes,
      memberNotes: memberNotes ?? this.memberNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'trainerId': trainerId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSec': durationSec,
      'rating': rating,
      'trainerNotes': trainerNotes,
      'memberNotes': memberNotes,
    };
  }

  factory SessionLog.fromMap(Map<String, dynamic> map) {
    return SessionLog(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      trainerId: map['trainerId'] as String,
      startedAt: DateTime.tryParse(map['startedAt'] as String? ?? '') ?? DateTime.now(),
      endedAt: DateTime.tryParse(map['endedAt'] as String? ?? '') ?? DateTime.now(),
      durationSec: map['durationSec'] as int? ?? 0,
      rating: map['rating'] as int?,
      trainerNotes: map['trainerNotes'] as String?,
      memberNotes: map['memberNotes'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory SessionLog.fromJson(String source) => SessionLog.fromMap(json.decode(source) as Map<String, dynamic>);
}
