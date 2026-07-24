import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/bloc/value_cubit.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class ThreadChatState {
  final List<ChatMessage> replies;
  final bool isLoading;

  const ThreadChatState({
    this.replies = const [],
    this.isLoading = true,
  });

  ThreadChatState copyWith({
    List<ChatMessage>? replies,
    bool? isLoading,
  }) {
    return ThreadChatState(
      replies: replies ?? this.replies,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ThreadChatScreen extends StatefulWidget {
  final String parentMessageId;
  final String chatId;
  final String? prescriptionUrl;
  final String? notes;
  final String? patientName;

  const ThreadChatScreen({
    super.key,
    required this.parentMessageId,
    required this.chatId,
    this.prescriptionUrl,
    this.notes,
    this.patientName,
  });

  @override
  State<ThreadChatScreen> createState() => _ThreadChatScreenState();
}

class _ThreadChatScreenState extends State<ThreadChatScreen> {
  late final ValueCubit<ThreadChatState> _threadCubit;
  late final TextEditingController _replyController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _threadCubit = ValueCubit<ThreadChatState>(const ThreadChatState());
    _replyController = TextEditingController();
    _scrollController = ScrollController();
    _fetchThreadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _threadCubit.close();
    super.dispose();
  }

  Future<void> _fetchThreadReplies() async {
    try {
      final repo = context.read<SupabaseChatRepository>();
      final result = await repo.fetchThreadReplies(widget.parentMessageId);
      final List<ChatMessage> replies = (result['replies'] as List<ChatMessage>?) ?? [];

      if (!mounted) return;

      if (replies.isNotEmpty) {
        _threadCubit.update(ThreadChatState(replies: replies, isLoading: false));
        _scrollToBottom();
        return;
      }

      // Fallback fetch if empty thread replies
      final messages = await repo.fetchChatMessages(widget.chatId);
      final threadReplies = messages
          .where((m) =>
              m.parentMessageId == widget.parentMessageId ||
              (m.appointmentId.isNotEmpty &&
                  m.appointmentId == widget.parentMessageId))
          .toList();

      if (mounted) {
        _threadCubit.update(ThreadChatState(replies: threadReplies, isLoading: false));
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        _threadCubit.update(ThreadChatState(replies: _threadCubit.state.replies, isLoading: false));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendReply(String currentPartnerId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    _replyController.clear();
    final repo = context.read<SupabaseChatRepository>();

    try {
      final replyMsg = ChatMessage(
        id: 'reply-${DateTime.now().millisecondsSinceEpoch}',
        chatId: widget.chatId,
        appointmentId: widget.parentMessageId,
        senderId: currentPartnerId,
        senderRole: 'partner',
        content: text,
        parentMessageId: widget.parentMessageId,
        timestamp: DateTime.now(),
      );

      final updatedList = List<ChatMessage>.from(_threadCubit.state.replies)..add(replyMsg);
      _threadCubit.update(_threadCubit.state.copyWith(replies: updatedList));
      _scrollToBottom();

      await repo.sendMessage(
        chatId: widget.chatId,
        appointmentId: widget.parentMessageId,
        senderId: currentPartnerId,
        senderRole: 'partner',
        content: text,
        parentMessageId: widget.parentMessageId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentPartnerId = '';
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      currentPartnerId = authState.partner.id;
    }

    return BlocProvider.value(
      value: _threadCubit,
      child: Scaffold(
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
              Text(widget.patientName ?? 'Prescription Thread',
                  style: TextStyles.headingSemiBold.copyWith(fontSize: 16)),
              Text(
                'Prescription Thread Replies',
                style: TextStyles.labelRegular.copyWith(
                  fontSize: 11,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Sticky Parent Prescription Card Header
            Container(
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
                  if (widget.prescriptionUrl != null && widget.prescriptionUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.prescriptionUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.blue3,
                          child: const Icon(Icons.picture_as_pdf, color: AppColors.error),
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
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.blue1),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medication_rounded, size: 16, color: AppColors.blue1),
                            const SizedBox(width: 4),
                            Text(
                              'Root Prescription Inquiry',
                              style: TextStyles.headingSemiBold.copyWith(
                                fontSize: 13,
                                color: AppColors.blue1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.notes != null && widget.notes!.isNotEmpty
                              ? '"${widget.notes}"'
                              : 'Patient uploaded prescription image/document for inquiry.',
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
            ),

            // Thread Reply Messages List with ValueCubit Reactive Builder
            Expanded(
              child: BlocBuilder<ValueCubit<ThreadChatState>, ThreadChatState>(
                bloc: _threadCubit,
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.blue1),
                    );
                  }

                  if (state.replies.isEmpty) {
                    return Center(
                      child: Text(
                        'No replies in this thread yet. Send a response below.',
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
                      final isMe = msg.isSentByMe || msg.senderId == currentPartnerId;
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
                              Text(
                                msg.content,
                                style: TextStyles.bodyRegular.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyles.labelRegular.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Reply Input Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.blue3, width: 2),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Reply to this prescription inquiry...',
                          fillColor: AppColors.blue3,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendReply(currentPartnerId),
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
                        onPressed: () => _sendReply(currentPartnerId),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
