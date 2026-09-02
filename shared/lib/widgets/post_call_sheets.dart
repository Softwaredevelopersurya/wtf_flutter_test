import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_strings.dart';
import '../utils/app_typography.dart';

/// Member Post-Call Rating Bottom Sheet (1-5 stars + optional note)
class MemberPostCallSheet extends StatefulWidget {
  final Future<void> Function(int rating, String note) onSubmit;

  const MemberPostCallSheet({
    super.key,
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
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
              AppSpacing.gapH8,
              Text('Rate Your Session', style: AppTypography.h2),
            ],
          ),
          AppSpacing.gapV8,
          Text(
            AppStrings.sessionEnded,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapV16,

          // 1-5 Star Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              return IconButton(
                iconSize: 36,
                icon: Icon(
                  starNumber <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _rating = starNumber),
              );
            }),
          ),
          Center(
            child: Text(
              '$_rating / 5 Stars',
              style: AppTypography.bodyMediumSemiBold.copyWith(color: Colors.amber.shade800),
            ),
          ),

          AppSpacing.gapV16,

          // Optional Feedback Note
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share session highlights or feedback for your trainer (optional)...',
            ),
          ),

          AppSpacing.gapV24,

          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    await widget.onSubmit(_rating, _noteController.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }
}

/// Trainer Post-Call Notes & Completion Bottom Sheet
class TrainerPostCallSheet extends StatefulWidget {
  final Future<void> Function(String trainerNotes) onComplete;

  const TrainerPostCallSheet({
    super.key,
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
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 28),
              AppSpacing.gapH8,
              Text('Session Notes & Completion', style: AppTypography.h2),
            ],
          ),
          AppSpacing.gapV8,
          Text(
            'Record notes on member posture, reps, and next steps.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapV16,

          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'e.g. Good progress on deadlifts. Keep core engaged. Focus on hydration and recovery.',
            ),
          ),

          AppSpacing.gapV24,

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.trainerPrimary),
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    await widget.onComplete(_notesController.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Mark as Complete'),
          ),
        ],
      ),
    );
  }
}
