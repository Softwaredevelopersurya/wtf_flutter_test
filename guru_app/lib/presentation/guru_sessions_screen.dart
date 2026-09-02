import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import '../providers/guru_view_model.dart';
import 'schedule_call_screen.dart';

enum SessionFilter {
  all('All'),
  last7Days('Last 7 days'),
  thisMonth('This Month');

  final String label;
  const SessionFilter(this.label);
}

class GuruSessionsScreen extends StatefulWidget {
  const GuruSessionsScreen({super.key});

  @override
  State<GuruSessionsScreen> createState() => _GuruSessionsScreenState();
}

class _GuruSessionsScreenState extends State<GuruSessionsScreen> {
  SessionFilter _currentFilter = SessionFilter.all;

  List<SessionLog> _applyFilter(List<SessionLog> sessions) {
    final now = DateTime.now();
    switch (_currentFilter) {
      case SessionFilter.last7Days:
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return sessions.where((s) => s.startedAt.isAfter(sevenDaysAgo)).toList();
      case SessionFilter.thisMonth:
        return sessions.where((s) => s.startedAt.year == now.year && s.startedAt.month == now.month).toList();
      case SessionFilter.all:
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
                    Text('Session Details', style: AppTypography.h2),
                    if (log.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          AppSpacing.gapH4,
                          Text('${log.rating}/5', style: AppTypography.bodyMediumSemiBold),
                        ],
                      ),
                  ],
                ),
                AppSpacing.gapV8,
                Text(
                  '${Formatters.formatDateFull(log.startedAt)} • Duration: ${log.formattedDuration}',
                  style: AppTypography.caption,
                ),
                AppSpacing.gapV16,

                // Member Notes
                Text('Your Notes & Feedback', style: AppTypography.bodyMediumSemiBold),
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
                        : 'No member notes recorded for this session.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
                AppSpacing.gapV16,

                // Trainer Notes
                Text('Trainer Feedback & Workout Plan', style: AppTypography.bodyMediumSemiBold),
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
                        : 'Trainer marked completed. No additional notes.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
                AppSpacing.gapV24,

                ElevatedButton(
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
    summary.writeln('=== WTF FITNESS: MY SESSION LOGS SUMMARY ===');
    summary.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    summary.writeln('Total Completed Sessions: ${sessions.length}');
    summary.writeln('-------------------------------------------');

    for (final s in sessions) {
      summary.writeln('Date: ${Formatters.formatFriendlyDateTime(s.startedAt)}');
      summary.writeln('Duration: ${s.formattedDuration}');
      summary.writeln('Rating: ${s.rating != null ? "${s.rating}/5 Stars" : "Not rated"}');
      if (s.memberNotes != null) summary.writeln('Member Note: ${s.memberNotes}');
      if (s.trainerNotes != null) summary.writeln('Trainer Note: ${s.trainerNotes}');
      summary.writeln('-------------------------------------------');
    }

    Clipboard.setData(ClipboardData(text: summary.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session summary report copied to clipboard!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GuruViewModel>();
    final allSessions = vm.mySessions;
    final filteredSessions = _applyFilter(allSessions);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Sessions & Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.guruPrimary),
            tooltip: 'Export Summary',
            onPressed: allSessions.isNotEmpty ? () => _exportSessionSummary(filteredSessions) : null,
          ),
          AppSpacing.gapH4,
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Chips Row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: SessionFilter.values.map((filter) {
                    final isSelected = _currentFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter.label),
                        selectedColor: AppColors.guruPrimary.withOpacity(0.15),
                        checkmarkColor: AppColors.guruPrimary,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.guruPrimary : AppColors.textSecondary,
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
                    ? _buildEmptyState()
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
                                  color: AppColors.guruPrimary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.fitness_center_rounded, color: AppColors.guruPrimary),
                              ),
                              title: Text(
                                Formatters.formatFriendlyDateTime(session.startedAt),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.guruPrimary),
            ),
            AppSpacing.gapV16,
            Text('No completed sessions found.', style: AppTypography.bodyLarge),
            AppSpacing.gapV16,
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 44)),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ScheduleCallScreen()),
                );
              },
              child: const Text('Schedule your first call'),
            ),
          ],
        ),
      ),
    );
  }
}
