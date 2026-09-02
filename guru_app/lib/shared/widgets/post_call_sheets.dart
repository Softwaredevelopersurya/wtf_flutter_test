import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

/// Member Post-Call Rating & Feedback Sheet
class MemberPostCallSheet extends StatefulWidget {
  final SessionLog session;
  final String trainerName;
  final Future<void> Function(int rating, String note) onSubmit;

  const MemberPostCallSheet({
    super.key,
    required this.session,
    this.trainerName = 'Aarav (Lead Trainer)',
    required this.onSubmit,
  });

  @override
  State<MemberPostCallSheet> createState() => _MemberPostCallSheetState();
}

class _MemberPostCallSheetState extends State<MemberPostCallSheet> {
  int _rating = 5;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            AppSpacing.gapV16,
            Text(
              'Rate Your Session',
              style: AppTypography.h2.copyWith(color: AppColors.darkText),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapV4,
            Text(
              'How was your coaching session with ${widget.trainerName}?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextMuted),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapV16,

            // Star Rating Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starVal = index + 1;
                return IconButton(
                  iconSize: 36,
                  icon: Icon(
                    starVal <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: starVal <= _rating ? AppColors.warning : AppColors.darkTextMuted,
                  ),
                  onPressed: () => setState(() => _rating = starVal),
                );
              }),
            ),
            AppSpacing.gapV16,

            // Feedback Note Input
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.darkText),
              decoration: const InputDecoration(
                hintText: 'Share optional feedback for your trainer...',
                labelText: 'Feedback / Notes',
              ),
            ),
            AppSpacing.gapV16,

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.guruPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      setState(() => _isSubmitting = true);
                      await widget.onSubmit(_rating, _noteController.text.trim());
                      if (!mounted) return;
                      nav.pop();
                    },
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trainer Post-Call Session Notes Sheet
class TrainerPostCallSheet extends StatefulWidget {
  final SessionLog session;
  final String clientName;
  final Future<void> Function(String trainerNotes) onComplete;

  const TrainerPostCallSheet({
    super.key,
    required this.session,
    this.clientName = 'DK',
    required this.onComplete,
  });

  @override
  State<TrainerPostCallSheet> createState() => _TrainerPostCallSheetState();
}

class _TrainerPostCallSheetState extends State<TrainerPostCallSheet> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            AppSpacing.gapV16,
            Text(
              'Session Summary & Notes',
              style: AppTypography.h2.copyWith(color: AppColors.darkText),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapV4,
            Text(
              'Client: ${widget.clientName} (${widget.session.formattedDuration})',
              style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextMuted),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapV16,

            TextField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.darkText),
              decoration: const InputDecoration(
                hintText: 'Record workout progress, diet adjustments, or follow-up action items...',
                labelText: 'Trainer Session Notes',
              ),
            ),
            AppSpacing.gapV16,

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.trainerPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      setState(() => _isSubmitting = true);
                      await widget.onComplete(_notesController.text.trim());
                      if (!mounted) return;
                      nav.pop();
                    },
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Mark Session Complete & Save'),
            ),
          ],
        ),
      ),
    );
  }
}
