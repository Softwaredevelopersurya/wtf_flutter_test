import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainer_app/shared/shared.dart';
import '../providers/trainer_view_model.dart';

class TrainerChatScreen extends StatefulWidget {
  const TrainerChatScreen({super.key});

  @override
  State<TrainerChatScreen> createState() => _TrainerChatScreenState();
}

class _TrainerChatScreenState extends State<TrainerChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  static const List<String> _trainerQuickReplies = [
    "Great form! 👍",
    "Check updated workout",
    "See you on call at 6!",
    "Stay hydrated!",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainerViewModel>().markMessagesAsRead();
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

    final vm = context.read<TrainerViewModel>();
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
                const Text('Share Coaching Resource', style: AppTypography.h3),
                AppSpacing.gapV16,
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.trainerPrimary, child: Icon(Icons.menu_book, color: Colors.white)),
                  title: const Text('Workout Chart / Routine'),
                  subtitle: const Text('Send customized workout diagram'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleSendWithAttachment('https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400', 'Here is your revised workout routine for this week.');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.restaurant, color: Colors.white)),
                  title: const Text('Nutrition Guide'),
                  subtitle: const Text('Send macro breakdown chart'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleSendWithAttachment('https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400', 'Macro meal template for your caloric goal.');
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
    final vm = context.read<TrainerViewModel>();
    await vm.sendMessage(text, attachmentUrl: url);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainerViewModel>();
    final user = vm.currentUser;
    final member = vm.primaryMember;
    final messages = vm.messagesForPrimaryMember;
    final isTyping = member != null && vm.isMemberTyping(member.id);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: member?.avatarUrl != null ? NetworkImage(member!.avatarUrl!) : null,
              child: member?.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            AppSpacing.gapH12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member?.name ?? 'DK', style: AppTypography.bodyMediumSemiBold),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      AppSpacing.gapH4,
                      const Text('Athlete • Member', style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                            final senderRole = isCurrent ? UserRole.trainer : UserRole.member;

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
                TypingIndicator(senderName: member.name),

              // Quick Replies Chips
              QuickRepliesBar(
                replies: _trainerQuickReplies,
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
                color: AppColors.trainerPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.trainerPrimary),
            ),
            AppSpacing.gapV16,
            const Text(AppStrings.emptyChat, style: AppTypography.bodyLarge, textAlign: TextAlign.center),
            AppSpacing.gapV16,
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.trainerPrimary,
                minimumSize: const Size(160, 44),
              ),
              icon: const Icon(Icons.waving_hand_rounded, size: 18),
              label: const Text('Say hi to DK'),
              onPressed: () => _handleSend('Hi DK, ready for this week’s coaching plan?'),
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
              icon: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.trainerPrimary),
              tooltip: 'Attach Resource',
              onPressed: _showAttachmentPicker,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type trainer response...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            AppSpacing.gapH8,
            Material(
              color: AppColors.trainerPrimary,
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


