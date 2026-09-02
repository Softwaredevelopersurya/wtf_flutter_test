import '../models/call_request.dart';

class SchedulerValidationResult {
  final bool isValid;
  final String? errorMessage;

  const SchedulerValidationResult.valid() : isValid = true, errorMessage = null;
  const SchedulerValidationResult.invalid(this.errorMessage) : isValid = false;
}

class Validators {
  /// Validates note length (max 140 chars)
  static bool isValidNote(String note) {
    return note.trim().isNotEmpty && note.length <= 140;
  }

  /// Validates that the requested scheduled time is not in the past
  static SchedulerValidationResult validateScheduledTime(DateTime scheduledTime, [DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    if (scheduledTime.isBefore(now)) {
      return const SchedulerValidationResult.invalid('Cannot pick past time.');
    }
    return const SchedulerValidationResult.valid();
  }

  /// Checks if the requested slot conflicts with any existing approved call requests (30-minute block window)
  static SchedulerValidationResult checkSlotConflict({
    required DateTime targetTime,
    required List<CallRequest> existingRequests,
    Duration slotDuration = const Duration(minutes: 30),
    String? excludeRequestId,
  }) {
    final targetEnd = targetTime.add(slotDuration);

    for (final request in existingRequests) {
      if (request.id == excludeRequestId) continue;
      if (request.status != CallRequestStatus.approved) continue;

      final reqStart = request.scheduledFor;
      final reqEnd = reqStart.add(slotDuration);

      // Overlap condition: start < otherEnd && end > otherStart
      final hasOverlap = targetTime.isBefore(reqEnd) && targetEnd.isAfter(reqStart);
      if (hasOverlap) {
        return const SchedulerValidationResult.invalid('Slot already approved for another session.');
      }
    }

    return const SchedulerValidationResult.valid();
  }
}
