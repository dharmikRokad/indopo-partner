import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/bloc/value_cubit.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'thread_chat_screen.dart';

class ChatRequestState {
  final RequestModel? requestDetails;
  final bool isLoadingRequest;
  const ChatRequestState({this.requestDetails, this.isLoadingRequest = true});
}

class ChatScreen extends StatelessWidget {
  final String id;
  final String? appointmentId;

  const ChatScreen({super.key, required this.id, this.appointmentId});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    bool isMedicalPartner = false;
    String partnerId = '';

    if (authState is AuthSuccess) {
      partnerId = authState.partner.id;
      final role = authState.partner.role;
      isMedicalPartner =
          role == PartnerType.doctor || role == PartnerType.pharmacy;
    }

    final supabaseRepo = context.read<SupabaseChatRepository>();
    final targetAppointmentId = appointmentId ?? id;

    return BlocProvider(
      create: (context) => ChatBloc(supabaseChatRepository: supabaseRepo)
        ..add(
          InitChatStream(
            chatId: id,
            appointmentId: targetAppointmentId,
            partnerId: partnerId,
          ),
        ),
      child: _ChatContent(
        chatId: id,
        appointmentId: targetAppointmentId,
        isMedicalPartner: isMedicalPartner,
      ),
    );
  }
}

class _ChatContent extends StatefulWidget {
  final String chatId;
  final String appointmentId;
  final bool isMedicalPartner;

  const _ChatContent({
    required this.chatId,
    required this.appointmentId,
    required this.isMedicalPartner,
  });

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  late final ScrollController _scrollController;
  late final ValueCubit<ChatRequestState> _requestCubit;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _requestCubit = ValueCubit<ChatRequestState>(const ChatRequestState());
    _fetchRequestInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _requestCubit.close();
    super.dispose();
  }

  Future<void> _fetchRequestInfo() async {
    try {
      final repo = context.read<RequestRepository>();
      final req = await repo.fetchRequestById(widget.appointmentId);
      if (mounted) {
        _requestCubit.update(
          ChatRequestState(requestDetails: req, isLoadingRequest: false),
        );
      }
    } catch (e) {
      if (mounted) {
        _requestCubit.update(
          ChatRequestState(
            requestDetails: _requestCubit.state.requestDetails,
            isLoadingRequest: false,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _requestCubit,
      child: BlocBuilder<ValueCubit<ChatRequestState>, ChatRequestState>(
        bloc: _requestCubit,
        builder: (context, requestState) {
          final requestDetails = requestState.requestDetails;
          final isLoadingRequest = requestState.isLoadingRequest;
          final String patientName = requestDetails?.patientName ?? 'Patient';

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
              title: isLoadingRequest
                  ? const Text(
                      'Loading chat...',
                      style: TextStyle(fontSize: 16),
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.blue2,
                          child: Text(
                            requestDetails?.patientInitials ?? 'P',
                            style: TextStyles.headingBold.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: TextStyles.headingSemiBold.copyWith(
                                  fontSize: 16,
                                ),
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
                            'Access Restricted: Chat features are only available for Doctor and Medical partner profiles.',
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
                      ? BlocConsumer<ChatBloc, ChatState>(
                          listener: (context, state) {},
                          builder: (context, state) {
                            if (state is ChatLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.blue1,
                                ),
                              );
                            }
                            if (state is ChatFailure) {
                              return Center(
                                child: Text('Error: ${state.message}'),
                              );
                            }
                            if (state is ChatLoaded) {
                              final rootMessages = state.messages
                                  .where(
                                    (m) =>
                                        m.parentMessageId == null ||
                                        m.parentMessageId!.trim().isEmpty,
                                  )
                                  .toList();

                              rootMessages.sort((a, b) {
                                final aReplies = state.messages.where(
                                    (m) => m.id == a.id || m.parentMessageId == a.id);
                                DateTime aLatest = a.timestamp;
                                for (final m in aReplies) {
                                  if (m.timestamp.isAfter(aLatest)) {
                                    aLatest = m.timestamp;
                                  }
                                }

                                final bReplies = state.messages.where(
                                    (m) => m.id == b.id || m.parentMessageId == b.id);
                                DateTime bLatest = b.timestamp;
                                for (final m in bReplies) {
                                  if (m.timestamp.isAfter(bLatest)) {
                                    bLatest = m.timestamp;
                                  }
                                }

                                return bLatest.compareTo(aLatest);
                              });

                              if (rootMessages.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Start of real-time message stream.',
                                    style: TextStyles.labelRegular,
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: rootMessages.length,
                                itemBuilder: (context, index) {
                                  final msg = rootMessages[index];
                                  final replies = state.messages
                                      .where((m) => m.parentMessageId == msg.id)
                                      .toList();
                                  final replyCount = replies.length;
                                  final unreadCount = replies
                                      .where((m) =>
                                          m.senderRole.toLowerCase() ==
                                          'patient')
                                      .length;

                                  return _PrescriptionInquiryCard(
                                    chatId: widget.chatId,
                                    rootMessage: msg,
                                    requestDetails: requestDetails,
                                    patientName: patientName,
                                    replyCount: replyCount,
                                    unreadCount: unreadCount,
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
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrescriptionInquiryCard extends StatelessWidget {
  final String chatId;
  final ChatMessage rootMessage;
  final RequestModel? requestDetails;
  final String patientName;
  final int replyCount;
  final int unreadCount;

  const _PrescriptionInquiryCard({
    required this.chatId,
    required this.rootMessage,
    this.requestDetails,
    required this.patientName,
    this.replyCount = 0,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl =
        (rootMessage.imageUrl != null && rootMessage.imageUrl!.isNotEmpty)
            ? rootMessage.imageUrl
            : (requestDetails?.attachments.isNotEmpty == true
                ? requestDetails!.attachments.first
                : null);

    final String notes = (rootMessage.content.isNotEmpty &&
            rootMessage.content != '📷 Prescription Inquiry')
        ? rootMessage.content
        : (requestDetails?.description ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ThreadChatScreen(
                parentMessageId: rootMessage.id,
                chatId: chatId,
                prescriptionUrl: imageUrl,
                notes: notes,
                patientName: patientName,
              ),
            ),
          );
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
                          : '$patientName\'s Prescription Request',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.headingSemiBold.copyWith(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$unreadCount new ${unreadCount == 1 ? 'reply' : 'replies'}',
                            style: TextStyles.labelRegular.copyWith(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (replyCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.blue1.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                        style: TextStyles.labelRegular.copyWith(
                          fontSize: 11,
                          color: AppColors.blue1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue3,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Thread',
                        style: TextStyles.labelRegular.copyWith(
                          fontSize: 11,
                          color: AppColors.blue1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            'Prescription Document Attached',
                            style: TextStyle(color: Colors.white, fontSize: 13),
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
