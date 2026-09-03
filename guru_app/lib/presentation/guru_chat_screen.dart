import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import '../providers/guru_view_model.dart';
import 'schedule_call_screen.dart';

class GuruChatScreen extends StatefulWidget {
  const GuruChatScreen({super.key});

  @override
  State<GuruChatScreen> createState() => _GuruChatScreenState();
}

class _GuruChatScreenState extends State<GuruChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuruViewModel>().markMessagesAsRead();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    final vm = context.read<GuruViewModel>();
    setState(() => _isSending = true);
    _textController.clear();

    await vm.sendMessage(text);
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _showAttachmentPicker() {
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
                const Text('Attach Media', style: AppTypography.h3),
                AppSpacing.gapV16,
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.fitness_center, color: Colors.white)),
                  title: const Text('Workout Log / Meal Photo'),
                  subtitle: const Text('Share your macro bowl or exercise form check'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleSendWithAttachment('https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', 'Sharing my meal photo today!');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.image, color: Colors.white)),
                  title: const Text('Progress Selfie'),
                  subtitle: const Text('Weekly physique progress comparison'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleSendWithAttachment('https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400', 'Form check update from today’s session.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSendWithAttachment(String url, String text) async {
    final vm = context.read<GuruViewModel>();
    await vm.sendMessage(text, attachmentUrl: url);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GuruViewModel>();
    final user = vm.currentUser;
    final trainer = vm.assignedTrainer;
    final messages = vm.messages;
    if (messages.length != _previousMessageCount) {
      _previousMessageCount = messages.length;
      _scrollToBottom();
    }
    final isTyping = vm.isTrainerTyping;
    final upcomingCall = vm.nextUpcomingApprovedCall;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: trainer?.avatarUrl != null ? NetworkImage(trainer!.avatarUrl!) : null,
              child: trainer?.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            AppSpacing.gapH12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trainer?.name ?? 'Coach Aarav', style: AppTypography.bodyMediumSemiBold),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      AppSpacing.gapH4,
                      const Text('Online • Lead Trainer', style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 100ms Call Shortcut in Chat toolbar
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.videocam_rounded, color: AppColors.guruPrimary, size: 26),
                tooltip: 'Video Call Coach',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScheduleCallScreen()),
                  );
                },
              ),
              if (upcomingCall != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.trainerPrimary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          AppSpacing.gapH4,
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Chat Messages List
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await vm.markMessagesAsRead();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isCurrent = message.senderId == user?.id;
                            final senderRole = isCurrent ? UserRole.member : UserRole.trainer;

                            return ChatBubble(
                              message: message,
                              isCurrentUser: isCurrent,
                              senderRole: senderRole,
                            );
                          },
                        ),
                      ),
              ),

              // Animated Typing Indicator
              if (isTyping)
                TypingIndicator(senderName: trainer?.name.split(' ')[0] ?? 'Coach'),

              // Quick Replies Chips
              QuickRepliesBar(
                replies: AppStrings.quickReplies,
                onSelected: (reply) => _handleSend(reply),
              ),

              // Sticky Multiline Input Bar
              _buildInputBar(),
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
                color: AppColors.guruPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.guruPrimary),
            ),
            AppSpacing.gapV16,
            const Text(AppStrings.emptyChat, style: AppTypography.bodyLarge, textAlign: TextAlign.center),
            AppSpacing.gapV16,
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              icon: const Icon(Icons.waving_hand_rounded, size: 18),
              label: const Text('Say hi'),
              onPressed: () => _handleSend('Hi Coach 👍'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.guruPrimary),
              tooltip: 'Attach Image',
              onPressed: _showAttachmentPicker,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            AppSpacing.gapH8,
            Material(
              color: AppColors.guruPrimary,
              shape: const CircleBorder(),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _isSending ? null : () => _handleSend(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



