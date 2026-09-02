import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainer_app/shared/shared.dart';
import '../providers/trainer_view_model.dart';
import 'trainer_chat_screen.dart';
import 'trainer_sessions_screen.dart';

class TrainerMembersScreen extends StatelessWidget {
  const TrainerMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainerViewModel>();
    final members = vm.members;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Assigned Members (Athletes)'),
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: AppSpacing.paddingMd,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                            child: member.avatarUrl == null ? Text(member.name[0]) : null,
                          ),
                          AppSpacing.gapH16,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(member.name, style: AppTypography.h3),
                                    AppSpacing.gapH8,
                                    const CustomBadge(text: 'Active Plan', backgroundColor: AppColors.guruPrimary),
                                  ],
                                ),
                                AppSpacing.gapV4,
                                Text(member.email, style: AppTypography.caption),
                                AppSpacing.gapV4,
                                Text(
                                  'Focus: Hypertrophy & Nutrition Review',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapV16,
                      const Divider(height: 1, color: AppColors.borderLight),
                      AppSpacing.gapV12,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.trainerPrimary,
                                side: const BorderSide(color: AppColors.trainerPrimary),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: const Text('Open Chat'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TrainerChatScreen()),
                                );
                              },
                            ),
                          ),
                          AppSpacing.gapH8,
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.trainerPrimary,
                              ),
                              icon: const Icon(Icons.history_edu_rounded, size: 16),
                              label: const Text('Past Logs'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TrainerSessionsScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const FloatingDevPanelButton(),
        ],
      ),
    );
  }
}

