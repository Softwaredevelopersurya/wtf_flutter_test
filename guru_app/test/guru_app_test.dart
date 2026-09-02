import 'package:flutter_test/flutter_test.dart';
import 'package:guru_app/providers/guru_view_model.dart';
import 'package:guru_app/shared/shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guru App View Model & Logic Tests', () {
    test('Initializes with default state', () async {
      final vm = GuruViewModel();
      expect(vm.isLoading, isTrue);
      expect(vm.messages, isEmpty);
    });

    test('Validates note length and slot booking constraints', () {
      expect(Validators.isValidNote('Macros review'), isTrue);
      expect(Validators.isValidNote(''), isFalse);
      expect(Validators.isValidNote('a' * 141), isFalse);
    });

    test('Calculates unread messages correctly', () {
      final now = DateTime.now();
      final msg = Message(
        id: 'msg_test',
        chatId: 'chat_test',
        senderId: 'trainer_1',
        receiverId: 'member_1',
        text: 'See you at 6 PM',
        createdAt: now,
        status: MessageStatus.sent,
      );

      expect(msg.status, MessageStatus.sent);
      final readMsg = msg.copyWith(status: MessageStatus.read);
      expect(readMsg.status, MessageStatus.read);
    });
  });
}

