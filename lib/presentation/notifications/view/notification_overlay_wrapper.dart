import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/partner_type.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../bloc/notification_event.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class NotificationOverlayWrapper extends StatefulWidget {
  final Widget child;
  const NotificationOverlayWrapper({super.key, required this.child});

  @override
  State<NotificationOverlayWrapper> createState() =>
      _NotificationOverlayWrapperState();
}

class _NotificationOverlayWrapperState extends State<NotificationOverlayWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  final _notificationCubit = ValueCubit<NotificationModel?>(null);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(
      begin: -120.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    _notificationCubit.close();
    super.dispose();
  }

  void _showBanner(NotificationModel notification) {
    _notificationCubit.update(notification);
    _controller.forward();

    // Automatically dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _notificationCubit.state?.id == notification.id) {
        _controller.reverse().then((_) {
          if (mounted) {
            _notificationCubit.update(null);
          }
        });
      }
    });
  }

  void _handleNotificationRedirection(NotificationModel notification) {
    final authState = context.read<AuthBloc>().state;
    PartnerType? partnerRole;
    if (authState is AuthSuccess) {
      partnerRole = authState.partner.role;
    }

    final metadata = notification.metadata ?? {};
    final appointmentId = metadata['appointmentId']?.toString() ?? metadata['id']?.toString();

    // Check notification type and partner role for appropriate page redirection
    if (notification.type == NotificationType.prescriptionInquiry ||
        partnerRole == PartnerType.medical) {
      // Redirect medical/pharmacy partner to prescriptions page
      context.go(AppRoutes.requestList);
    } else {
      // Redirect doctor/lab/imaging partner to appointment requests/details
      if (appointmentId != null &&
          appointmentId.isNotEmpty &&
          appointmentId != notification.id) {
        context.push(
          AppRoutes.requestDetail.replaceAll(':id', appointmentId),
        );
      } else {
        context.go(AppRoutes.requestList);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationForegroundReceived) {
          _showBanner(state.notification);
        } else if (state is NotificationOpened) {
          _handleNotificationRedirection(state.notification);
        }
      },
      child: BlocBuilder<ValueCubit<NotificationModel?>, NotificationModel?>(
        bloc: _notificationCubit,
        builder: (context, activeNotification) {
          return Stack(
            children: [
              widget.child,
              if (activeNotification != null)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Positioned(
                      top: _slideAnimation.value,
                      left: 16,
                      right: 16,
                      child: SafeArea(
                        child: _buildBannerCard(context, activeNotification),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, NotificationModel notification) {
    final title = notification.patient?.fullName.isNotEmpty == true
        ? 'Notification: ${notification.patient!.fullName}'
        : 'New Notification';

    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          _controller.reverse().then((_) {
            if (mounted) {
              _notificationCubit.update(null);
            }
          });
          context.read<NotificationBloc>().add(NotificationTapped(notification));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.blue2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.blue1, width: 1.5),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.blue3,
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.blue1,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: TextStyles.bodyRegular.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
