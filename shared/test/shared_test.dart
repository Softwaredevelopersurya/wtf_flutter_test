import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('Data Models & Serialization Tests', () {
    test('User serialization and deserialization preserves properties', () {
      const user = User(
        id: 'user_123',
        role: UserRole.trainer,
        name: 'Aarav Test',
        email: 'aarav@test.com',
        avatarUrl: 'https://avatar.com/1',
      );

      final jsonMap = user.toMap();
      expect(jsonMap['id'], 'user_123');
      expect(jsonMap['role'], 'trainer');
      expect(jsonMap['name'], 'Aarav Test');

      final deserialized = User.fromMap(jsonMap);
      expect(deserialized.id, user.id);
      expect(deserialized.role, UserRole.trainer);
      expect(deserialized.isTrainer, isTrue);
      expect(deserialized.isMember, isFalse);
    });

    test('Message serialization preserves status and timestamps', () {
      final now = DateTime.now();
      final msg = Message(
        id: 'msg_001',
        chatId: 'chat_1',
        senderId: 'sender_1',
        receiverId: 'receiver_1',
        text: 'Hi Coach 👍',
        createdAt: now,
        status: MessageStatus.read,
      );

      final jsonStr = msg.toJson();
      final deserialized = Message.fromJson(jsonStr);

      expect(deserialized.id, 'msg_001');
      expect(deserialized.text, 'Hi Coach 👍');
      expect(deserialized.status, MessageStatus.read);
    });

    test('CallRequest correctly manages pending/approved statuses', () {
      final req = CallRequest(
        id: 'req_1',
        memberId: 'mem_1',
        trainerId: 'tr_1',
        requestedAt: DateTime.now(),
        scheduledFor: DateTime.now().add(const Duration(hours: 2)),
        note: 'Macros review',
        status: CallRequestStatus.pending,
      );

      expect(req.isPending, isTrue);
      expect(req.isApproved, isFalse);

      final approved = req.copyWith(status: CallRequestStatus.approved, roomId: 'channel_agora_abc');
      expect(approved.isApproved, isTrue);
      expect(approved.roomId, 'channel_agora_abc');
    });

    test('Agora RoomMeta and AgoraInCallMessage serialization tests', () {
      const room = RoomMeta(
        id: 'meta_1',
        callRequestId: 'req_1',
        channelName: 'channel_agora_123',
        agoraRoleMember: 'broadcaster',
        agoraRoleTrainer: 'publisher',
      );

      final map = room.toMap();
      expect(map['channelName'], 'channel_agora_123');
      expect(map['agoraRoleMember'], 'broadcaster');

      final deserialized = RoomMeta.fromMap(map);
      expect(deserialized.channelName, 'channel_agora_123');
      expect(deserialized.hmsRoomId, 'channel_agora_123');

      final msg = AgoraInCallMessage(
        id: 'msg_1',
        senderId: 'u1',
        senderName: 'DK',
        message: 'Let us begin form checks',
        timestamp: DateTime.now(),
      );

      final msgMap = msg.toMap();
      expect(msgMap['senderName'], 'DK');
      expect(msgMap['message'], 'Let us begin form checks');
      final deserializedMsg = AgoraInCallMessage.fromMap(msgMap);
      expect(deserializedMsg.message, msg.message);
    });
  });


  group('Scheduler Validation Tests (Minimum Quality Gate)', () {
    test('Validation rejects past scheduled times', () {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      final result = Validators.validateScheduledTime(pastTime);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, 'Cannot pick past time.');
    });

    test('Validation accepts valid future scheduled times', () {
      final futureTime = DateTime.now().add(const Duration(hours: 2));
      final result = Validators.validateScheduledTime(futureTime);

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Validation detects conflicts with existing approved requests', () {
      final baseTime = DateTime(2026, 9, 3, 18, 0); // 6:00 PM tomorrow
      final existingRequests = [
        CallRequest(
          id: 'existing_approved_1',
          memberId: 'mem_1',
          trainerId: 'tr_1',
          requestedAt: DateTime.now(),
          scheduledFor: baseTime,
          note: 'Existing Session',
          status: CallRequestStatus.approved,
        ),
      ];

      // Exact same time conflict
      final conflict1 = Validators.checkSlotConflict(
        targetTime: baseTime,
        existingRequests: existingRequests,
      );
      expect(conflict1.isValid, isFalse);
      expect(conflict1.errorMessage, contains('Slot already approved'));

      // Non-conflicting time (1 hour later)
      final noConflict = Validators.checkSlotConflict(
        targetTime: baseTime.add(const Duration(hours: 1)),
        existingRequests: existingRequests,
      );
      expect(noConflict.isValid, isTrue);
    });
  });

  group('SessionLog Duration Calculation Tests', () {
    test('Calculates seconds, minutes, and hours accurately', () {
      final dummyDate = DateTime(2026, 9, 2, 13, 0);
      final logSeconds = SessionLog(
        id: '1',
        memberId: 'm',
        trainerId: 't',
        startedAt: dummyDate,
        endedAt: dummyDate.add(const Duration(seconds: 45)),
        durationSec: 45,
      );
      expect(logSeconds.formattedDuration, '45s');

      final logMinutes = SessionLog(
        id: '2',
        memberId: 'm',
        trainerId: 't',
        startedAt: dummyDate,
        endedAt: dummyDate.add(const Duration(seconds: 765)),
        durationSec: 765, // 12m 45s
      );
      expect(logMinutes.formattedDuration, '12m 45s');

      final logHours = SessionLog(
        id: '3',
        memberId: 'm',
        trainerId: 't',
        startedAt: dummyDate,
        endedAt: dummyDate.add(const Duration(seconds: 4500)),
        durationSec: 4500, // 1h 15m
      );
      expect(logHours.formattedDuration, '1h 15m');
    });

    test('Formatters duration helper works identically', () {
      expect(Formatters.formatDuration(30), '30s');
      expect(Formatters.formatDuration(600), '10m');
      expect(Formatters.formatDuration(635), '10m 35s');
    });
  });
}


