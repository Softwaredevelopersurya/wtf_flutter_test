import 'dart:convert';

class RoomMeta {
  final String id;
  final String callRequestId;
  final String channelName;
  final String agoraRoleMember;
  final String agoraRoleTrainer;
  final String? agoraAppId;

  const RoomMeta({
    required this.id,
    required this.callRequestId,
    required this.channelName,
    this.agoraRoleMember = 'broadcaster',
    this.agoraRoleTrainer = 'broadcaster',
    this.agoraAppId,
  });

  // Backward compatibility getters
  String get hmsRoomId => channelName;
  String get hmsRoleMember => agoraRoleMember;
  String get hmsRoleTrainer => agoraRoleTrainer;

  RoomMeta copyWith({
    String? id,
    String? callRequestId,
    String? channelName,
    String? agoraRoleMember,
    String? agoraRoleTrainer,
    String? agoraAppId,
    // Backward compatibility parameter aliases
    String? hmsRoomId,
    String? hmsRoleMember,
    String? hmsRoleTrainer,
  }) {
    return RoomMeta(
      id: id ?? this.id,
      callRequestId: callRequestId ?? this.callRequestId,
      channelName: channelName ?? hmsRoomId ?? this.channelName,
      agoraRoleMember: agoraRoleMember ?? hmsRoleMember ?? this.agoraRoleMember,
      agoraRoleTrainer: agoraRoleTrainer ?? hmsRoleTrainer ?? this.agoraRoleTrainer,
      agoraAppId: agoraAppId ?? this.agoraAppId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callRequestId': callRequestId,
      'channelName': channelName,
      'agoraRoleMember': agoraRoleMember,
      'agoraRoleTrainer': agoraRoleTrainer,
      if (agoraAppId != null) 'agoraAppId': agoraAppId,
      // Compatibility keys
      'hmsRoomId': channelName,
      'hmsRoleMember': agoraRoleMember,
      'hmsRoleTrainer': agoraRoleTrainer,
    };
  }

  factory RoomMeta.fromMap(Map<String, dynamic> map) {
    final chName = (map['channelName'] ?? map['hmsRoomId'] ?? '') as String;
    final rMember = (map['agoraRoleMember'] ?? map['hmsRoleMember'] ?? 'broadcaster') as String;
    final rTrainer = (map['agoraRoleTrainer'] ?? map['hmsRoleTrainer'] ?? 'broadcaster') as String;

    return RoomMeta(
      id: map['id'] as String,
      callRequestId: map['callRequestId'] as String,
      channelName: chName,
      agoraRoleMember: rMember,
      agoraRoleTrainer: rTrainer,
      agoraAppId: map['agoraAppId'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoomMeta.fromJson(String source) =>
      RoomMeta.fromMap(json.decode(source) as Map<String, dynamic>);
}
