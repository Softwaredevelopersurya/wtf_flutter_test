import 'package:flutter_test/flutter_test.dart';
import 'package:trainer_app/providers/trainer_view_model.dart';
import 'package:trainer_app/shared/shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Trainer App View Model & Logic Tests', () {
    test('Initializes with default trainer state', () async {
      final vm = TrainerViewModel();
      expect(vm.isLoading, isTrue);
      expect(vm.pendingRequests, isEmpty);
    });

    test('Checks call approval workflow and status changes', () {
      final now = DateTime.now();
      final req = CallRequest(
        id: 'call_1',
        memberId: 'user_member_dk',
        trainerId: 'user_trainer_aarav',
        requestedAt: now,
        scheduledFor: now.add(const Duration(hours: 3)),
        note: 'Macros review',
        status: CallRequestStatus.pending,
      );

      expect(req.isPending, isTrue);
      final approved = req.copyWith(status: CallRequestStatus.approved, roomId: 'room_live_01');
      expect(approved.isApproved, isTrue);
      expect(approved.roomId, 'room_live_01');

      final declined = req.copyWith(status: CallRequestStatus.declined, declineReason: 'Time conflict');
      expect(declined.isDeclined, isTrue);
      expect(declined.declineReason, 'Time conflict');
    });

    test('Session log completion formatting', () {
      final log = SessionLog(
        id: 'log_01',
        memberId: 'user_member_dk',
        trainerId: 'user_trainer_aarav',
        startedAt: DateTime.now(),
        endedAt: DateTime.now().add(const Duration(minutes: 30)),
        durationSec: 1800,
        rating: 5,
        trainerNotes: 'Solid progress',
      );

      expect(log.formattedDuration, '30m');
      expect(log.rating, 5);
    });
  });
}

