import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trainer_app/shared/shared.dart';
import '../providers/trainer_view_model.dart';

enum TrainerSessionFilter {
  all('All'),
  last7Days('Last 7 days'),
  thisMonth('This Month');

  final String label;
  const TrainerSessionFilter(this.label);
}

class TrainerSessionsScreen extends StatefulWidget {
  const TrainerSessionsScreen({super.key});

  @override
  State<TrainerSessionsScreen> createState() => _TrainerSessionsScreenState();
}

class _TrainerSessionsScreenState extends State<TrainerSessionsScreen> {
  TrainerSessionFilter _currentFilter = TrainerSessionFilter.all;

  List<SessionLog> _applyFilter(List<SessionLog> sessions) {
    final now = DateTime.now();
    switch (_currentFilter) {
      case TrainerSessionFilter.last7Days:
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return sessions.where((s) => s.startedAt.isAfter(sevenDaysAgo)).toList();
      case TrainerSessionFilter.thisMonth:
        return sessions.where((s) => s.startedAt.year == now.year && s.startedAt.month == now.month).toList();
      case TrainerSessionFilter.all:
        return sessions;
    }
  }

  void _showSessionDetails(SessionLog log) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Completed Session Log', style: AppTypography.h2),
                    if (log.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          AppSpacing.gapH4,
                          Text('${log.rating}/5 Member Rating', style: AppTypography.bodyMediumSemiBold),
                        ],
                      ),
                  ],
                ),
                AppSpacing.gapV8,
                Text(
                  'Member: DK • ${Formatters.formatDateFull(log.startedAt)} • Duration: ${log.formattedDuration}',
                  style: AppTypography.caption,
                ),
                AppSpacing.gapV16,

                // Trainer Notes
                Text('Trainer Feedback & Directives', style: AppTypography.bodyMediumSemiBold),
                AppSpacing.gapV4,
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    log.trainerNotes != null && log.trainerNotes!.isNotEmpty
                        ? log.trainerNotes!
                        : 'No trainer notes recorded.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
                AppSpacing.gapV16,

                // Member Notes
                Text('Member Feedback', style: AppTypography.bodyMediumSemiBold),
                AppSpacing.gapV4,
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    log.memberNotes != null && log.memberNotes!.isNotEmpty
                        ? log.memberNotes!
                        : 'No member comments.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
                AppSpacing.gapV24,

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.trainerPrimary),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exportSessionSummary(List<SessionLog> sessions) {
    if (sessions.isEmpty) return;

    final summary = StringBuffer();
    summary.writeln('=== WTF FITNESS: TRAINER SESSIONS & CLIENT LOGS ===');
    summary.writeln('Coach: Aarav (Lead Trainer)');
    summary.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    summary.writeln('Total Client Sessions: ${sessions.length}');
    summary.writeln('--------------------------------------------------');

    for (final s in sessions) {
      summary.writeln('Athlete: DK');
      summary.writeln('Date: ${Formatters.formatFriendlyDateTime(s.startedAt)}');
      summary.writeln('Duration: ${s.formattedDuration}');
      summary.writeln('Member Rating: ${s.rating != null ? "${s.rating}/5 Stars" : "Pending rating"}');
      if (s.trainerNotes != null) summary.writeln('Trainer Notes: ${s.trainerNotes}');
      if (s.memberNotes != null) summary.writeln('Member Feedback: ${s.memberNotes}');
      summary.writeln('--------------------------------------------------');
    }

    Clipboard.setData(ClipboardData(text: summary.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Client sessions exported to clipboard!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainerViewModel>();
    final allSessions = vm.completedSessions;
    final filteredSessions = _applyFilter(allSessions);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Session Logs & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.trainerPrimary),
            tooltip: 'Export Client Report',
            onPressed: allSessions.isNotEmpty ? () => _exportSessionSummary(filteredSessions) : null,
          ),
          AppSpacing.gapH4,
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Chips
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: TrainerSessionFilter.values.map((filter) {
                    final isSelected = _currentFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter.label),
                        selectedColor: AppColors.trainerPrimary.withOpacity(0.15),
                        checkmarkColor: AppColors.trainerPrimary,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.trainerPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _currentFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Sessions List
              Expanded(
                child: filteredSessions.isEmpty
                    ? Center(
                        child: Text(
                          'No completed sessions found for this period.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: AppSpacing.paddingMd,
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.trainerPrimary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.sports_gymnastics_rounded, color: AppColors.trainerPrimary),
                              ),
                              title: Text(
                                'Member: DK (${Formatters.formatFriendlyDateTime(session.startedAt)})',
                                style: AppTypography.bodyMediumSemiBold,
                              ),
                              subtitle: Row(
                                children: [
                                  Text('Duration: ${session.formattedDuration}', style: AppTypography.caption),
                                  if (session.rating != null) ...[
                                    AppSpacing.gapH8,
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    Text('${session.rating}/5', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                              onTap: () => _showSessionDetails(session),
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
}

