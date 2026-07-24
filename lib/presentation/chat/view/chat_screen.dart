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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
                          listener: (context, state) {
                            if (state is ChatLoaded) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToBottom(),
                              );
                            }
                          },
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
                                  .where((m) =>
                                      m.parentMessageId == null ||
                                      m.parentMessageId!.trim().isEmpty)
                                  .toList();

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

                                  return _PrescriptionInquiryCard(
                                    chatId: widget.chatId,
                                    rootMessageId: msg.id,
                                    requestDetails: requestDetails,
                                    patientName: patientName,
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;
    final bubbleColor = isMe ? AppColors.blue2 : AppColors.surface;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isMe
        ? const EdgeInsets.only(left: 48, bottom: 12)
        : const EdgeInsets.only(right: 48, bottom: 12);
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            margin: margin,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message.imageUrl!,
                      width: 200,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  message.content,
                  style: TextStyles.bodyRegular.copyWith(
                    color: Colors.white,
                    fontSize: 14,
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

class _PrescriptionInquiryCard extends StatelessWidget {
  final String chatId;
  final String rootMessageId;
  final RequestModel? requestDetails;
  final String patientName;

  const _PrescriptionInquiryCard({
    required this.chatId,
    required this.rootMessageId,
    this.requestDetails,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final hasAttachment = requestDetails?.attachments.isNotEmpty ?? false;
    final imageUrl = hasAttachment ? requestDetails!.attachments.first : null;
    final notes = requestDetails?.description;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ThreadChatScreen(
                parentMessageId: rootMessageId,
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
              color: AppColors.blue1.withValues(alpha: 0.6),
              width: 1.5,
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
                    Icons.receipt_long_rounded,
                    color: AppColors.blue1,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prescription Inquiry Card',
                      style: TextStyles.headingSemiBold.copyWith(
                        fontSize: 14,
                        color: AppColors.blue1,
                      ),
                    ),
                  ),
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
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 60,
                      color: AppColors.blue3,
                      child: const Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: AppColors.error,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                Text(
                  'Notes: "$notes"',
                  style: TextStyles.bodyRegular.copyWith(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
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
