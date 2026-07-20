import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/request_model.dart';
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
  final _notificationCubit = ValueCubit<RequestModel?>(null);

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

  void _showBanner(RequestModel request) {
    _notificationCubit.update(request);
    _controller.forward();

    // Automatically dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _notificationCubit.state?.id == request.id) {
        _controller.reverse().then((_) {
          if (mounted) {
            _notificationCubit.update(null);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationForegroundReceived) {
          _showBanner(state.request);
        } else if (state is NotificationOpened) {
          // Redirect the partner to appointments list
          context.go(AppRoutes.requestList);
        }
      },
      child: BlocBuilder<ValueCubit<RequestModel?>, RequestModel?>(
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

  Widget _buildBannerCard(BuildContext context, RequestModel request) {
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
          context.read<NotificationBloc>().add(NotificationTapped(request.id));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.blue2, // blue2 background
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
                      'New Request: ${request.patientName}',
                      style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.requestType} • ${request.description}',
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
