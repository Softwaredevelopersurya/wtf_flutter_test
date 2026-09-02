import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guru_app/shared/shared.dart';
import '../providers/guru_view_model.dart';
import 'guru_chat_screen.dart';
import 'schedule_call_screen.dart';
import 'guru_sessions_screen.dart';
import 'onboarding_screen.dart';

class GuruHomeScreen extends StatelessWidget {
  const GuruHomeScreen({super.key});

  void _startVideoCallFlow(BuildContext context, GuruViewModel vm, CallRequest callReq) {
    if (vm.currentUser == null || vm.assignedTrainer == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PreJoinDeviceCheckModal(
        currentUser: vm.currentUser!,
        callRequest: callReq,
        onJoin: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ActiveVideoCallScreen(
                currentUser: vm.currentUser!,
                peerUser: vm.assignedTrainer!,
                callRequest: callReq,
                onCallEnded: (startedAt, endedAt) async {
                  // End call -> Auto write SessionLog
                  final log = await vm.recordCompletedSession(
                    startedAt: startedAt,
                    endedAt: endedAt,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop(); // Exit call screen

                    // Show Member Post-call sheet (1-5 star rating + optional notes)
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => MemberPostCallSheet(
                        session: log,
                        onSubmit: (rating, note) async {
                          await vm.rateSession(log.id, rating, note);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you! Session rating saved to your logs.'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GuruViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.guruPrimary)),
      );
    }

    final user = vm.currentUser;
    final trainer = vm.assignedTrainer;
    final upcomingCall = vm.nextUpcomingApprovedCall;
    final unreadCount = vm.unreadChatCount;
    final lastMsg = vm.lastChatMessage;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
              child: user?.avatarUrl == null ? Text(user?.name[0] ?? 'D') : null,
            ),
            AppSpacing.gapH12,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Member', style: AppTypography.h3),
                Row(
                  children: [
                    const CustomBadge(text: 'Member', backgroundColor: AppColors.guruPrimary),
                    AppSpacing.gapH4,
                    Text('• Coach: ${trainer?.name.split(' ')[0] ?? 'Aarav'}', style: AppTypography.caption),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Reset App / Re-onboard',
            onPressed: () async {
              await vm.resetForTesting();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              }
            },
          ),
          AppSpacing.gapH4,
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: AppSpacing.paddingMd,
            children: [
              // Upcoming Approved Call Banner
              if (upcomingCall != null) ...[
                _buildUpcomingCallBanner(context, vm, upcomingCall),
                AppSpacing.gapV16,
              ],

              // Welcome greeting
              Text('Hello, ${user?.name ?? "DK"} 👋', style: AppTypography.h1),
              AppSpacing.gapV4,
              Text(
                'Let’s achieve your fitness milestones today.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              AppSpacing.gapV24,

              // 1. Card: Chat with Trainer
              _buildHomeCard(
                title: 'Chat with Trainer',
                subtitle: lastMsg != null
                    ? '${lastMsg.senderId == user?.id ? "You: " : ""}${lastMsg.text}'
                    : 'Get nutrition advice and workout guidance',
                icon: Icons.chat_bubble_rounded,
                badgeCount: unreadCount,
                color: AppColors.guruPrimary,
                trailingTime: lastMsg != null ? Formatters.timeAgo(lastMsg.createdAt) : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GuruChatScreen()),
                  );
                },
              ),

              AppSpacing.gapV16,

              // 2. Card: Schedule Call
              _buildHomeCard(
                title: 'Schedule Call',
                subtitle: 'Book a 1-on-1 30-min live video coaching session',
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF0096C7),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScheduleCallScreen()),
                  );
                },
              ),

              AppSpacing.gapV16,

              // 3. Card: My Sessions
              _buildHomeCard(
                title: 'My Sessions',
                subtitle: '${vm.mySessions.length} completed logs and coach reviews',
                icon: Icons.history_edu_rounded,
                color: const Color(0xFF023E8A),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GuruSessionsScreen()),
                  );
                },
              ),
            ],
          ),
          const FloatingDevPanelButton(),
        ],
      ),
    );
  }

  Widget _buildUpcomingCallBanner(BuildContext context, GuruViewModel vm, CallRequest callReq) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.guruPrimary, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.guruPrimary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.video_camera_front_rounded, color: Colors.white, size: 14),
                    AppSpacing.gapH4,
                    Text('Upcoming Video Session', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(
                Formatters.formatFriendlyDateTime(callReq.scheduledFor),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          AppSpacing.gapV12,
          Text(
            'Topic: "${callReq.note}"',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          AppSpacing.gapV12,
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.guruPrimary,
              elevation: 0,
            ),
            icon: const Icon(Icons.videocam_rounded, color: AppColors.guruPrimary),
            label: const Text('Join Call Now'),
            onPressed: () => _startVideoCallFlow(context, vm, callReq),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    int badgeCount = 0,
    String? trailingTime,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              AppSpacing.gapH16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: AppTypography.h3),
                        if (trailingTime != null)
                          Text(trailingTime, style: AppTypography.caption),
                      ],
                    ),
                    AppSpacing.gapV4,
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0) ...[
                AppSpacing.gapH8,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.trainerPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                AppSpacing.gapH8,
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



