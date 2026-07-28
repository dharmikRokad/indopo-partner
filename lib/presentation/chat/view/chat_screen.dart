import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../bloc/thread_bloc.dart';
import '../bloc/thread_event.dart';
import 'thread_chat_screen.dart';

class ChatScreen extends StatelessWidget {
  /// [id] is the chat room ID.
  final String id;

  const ChatScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String partnerId = '';
    bool isMedicalPartner = false;

    if (authState is AuthSuccess) {
      partnerId = authState.partner.id;
      final role = authState.partner.role;
      isMedicalPartner =
          role == PartnerType.doctor || role == PartnerType.pharmacy;
    }

    return BlocProvider(
      create: (_) =>
          ChatBloc(repo: context.read<SupabaseChatRepository>())
            ..add(InitChatStream(chatId: id, partnerId: partnerId)),
      child: _ChatContent(
        chatId: id,
        partnerId: partnerId,
        isMedicalPartner: isMedicalPartner,
      ),
    );
  }
}

class _ChatContent extends StatefulWidget {
  final String chatId;
  final String partnerId;
  final bool isMedicalPartner;

  const _ChatContent({
    required this.chatId,
    required this.partnerId,
    required this.isMedicalPartner,
  });

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.blue2,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prescription Inquiries',
                    style:
                        TextStyles.headingSemiBold.copyWith(fontSize: 16),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live Stream',
                        style: TextStyles.labelRegular.copyWith(
                          fontSize: 11,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!widget.isMedicalPartner)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              color: AppColors.error.withValues(alpha: 0.2),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Access Restricted: Chat features are only available for Doctor and Pharmacy partner profiles.',
                      style: TextStyles.bodyRegular.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.isMedicalPartner
                ? BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is ChatLoading || state is ChatInitial) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.blue1),
                        );
                      }
                      if (state is ChatFailure) {
                        return Center(
                          child: Text('Error: ${state.message}'),
                        );
                      }
                      if (state is ChatLoaded) {
                        final rootMessages = state.rootMessages;

                        if (rootMessages.isEmpty) {
                          return Center(
                            child: Text(
                              'No prescription inquiries yet.',
                              style: TextStyles.labelRegular.copyWith(
                                  color: AppColors.textMuted),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: rootMessages.length,
                          itemBuilder: (context, index) {
                            final msg = rootMessages[index];
                            return _PrescriptionInquiryCard(
                              chatId: widget.chatId,
                              partnerId: widget.partnerId,
                              rootMessage: msg,
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.forum_rounded,
                          size: 64,
                          color: AppColors.surface,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chat Disabled',
                          style: TextStyles.headingSemiBold.copyWith(
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionInquiryCard extends StatelessWidget {
  final String chatId;
  final String partnerId;
  final ChatMessage rootMessage;

  const _PrescriptionInquiryCard({
    required this.chatId,
    required this.partnerId,
    required this.rootMessage,
  });

  @override
  Widget build(BuildContext context) {
    final int replyCount = rootMessage.replyCount;
    final int unreadCount = rootMessage.unreadReplyCount;
    final String? imageUrl = rootMessage.imageUrl?.isNotEmpty == true
        ? rootMessage.imageUrl
        : null;
    final String notes = rootMessage.content.isNotEmpty &&
            rootMessage.content != '📷 Prescription Inquiry'
        ? rootMessage.content
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () async {
          // Mark this thread's unread replies as read before navigating
          await context
              .read<SupabaseChatRepository>()
              .markThreadUnreadAsRead(rootMessage.id);

          if (!context.mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => ThreadBloc(
                  repo: context.read<SupabaseChatRepository>(),
                )..add(InitThreadStream(
                    chatId: chatId,
                    parentMessageId: rootMessage.id,
                    partnerId: partnerId,
                  )),
                child: ThreadChatScreen(
                  parentMessageId: rootMessage.id,
                  chatId: chatId,
                  prescriptionUrl: imageUrl,
                  notes: notes.isNotEmpty ? notes : null,
                ),
              ),
            ),
          );

          // Re-mark as read on return (in case more came in)
          if (!context.mounted) return;
          context
              .read<SupabaseChatRepository>()
              .markThreadUnreadAsRead(rootMessage.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unreadCount > 0
                  ? AppColors.error
                  : AppColors.blue1.withValues(alpha: 0.6),
              width: unreadCount > 0 ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.medication_rounded,
                    color: AppColors.blue1,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes.isNotEmpty
                          ? notes
                          : '📷 Prescription Inquiry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.headingSemiBold.copyWith(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unread / reply badge
                  if (unreadCount > 0)
                    _Badge(
                      label:
                          '$unreadCount new ${unreadCount == 1 ? 'reply' : 'replies'}',
                      backgroundColor: AppColors.error,
                      showDot: true,
                    )
                  else if (replyCount > 0)
                    _Badge(
                      label:
                          '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                      backgroundColor:
                          AppColors.blue1.withValues(alpha: 0.2),
                      borderColor: AppColors.blue1.withValues(alpha: 0.5),
                      textColor: AppColors.blue1,
                    )
                  else
                    _Badge(
                      label: 'Thread',
                      backgroundColor: AppColors.blue3,
                      textColor: AppColors.blue1,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 60,
                      color: AppColors.blue3,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: const Row(
                        children: [
                          Icon(Icons.picture_as_pdf,
                              color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            'Prescription Document Attached',
                            style: TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const Divider(height: 1, color: AppColors.blue3),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 14,
                        color: AppColors.blue1,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to open prescription thread',
                        style: TextStyles.labelRegular.copyWith(
                          fontSize: 12,
                          color: AppColors.blue1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.blue1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final bool showDot;

  const _Badge({
    required this.label,
    required this.backgroundColor,
    this.borderColor,
    this.textColor = Colors.white,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyles.labelRegular.copyWith(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
