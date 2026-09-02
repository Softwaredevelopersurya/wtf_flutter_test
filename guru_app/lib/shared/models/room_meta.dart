import 'dart:convert';

class RoomMeta {
  final String id;
  final String callRequestId;
  final String hmsRoomId;
  final String hmsRoleMember;
  final String hmsRoleTrainer;

  const RoomMeta({
    required this.id,
    required this.callRequestId,
    required this.hmsRoomId,
    this.hmsRoleMember = 'member',
    this.hmsRoleTrainer = 'trainer',
  });

  RoomMeta copyWith({
    String? id,
    String? callRequestId,
    String? hmsRoomId,
    String? hmsRoleMember,
    String? hmsRoleTrainer,
  }) {
    return RoomMeta(
      id: id ?? this.id,
      callRequestId: callRequestId ?? this.callRequestId,
      hmsRoomId: hmsRoomId ?? this.hmsRoomId,
      hmsRoleMember: hmsRoleMember ?? this.hmsRoleMember,
      hmsRoleTrainer: hmsRoleTrainer ?? this.hmsRoleTrainer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callRequestId': callRequestId,
      'hmsRoomId': hmsRoomId,
      'hmsRoleMember': hmsRoleMember,
      'hmsRoleTrainer': hmsRoleTrainer,
    };
  }

  factory RoomMeta.fromMap(Map<String, dynamic> map) {
    return RoomMeta(
      id: map['id'] as String,
      callRequestId: map['callRequestId'] as String,
      hmsRoomId: map['hmsRoomId'] as String,
      hmsRoleMember: map['hmsRoleMember'] as String? ?? 'member',
      hmsRoleTrainer: map['hmsRoleTrainer'] as String? ?? 'trainer',
    );
  }

  String toJson() => json.encode(toMap());

  factory RoomMeta.fromJson(String source) => RoomMeta.fromMap(json.decode(source) as Map<String, dynamic>);
}
