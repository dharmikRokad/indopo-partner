import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_room_model.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/chat_list_bloc.dart';
import '../bloc/chat_list_event.dart';
import '../bloc/chat_list_state.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final String partnerId =
        authState.status == AuthBlocStatus.authenticated &&
            authState.partner != null
        ? authState.partner!.id
        : '';

    return BlocProvider(
      create: (_) =>
          ChatListBloc(repo: context.read<SupabaseChatRepository>())
            ..add(InitChatListStream(partnerId: partnerId)),
      child: const _ChatsListContent(),
    );
  }
}

class _ChatsListContent extends StatelessWidget {
  const _ChatsListContent();

  Future<void> _onRefresh(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    final String partnerId =
        authState.status == AuthBlocStatus.authenticated &&
            authState.partner != null
        ? authState.partner!.id
        : '';
    context.read<ChatListBloc>().add(InitChatListStream(partnerId: partnerId));
    // Small delay so the pull-to-refresh indicator resolves gracefully
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue3,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Active Chats',
          style: TextStyles.headingSemiBold.copyWith(fontSize: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        color: AppColors.blue1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BlocBuilder<ChatListBloc, ChatListState>(
            builder: (context, state) {
              if (state.status == ChatListStatus.loading ||
                  state.status == ChatListStatus.initial) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.blue1),
                );
              }

              if (state.status == ChatListStatus.error) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                    Center(
                      child: Text(
                        'Failed to load chats. Pull to refresh.',
                        style: TextStyles.bodyRegular.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }

              if (state.status == ChatListStatus.loaded) {
                return _buildList(context, state.chats);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ChatRoomModel> chats) {
    if (chats.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active chats',
                  style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'When prescription inquiries are initialised, real-time chats appear here.',
                  style: TextStyles.bodyRegular.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final room = chats[index];
        return _ChatListTile(room: room);
      },
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final ChatRoomModel room;

  const _ChatListTile({required this.room});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = room.partnerUnreadCount > 0;
    final String timeStr = _formatTime(room.lastMessageTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          // Reset unread count immediately then navigate
          context.read<SupabaseChatRepository>().markPartnerChatsUnreadAsRead(
            room.id,
          );
          await GoRouter.of(context).push(
            '${AppRoutes.chat.replaceAll(':id', room.id)}?patientId=${room.patientId}&patientName=${Uri.encodeComponent(room.patientName)}',
          );
          // Stream update will automatically reflect the reset count
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread
                  ? AppColors.blue1
                  : AppColors.blue2.withValues(alpha: 0.5),
              width: hasUnread ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              room.patientPhotoUrl != null && room.patientPhotoUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(room.patientPhotoUrl!),
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.blue2,
                      child: Text(
                        room.patientInitials,
                        style: TextStyles.headingBold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            room.patientName,
                            style: TextStyles.headingSemiBold.copyWith(
                              fontSize: 16,
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: TextStyles.labelRegular.copyWith(
                              fontSize: 11,
                              color: hasUnread
                                  ? AppColors.blue1
                                  : AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.lastMessage ?? 'No messages yet',
                            style: TextStyles.labelRegular.copyWith(
                              fontSize: 13,
                              color: hasUnread
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.blue1,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${room.partnerUnreadCount}',
                              style: TextStyles.labelRegular.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
