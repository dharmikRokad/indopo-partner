import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_message.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/thread_bloc.dart';
import '../bloc/thread_event.dart';
import '../bloc/thread_state.dart';

class ThreadChatScreen extends StatefulWidget {
  final String parentMessageId;
  final String chatId;
  final String? prescriptionUrl;
  final String? notes;
  final String? patientName;
  final String? partnerName;
  final String? patientId;

  const ThreadChatScreen({
    super.key,
    required this.parentMessageId,
    required this.chatId,
    this.prescriptionUrl,
    this.notes,
    this.patientName,
    this.partnerName,
    this.patientId,
  });

  @override
  State<ThreadChatScreen> createState() => _ThreadChatScreenState();
}

class _ThreadChatScreenState extends State<ThreadChatScreen> {
  late final TextEditingController _replyController;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) _scrollToBottom(delayMs: 300);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({int delayMs = 100}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendReply(BuildContext context) {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final authState = context.read<AuthBloc>().state;
    final partnerName = widget.partnerName ?? authState.partner?.name;
    _replyController.clear();
    _focusNode.requestFocus();
    context.read<ThreadBloc>().add(
          SendThreadReply(
            content: text,
            partnerName: partnerName,
            patientId: widget.patientId,
          ),
        );
    // The Supabase stream will surface the new message automatically
    _scrollToBottom(delayMs: 300);
  }

  @override
  Widget build(BuildContext context) {
    String currentPartnerId = '';
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthBlocStatus.authenticated &&
        authState.partner != null) {
      currentPartnerId = authState.partner!.id;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.blue3,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patientName ?? 'Prescription Inquiry',
              style: TextStyles.headingSemiBold.copyWith(fontSize: 16),
            ),
            Text(
              widget.notes != null && widget.notes!.isNotEmpty
                  ? '"${widget.notes}"'
                  : '📷 Prescription Inquiry Thread',
              style: TextStyles.labelRegular.copyWith(
                fontSize: 11,
                color: AppColors.blue1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: BlocConsumer<ThreadBloc, ThreadState>(
        listener: (context, state) {
          if (state.status == ThreadStatus.loaded) {
            _scrollToBottom(delayMs: 200);
          }
        },
        builder: (context, state) {
          return NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              _scrollToBottom(delayMs: 150);
              return true;
            },
            child: SizeChangedLayoutNotifier(
              child: Column(
                children: [
                  // Sticky prescription header
                  _PrescriptionHeader(
                    prescriptionUrl: widget.prescriptionUrl,
                    notes: widget.notes,
                    patientName: widget.patientName,
                  ),

                  // Replies list
                  Expanded(child: _buildRepliesList(state, currentPartnerId)),

                  // Reply input
                  _ReplyInputBar(
                    controller: _replyController,
                    focusNode: _focusNode,
                    onSend: () => _sendReply(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRepliesList(ThreadState state, String currentPartnerId) {
    if (state.status == ThreadStatus.loading ||
        state.status == ThreadStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue1),
      );
    }

    if (state.status == ThreadStatus.failure) {
      return Center(
        child: Text(
          'Failed to load thread: ${state.errorMessage}',
          style: TextStyles.labelRegular.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    if (state.status == ThreadStatus.loaded) {
      if (state.replies.isEmpty) {
        return Center(
          child: Text(
            'No replies yet. Send a response below.',
            style: TextStyles.labelRegular.copyWith(color: AppColors.textMuted),
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.replies.length,
        itemBuilder: (context, index) {
          final msg = state.replies[index];
          final bool isMe =
              msg.senderId == currentPartnerId || msg.senderRole == 'PARTNER';
          return _MessageBubble(message: msg, isMe: isMe);
        },
      );
    }

    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _PrescriptionHeader extends StatelessWidget {
  final String? prescriptionUrl;
  final String? notes;
  final String? patientName;

  const _PrescriptionHeader({
    this.prescriptionUrl,
    this.notes,
    this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.blue1.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prescription thumbnail
          if (prescriptionUrl != null && prescriptionUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        prescriptionUrl!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  prescriptionUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.blue3,
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.blue3,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.blue1,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medication_rounded,
                      size: 16,
                      color: AppColors.blue1,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${patientName ?? 'Patient'}'s Prescription",
                        style: TextStyles.headingSemiBold.copyWith(
                          fontSize: 13,
                          color: AppColors.blue1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notes != null && notes!.isNotEmpty
                      ? '"$notes"'
                      : 'Patient uploaded prescription for inquiry.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.bodyRegular.copyWith(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColors.blue2 : AppColors.surface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message.content,
              style: TextStyles.bodyRegular.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyles.labelRegular.copyWith(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _ReplyInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.blue3, width: 2)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Reply to this prescription inquiry...',
                  fillColor: AppColors.blue3,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.blue1,
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
