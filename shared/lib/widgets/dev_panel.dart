import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/log_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class FloatingDevPanelButton extends StatelessWidget {
  const FloatingDevPanelButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          onTap: () => showDevPanel(context),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.darkSurface.withOpacity(0.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

void showDevPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const DevPanelModal(),
  );
}

class DevPanelModal extends StatefulWidget {
  const DevPanelModal({super.key});

  @override
  State<DevPanelModal> createState() => _DevPanelModalState();
}

class _DevPanelModalState extends State<DevPanelModal> {
  final LogService _logService = LogService();
  LogTag? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.darkSurfaceVariant)),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_mode_rounded, color: AppColors.guruPrimary, size: 22),
                AppSpacing.gapH8,
                Text(
                  'Developer Panel & Observability',
                  style: AppTypography.h3.copyWith(color: AppColors.darkText),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.darkTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: AppSpacing.paddingMd,
              children: [
                _buildEnvSection(),
                AppSpacing.gapV16,
                _buildBuildInfoSection(),
                AppSpacing.gapV16,
                _buildLogsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvSection() {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.darkSurfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.warning),
              AppSpacing.gapH8,
              Text('Environment Variables (Masked)', style: AppTypography.bodyMediumSemiBold.copyWith(color: AppColors.darkText)),
            ],
          ),
          AppSpacing.gapV8,
          _buildEnvRow('HMS_APP_ACCESS_KEY', 'dev_***_key'),
          _buildEnvRow('HMS_APP_SECRET', 'dev_***_ret'),
          _buildEnvRow('TOKEN_SERVER_URL', 'http://localhost:8080'),
          _buildEnvRow('HMS_DEFAULT_ROOM', 'room_wtf_default_01'),
        ],
      ),
    );
  }

  Widget _buildEnvRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextMuted, fontFamily: 'monospace')),
          Text(value, style: AppTypography.bodySmall.copyWith(color: AppColors.darkText, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBuildInfoSection() {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.darkSurfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.guruPrimary),
              AppSpacing.gapH8,
              Text('Build & Runtime Info', style: AppTypography.bodyMediumSemiBold.copyWith(color: AppColors.darkText)),
            ],
          ),
          AppSpacing.gapV8,
          _buildEnvRow('FLUTTER_VERSION', '3.33.0'),
          _buildEnvRow('DART_SDK', '3.10.0'),
          _buildEnvRow('RTC_PROVIDER', '100ms Live Video SDK'),
          _buildEnvRow('STORAGE_MODE', 'Local Sync Engine (Reactive Stream)'),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    return StreamBuilder<List<LogEntry>>(
      stream: _logService.logStream,
      initialData: _logService.logs,
      builder: (context, snapshot) {
        final allLogs = snapshot.data ?? [];
        final filteredLogs = _selectedFilter == null
            ? allLogs
            : allLogs.where((l) => l.tag == _selectedFilter).toList();

        final recentLogs = filteredLogs.take(20).toList();

        return Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.darkSurfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt_rounded, size: 16, color: AppColors.success),
                      AppSpacing.gapH8,
                      Text('Recent Structured Logs (${recentLogs.length})', style: AppTypography.bodyMediumSemiBold.copyWith(color: AppColors.darkText)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.darkTextMuted),
                        tooltip: 'Copy Error/Logs',
                        onPressed: () {
                          final text = recentLogs.map((l) => l.formatted).join('\n');
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logs copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                        tooltip: 'Clear Logs',
                        onPressed: () => _logService.clearLogs(),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.gapV8,

              // Tag Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', null),
                    AppSpacing.gapH8,
                    _buildFilterChip('[CHAT]', LogTag.chat, color: AppColors.guruPrimary),
                    AppSpacing.gapH8,
                    _buildFilterChip('[RTC]', LogTag.rtc, color: AppColors.trainerPrimary),
                    AppSpacing.gapH8,
                    _buildFilterChip('[SCHEDULE]', LogTag.schedule, color: AppColors.warning),
                    AppSpacing.gapH8,
                    _buildFilterChip('[AUTH]', LogTag.auth, color: AppColors.success),
                  ],
                ),
              ),
              AppSpacing.gapV12,

              // Log Items
              if (recentLogs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text('No logs captured yet.', style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextMuted)),
                  ),
                )
              else
                ...recentLogs.map((log) => _buildLogItem(log)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, LogTag? tag, {Color? color}) {
    final isSelected = _selectedFilter == tag;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppColors.guruPrimary) : AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.darkTextMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
    Color tagColor;
    switch (log.tag) {
      case LogTag.chat:
        tagColor = AppColors.guruPrimary;
        break;
      case LogTag.rtc:
        tagColor = AppColors.trainerPrimary;
        break;
      case LogTag.schedule:
        tagColor = AppColors.warning;
        break;
      case LogTag.auth:
        tagColor = AppColors.success;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border(left: BorderSide(color: log.isError ? AppColors.error : tagColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '[${log.tag.label}]',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor, fontFamily: 'monospace'),
              ),
              AppSpacing.gapH8,
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted, fontFamily: 'monospace'),
              ),
            ],
          ),
          AppSpacing.gapV4,
          Text(
            log.message,
            style: TextStyle(
              fontSize: 12,
              color: log.isError ? AppColors.error : AppColors.darkText,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
