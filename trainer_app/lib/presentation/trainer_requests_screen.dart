import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainer_app/shared/shared.dart';
import '../providers/trainer_view_model.dart';

class TrainerRequestsScreen extends StatefulWidget {
  const TrainerRequestsScreen({super.key});

  @override
  State<TrainerRequestsScreen> createState() => _TrainerRequestsScreenState();
}

class _TrainerRequestsScreenState extends State<TrainerRequestsScreen> {
  int _selectedTabIndex = 0; // 0: Pending, 1: History

  void _showDeclineReasonModal(BuildContext context, TrainerViewModel vm, CallRequest req) {
    final reasonController = TextEditingController(text: 'Schedule conflict, please pick another slot');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Decline Call Request', style: AppTypography.h2),
              AppSpacing.gapV8,
              Text(
                'Provide a brief reason to notify the member.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              AppSpacing.gapV16,

              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. In coaching session, please choose tomorrow 10:00 AM',
                ),
              ),

              AppSpacing.gapV24,

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isNotEmpty) {
                    await vm.declineCallRequest(req.id, reason);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.callDeclined(reason)),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Confirm Decline'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainerViewModel>();
    final pendingRequests = vm.pendingRequests;
    final allRequests = vm.allRequests;
    final displayList = _selectedTabIndex == 0 ? pendingRequests : allRequests;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Call Booking Requests'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Tabs: Pending vs All
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('Pending (${pendingRequests.length})')),
                        selected: _selectedTabIndex == 0,
                        selectedColor: AppColors.trainerPrimary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: _selectedTabIndex == 0 ? AppColors.trainerPrimary : AppColors.textSecondary,
                          fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedTabIndex = 0);
                        },
                      ),
                    ),
                    AppSpacing.gapH8,
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('All Requests (${allRequests.length})')),
                        selected: _selectedTabIndex == 1,
                        selectedColor: AppColors.trainerPrimary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: _selectedTabIndex == 1 ? AppColors.trainerPrimary : AppColors.textSecondary,
                          fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedTabIndex = 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Request Cards
              Expanded(
                child: displayList.isEmpty
                    ? Center(
                        child: Text(
                          _selectedTabIndex == 0 ? 'No pending requests.' : 'No request history.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: AppSpacing.paddingMd,
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final req = displayList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                          const CircleAvatar(
                                            radius: 16,
                                            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150'),
                                          ),
                                          AppSpacing.gapH8,
                                          Text('DK (Member)', style: AppTypography.bodyMediumSemiBold),
                                        ],
                                      ),
                                      _buildStatusBadge(req.status),
                                    ],
                                  ),
                                  AppSpacing.gapV12,

                                  // Scheduled Date & Time
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.trainerPrimary),
                                      AppSpacing.gapH8,
                                      Text(
                                        Formatters.formatFriendlyDateTime(req.scheduledFor),
                                        style: AppTypography.bodyMediumSemiBold,
                                      ),
                                    ],
                                  ),
                                  AppSpacing.gapV4,

                                  // Member Note
                                  Text(
                                    'Note: "${req.note}"',
                                    style: AppTypography.bodyMedium,
                                  ),

                                  if (req.declineReason != null) ...[
                                    AppSpacing.gapV8,
                                    Text('Reason: ${req.declineReason}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                                  ],

                                  // Action Buttons for Pending Requests
                                  if (req.isPending) ...[
                                    AppSpacing.gapV16,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                              side: const BorderSide(color: AppColors.error),
                                            ),
                                            onPressed: () => _showDeclineReasonModal(context, vm, req),
                                            child: const Text('Decline'),
                                          ),
                                        ),
                                        AppSpacing.gapH12,
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.success,
                                            ),
                                            onPressed: () async {
                                              await vm.approveCallRequest(req.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(AppStrings.callApprovedShort(Formatters.formatTimeOnly(req.scheduledFor))),
                                                    backgroundColor: AppColors.success,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('Approve'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          const FloatingDevPanelButton(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CallRequestStatus status) {
    Color color;
    String label;

    switch (status) {
      case CallRequestStatus.approved:
        color = AppColors.success;
        label = 'Approved';
        break;
      case CallRequestStatus.declined:
        color = AppColors.error;
        label = 'Declined';
        break;
      case CallRequestStatus.cancelled:
        color = AppColors.textMuted;
        label = 'Cancelled';
        break;
      case CallRequestStatus.pending:
        color = AppColors.warning;
        label = 'Pending Action';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

