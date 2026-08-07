import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/partner_type.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import '../../chat/bloc/thread_bloc.dart';
import '../../chat/bloc/thread_event.dart';
import '../../chat/view/thread_chat_screen.dart';

class NotificationOverlayWrapper extends StatelessWidget {
  final Widget child;
  const NotificationOverlayWrapper({super.key, required this.child});

  void _handleNotificationRedirection(
    BuildContext context,
    NotificationModel notification,
  ) {
    final authState = context.read<AuthBloc>().state;
    PartnerType? partnerRole;
    String partnerId = '';
    if (authState.status == AuthBlocStatus.authenticated &&
        authState.partner != null) {
      partnerRole = authState.partner!.role;
      partnerId = authState.partner!.id;
    }

    final metadata = notification.metadata ?? {};
    final String? chatId =
        metadata['chatId']?.toString() ?? metadata['chat_id']?.toString();
    final String? parentMessageId =
        metadata['parentMessageId']?.toString() ??
        metadata['parent_message_id']?.toString();
    final String? appointmentId =
        metadata['appointmentId']?.toString() ?? metadata['id']?.toString();

    // 1. Direct Chat & Thread Navigation
    if (chatId != null && chatId.isNotEmpty) {
      if (parentMessageId != null && parentMessageId.isNotEmpty) {
        // Open Root Chat Screen first
        context.push(AppRoutes.chat.replaceAll(':id', chatId));

        // Push specific Thread Screen
        final repo = context.read<SupabaseChatRepository>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => ThreadBloc(repo: repo)
                ..add(
                  InitThreadStream(
                    chatId: chatId,
                    parentMessageId: parentMessageId,
                    partnerId: partnerId,
                  ),
                ),
              child: ThreadChatScreen(
                parentMessageId: parentMessageId,
                chatId: chatId,
                notes: metadata['notes']?.toString() ?? notification.message,
                prescriptionUrl:
                    metadata['prescriptionUrl']?.toString() ??
                    metadata['imageUrl']?.toString(),
                patientName: notification.patient?.fullName,
              ),
            ),
          ),
        );
      } else {
        context.push(AppRoutes.chat.replaceAll(':id', chatId));
      }
      return;
    }

    // 2. Prescription Inquiry / Pharmacy Partner
    if (notification.type == NotificationType.prescriptionInquiry ||
        partnerRole == PartnerType.pharmacy) {
      context.go(AppRoutes.requestList);
      return;
    }

    // 3. Doctor/Lab/Imaging partner appointment requests/details
    if (appointmentId != null &&
        appointmentId.isNotEmpty &&
        appointmentId != notification.id) {
      context.push(AppRoutes.requestDetail.replaceAll(':id', appointmentId));
    } else {
      context.go(AppRoutes.requestList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state.status == NotificationStatus.opened &&
            state.notification != null) {
          _handleNotificationRedirection(context, state.notification!);
        }
      },
      child: child,
    );
  }
}

