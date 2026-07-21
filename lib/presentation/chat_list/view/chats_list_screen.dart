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

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String partnerId = '';
    if (authState is AuthSuccess) {
      partnerId = authState.partner.id;
    }

    final supabaseRepo = context.read<SupabaseChatRepository>();

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
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: supabaseRepo.streamPartnerChats(partnerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue1),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to stream active chats', style: TextStyles.headingSemiBold),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyles.bodyRegular.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];
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
                        'When prescription appointments are confirmed, real-time chats appear here.',
                        style: TextStyles.bodyRegular.copyWith(color: AppColors.textMuted),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final room = chats[index];
              final hasUnread = room.partnerUnreadCount > 0;
              final String timeStr = room.lastMessageTime != null
                  ? '${room.lastMessageTime!.hour.toString().padLeft(2, '0')}:${room.lastMessageTime!.minute.toString().padLeft(2, '0')}'
                  : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.push(AppRoutes.chat.replaceAll(':id', room.id)),
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
                        // Opposite user (patient) photo or initial letter
                        if (room.patientPhotoUrl != null && room.patientPhotoUrl!.isNotEmpty)
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(room.patientPhotoUrl!),
                          )
                        else
                          CircleAvatar(
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
                                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
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
                                        color: hasUnread ? AppColors.blue1 : AppColors.textMuted,
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
                                        color: hasUnread ? Colors.white : AppColors.textMuted,
                                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
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
            },
          );
        },
      ),
    );
  }
}
