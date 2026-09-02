import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guru_app/shared/shared.dart';
import '../providers/guru_view_model.dart';

class ScheduleCallScreen extends StatefulWidget {
  const ScheduleCallScreen({super.key});

  @override
  State<ScheduleCallScreen> createState() => _ScheduleCallScreenState();
}

class _ScheduleCallScreenState extends State<ScheduleCallScreen> {
  DateTime? _selectedSlot;
  final TextEditingController _noteController = TextEditingController(text: 'Macros review');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestCall() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available 30-min time slot.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a short note for your coach.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (note.length > 140) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note cannot exceed 140 characters.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final vm = context.read<GuruViewModel>();
    setState(() => _isSubmitting = true);

    try {
      await vm.requestCall(
        scheduledFor: _selectedSlot!,
        note: note,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.requestSent),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _selectedSlot = null;
          _noteController.text = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Copy error',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GuruViewModel>();
    final requests = vm.myRequests;
    final trainer = vm.assignedTrainer;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Schedule Video Call'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: AppSpacing.paddingMd,
            children: [
              // Trainer Profile Badge
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: trainer?.avatarUrl != null ? NetworkImage(trainer!.avatarUrl!) : null,
                    ),
                    AppSpacing.gapH12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trainer?.name ?? 'Coach Aarav', style: AppTypography.h3),
                          Text('1-on-1 Consultation • 30 mins', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    const CustomBadge(text: '100ms HD Call', backgroundColor: AppColors.guruPrimary),
                  ],
                ),
              ),

              AppSpacing.gapV16,

              // 3-Day & Slot Picker
              Card(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: TimeSlotPicker(
                    initialDate: DateTime.now(),
                    existingRequests: vm.myRequests,
                    primaryColor: AppColors.guruPrimary,
                    onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
                  ),
                ),
              ),

              AppSpacing.gapV16,

              // Note Field (Max 140 Chars)
              Card(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Session Topic / Note', style: AppTypography.bodyMediumSemiBold),
                          ValueListenableBuilder(
                            valueListenable: _noteController,
                            builder: (context, TextEditingValue value, _) {
                              final length = value.text.length;
                              return Text(
                                '$length / 140',
                                style: AppTypography.caption.copyWith(
                                  color: length > 140 ? AppColors.error : AppColors.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      AppSpacing.gapV8,
                      TextField(
                        controller: _noteController,
                        maxLength: 140,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Macros review, form check for deadlift',
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.gapV16,

              // Request Call CTA
              ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, size: 18),
                label: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Request Call'),
                onPressed: _isSubmitting ? null : _handleRequestCall,
              ),

              AppSpacing.gapV24,

              // Section: My Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Requests & Status', style: AppTypography.h3),
                  Text('${requests.length} total', style: AppTypography.caption),
                ],
              ),
              AppSpacing.gapV12,

              if (requests.isEmpty)
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Center(
                    child: Text(
                      'No call requests yet. Select a slot above.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...requests.reversed.map((req) => _buildRequestCard(req)),
            ],
          ),
          const FloatingDevPanelButton(),
        ],
      ),
    );
  }

  Widget _buildRequestCard(CallRequest req) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (req.status) {
      case CallRequestStatus.approved:
        statusColor = AppColors.success;
        statusLabel = 'Approved';
        statusIcon = Icons.check_circle_rounded;
        break;
      case CallRequestStatus.declined:
        statusColor = AppColors.error;
        statusLabel = 'Declined';
        statusIcon = Icons.cancel_rounded;
        break;
      case CallRequestStatus.cancelled:
        statusColor = AppColors.textMuted;
        statusLabel = 'Cancelled';
        statusIcon = Icons.remove_circle_outline_rounded;
        break;
      case CallRequestStatus.pending:
        statusColor = AppColors.warning;
        statusLabel = 'Pending approval by Aarav';
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.guruPrimary),
                    AppSpacing.gapH8,
                    Text(
                      Formatters.formatFriendlyDateTime(req.scheduledFor),
                      style: AppTypography.bodyMediumSemiBold,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      AppSpacing.gapH4,
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapV8,
            Text('Topic: "${req.note}"', style: AppTypography.bodyMedium),
            if (req.isDeclined && req.declineReason != null) ...[
              AppSpacing.gapV8,
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  AppStrings.callDeclined(req.declineReason!),
                  style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

