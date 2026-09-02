import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/formatters.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final UserRole senderRole;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.senderRole,
  });

  @override
  Widget build(BuildContext context) {
    // Bubble color follows role definition: Member = Blue, Trainer = Red
    final bubbleColor = senderRole == UserRole.member ? AppColors.guruPrimary : AppColors.trainerPrimary;
    final alignment = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppSpacing.radiusMd),
                topRight: const Radius.circular(AppSpacing.radiusMd),
                bottomLeft: Radius.circular(isCurrentUser ? AppSpacing.radiusMd : 2),
                bottomRight: Radius.circular(isCurrentUser ? 2 : AppSpacing.radiusMd),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Optional Attachment Thumbnail
                if (message.attachmentUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Image.network(
                      message.attachmentUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: Colors.white24,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapV8,
                ],

                // Message Text
                Text(
                  message.text,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
                AppSpacing.gapV4,

                // Timestamp and Status Ticks
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatTimeOnly(message.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    if (isCurrentUser) ...[
                      AppSpacing.gapH4,
                      _buildStatusIcon(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    if (status == MessageStatus.sending) {
      return const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
      );
    } else if (status == MessageStatus.sent) {
      return const Icon(Icons.check, size: 13, color: Colors.white70);
    } else {
      return const Icon(Icons.done_all, size: 14, color: Colors.white);
    }
  }
}

/// Animated 3-dot Typing Indicator
class TypingIndicator extends StatefulWidget {
  final String senderName;
  const TypingIndicator({super.key, required this.senderName});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.senderName} is typing',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                AppSpacing.gapH8,
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final value = (_controller.value + (index * 0.2)) % 1.0;
                        final scale = 0.5 + (0.5 * (1.0 - (value - 0.5).abs() * 2));
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textSecondary.withOpacity(scale),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Reply Chips Bar
class QuickRepliesBar extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onSelected;

  const QuickRepliesBar({
    super.key,
    required this.replies,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, __) => AppSpacing.gapH8,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return ActionChip(
            label: Text(reply, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.surfaceLight,
            side: const BorderSide(color: AppColors.borderLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
            onPressed: () => onSelected(reply),
          );
        },
      ),
    );
  }
}
