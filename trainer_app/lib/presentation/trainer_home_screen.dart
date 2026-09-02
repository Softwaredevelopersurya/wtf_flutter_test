import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import '../providers/trainer_view_model.dart';
import 'trainer_members_screen.dart';
import 'trainer_chat_screen.dart';
import 'trainer_requests_screen.dart';
import 'trainer_sessions_screen.dart';
import 'trainer_login_screen.dart';

class TrainerHomeScreen extends StatelessWidget {
  const TrainerHomeScreen({super.key});

  void _startTrainerVideoCall(BuildContext context, TrainerViewModel vm, CallRequest callReq) {
    if (vm.currentUser == null || vm.primaryMember == null) return;

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
                peerUser: vm.primaryMember!,
                callRequest: callReq,
                onCallEnded: (startedAt, endedAt) async {
                  // End call -> Auto write SessionLog
                  final log = await vm.recordCompletedSession(
                    memberId: callReq.memberId,
                    startedAt: startedAt,
                    endedAt: endedAt,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop(); // Exit call screen

                    // Show Trainer Post-call sheet (Quick notes + "Mark as complete")
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => TrainerPostCallSheet(
                        onComplete: (notes) async {
                          await vm.submitTrainerNotes(log.id, notes);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Session completed & trainer notes saved to logs!'),
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
    final vm = context.watch<TrainerViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.trainerPrimary)),
      );
    }

    final user = vm.currentUser;
    final pendingCount = vm.pendingRequests.length;
    final unreadCount = vm.unreadChatCount;
    final upcomingCall = vm.nextUpcomingApprovedCall;
    final lastMsg = vm.lastChatMessage;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
              child: user?.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            AppSpacing.gapH12,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Coach Aarav', style: AppTypography.h3),
                const CustomBadge(text: 'Lead Trainer', backgroundColor: AppColors.trainerPrimary),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Log out',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const TrainerLoginScreen()),
              );
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
              // Upcoming Call Banner (if any approved call)
              if (upcomingCall != null) ...[
                _buildUpcomingCallBanner(context, vm, upcomingCall),
                AppSpacing.gapV16,
              ],

              Text('Trainer Operations Console', style: AppTypography.h1),
              AppSpacing.gapV4,
              Text(
                'Manage assigned members, calls, and coaching requests.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              AppSpacing.gapV24,

              // 4-Tile Grid (Members, Chats, Requests, Sessions)
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Tile 1: Members
                  _buildDashboardTile(
                    title: 'Members',
                    count: '${vm.members.length}',
                    subtitle: 'Assigned athletes',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF3A86FF),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TrainerMembersScreen()),
                      );
                    },
                  ),

                  // Tile 2: Chats
                  _buildDashboardTile(
                    title: 'Chats',
                    count: unreadCount > 0 ? '$unreadCount New' : '${vm.messagesForPrimaryMember.length}',
                    subtitle: lastMsg != null ? Formatters.timeAgo(lastMsg.createdAt) : 'No messages',
                    icon: Icons.chat_rounded,
                    badgeCount: unreadCount,
                    color: AppColors.trainerPrimary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TrainerChatScreen()),
                      );
                    },
                  ),

                  // Tile 3: Requests
                  _buildDashboardTile(
                    title: 'Requests',
                    count: '$pendingCount Pending',
                    subtitle: 'Call bookings',
                    icon: Icons.calendar_month_rounded,
                    badgeCount: pendingCount,
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TrainerRequestsScreen()),
                      );
                    },
                  ),

                  // Tile 4: Sessions
                  _buildDashboardTile(
                    title: 'Sessions',
                    count: '${vm.completedSessions.length}',
                    subtitle: 'Completed logs',
                    icon: Icons.analytics_rounded,
                    color: AppColors.success,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TrainerSessionsScreen()),
                      );
                    },
                  ),
                ],
              ),

              AppSpacing.gapV24,

              // Quick Action: Pending Requests Preview
              if (pendingCount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pending Call Approvals', style: AppTypography.h3),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TrainerRequestsScreen()),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                AppSpacing.gapV8,
                ...vm.pendingRequests.take(2).map((req) => _buildQuickRequestCard(context, vm, req)),
              ],
            ],
          ),
          const FloatingDevPanelButton(),
        ],
      ),
    );
  }

  Widget _buildUpcomingCallBanner(BuildContext context, TrainerViewModel vm, CallRequest callReq) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.trainerPrimary, Color(0xFFB00020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.trainerPrimary.withOpacity(0.35),
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
                    Icon(Icons.video_call_rounded, color: Colors.white, size: 14),
                    AppSpacing.gapH4,
                    Text('Trainer Host Live Session', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
            'Member: DK • Topic: "${callReq.note}"',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          AppSpacing.gapV12,
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.trainerPrimary,
            ),
            icon: const Icon(Icons.videocam_rounded, color: AppColors.trainerPrimary),
            label: const Text('Start Video Call (Host)'),
            onPressed: () => _startTrainerVideoCall(context, vm, callReq),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTile({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.trainerPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(count, style: AppTypography.h2),
                  AppSpacing.gapV4,
                  Text(title, style: AppTypography.bodyMediumSemiBold),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickRequestCard(BuildContext context, TrainerViewModel vm, CallRequest req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150'),
            ),
            AppSpacing.gapH12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DK (Member)', style: AppTypography.bodyMediumSemiBold),
                  Text(
                    '${Formatters.formatFriendlyDateTime(req.scheduledFor)}: "${req.note}"',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
              tooltip: 'Approve',
              onPressed: () => vm.approveCallRequest(req.id),
            ),
          ],
        ),
      ),
    );
  }
}
