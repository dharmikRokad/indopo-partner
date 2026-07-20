import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class ChatRequestState {
  final RequestModel? requestDetails;
  final bool isLoadingRequest;
  const ChatRequestState({this.requestDetails, this.isLoadingRequest = true});
}

class ChatScreen extends StatelessWidget {
  final String id;
  const ChatScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // 1. Guard check from AuthBloc
    final authState = context.read<AuthBloc>().state;
    bool isMedicalPartner = false;

    if (authState is AuthSuccess) {
      final role = authState.partner.role;
      isMedicalPartner =
          role == PartnerType.doctor || role == PartnerType.medical;
    }

    return BlocProvider(
      create: (context) => ChatBloc()..add(LoadChatHistory(id)),
      child: _ChatContent(requestId: id, isMedicalPartner: isMedicalPartner),
    );
  }
}

class _ChatContent extends StatefulWidget {
  final String requestId;
  final bool isMedicalPartner;

  const _ChatContent({required this.requestId, required this.isMedicalPartner});

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _requestCubit = ValueCubit<ChatRequestState>(const ChatRequestState());

  @override
  void initState() {
    super.initState();
    _fetchRequestInfo();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _requestCubit.close();
    super.dispose();
  }

  Future<void> _fetchRequestInfo() async {
    try {
      final repo = context.read<RequestRepository>();
      final req = await repo.fetchRequestById(widget.requestId);
      if (mounted) {
        _requestCubit.update(ChatRequestState(requestDetails: req, isLoadingRequest: false));
      }
    } catch (e) {
      if (mounted) {
        _requestCubit.update(ChatRequestState(requestDetails: _requestCubit.state.requestDetails, isLoadingRequest: false));
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatBloc>().add(SendMessage(content: text));
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _sendSimulatedImage() {
    context.read<ChatBloc>().add(
      const SendMessage(
        content: 'Sent an attachment',
        imageUrl:
            'https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=300&auto=format&fit=crop',
      ),
    );
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValueCubit<ChatRequestState>, ChatRequestState>(
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
                ? const Text('Loading chat...', style: TextStyle(fontSize: 16))
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.blue2,
                        child: Text(
                          requestDetails?.patientInitials ?? 'P',
                          style: TextStyles.headingBold.copyWith(fontSize: 13),
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
                                  'Online',
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
              // 1. Guard Banner for Non-Medical Partner types
              if (!widget.isMedicalPartner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

              // 2. Chat Messages list
              Expanded(
                child: widget.isMedicalPartner
                    ? BlocConsumer<ChatBloc, ChatState>(
                        listener: (context, state) {
                          if (state is ChatLoaded) {
                            // Scroll down slightly after load
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
                            return Center(child: Text('Error: ${state.message}'));
                          }
                          if (state is ChatLoaded) {
                            final messages = state.messages;
                            if (messages.isEmpty) {
                              return Center(
                                  child: Text(
                                    'Start of message history.',
                                    style: TextStyles.labelRegular,
                                  ),
                                );
                            }
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                return _MessageBubble(message: msg);
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

              // 3. Message Input Area (Disabled for non-medical)
              AbsorbPointer(
                absorbing: !widget.isMedicalPartner,
                child: Opacity(
                  opacity: widget.isMedicalPartner ? 1.0 : 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.blue3, width: 2),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          // Simulated image attachment selector
                          IconButton(
                            icon: const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: AppColors.blue1,
                            ),
                            onPressed: _sendSimulatedImage,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                fillColor: AppColors.blue3,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Send button
                          CircleAvatar(
                            backgroundColor: AppColors.blue1,
                            child: IconButton(
                              icon: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
                // Display attachment image if url exists
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
