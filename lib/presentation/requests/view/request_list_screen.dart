import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:indopo_partner/data/models/partner_type.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/presentation/widgets/logout_confirmation_dialog.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/request_list_bloc.dart';
import '../bloc/request_list_event.dart';
import '../bloc/request_list_state.dart';

class RequestListScreen extends StatelessWidget {
  const RequestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RequestListBloc(requestRepository: context.read<RequestRepository>()),
      child: const _RequestListContent(),
    );
  }
}

class _RequestListContent extends StatefulWidget {
  const _RequestListContent();

  @override
  State<_RequestListContent> createState() => _RequestListContentState();
}

class _RequestListContentState extends State<_RequestListContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<RequestStatus> _activeTabs;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    bool isMedical = false;
    if (authState is AuthSuccess) {
      isMedical = authState.partner.role == PartnerType.pharmacy;
    }
    _activeTabs = isMedical
        ? [
            RequestStatus.newRequest,
            RequestStatus.inProgress,
            RequestStatus.cancelled,
          ]
        : [
            RequestStatus.newRequest,
            RequestStatus.inProgress,
            RequestStatus.completed,
            RequestStatus.cancelled,
          ];

    _tabController = TabController(length: _activeTabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initial fetch of 'New' requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestListBloc>().add(
        const FetchRequests(RequestStatus.newRequest),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;

    final bloc = context.read<RequestListBloc>();
    final status = _activeTabs[_tabController.index];
    bloc.add(FetchRequests(status));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String partnerName = 'Partner';
    String roleBadge = '🩺 Doctor';
    bool isAvailable = false;

    if (authState is AuthSuccess) {
      final p = authState.partner;
      partnerName =
          p.details['full_name'] ??
          p.details['lab_name'] ??
          p.details['center_name'] ??
          p.email;
      roleBadge = '${p.role.icon} ${p.role.displayName}';
      isAvailable = p.isAvailable;
    }

    return BlocBuilder<RequestListBloc, RequestListState>(
      builder: (context, state) {
        bool hasUnreadDot = false;
        if (state is RequestListLoaded) {
          hasUnreadDot = state.hasUnreadNew;
        }

        return Scaffold(
          backgroundColor: AppColors.blue3,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
                ),
                Text(
                  roleBadge,
                  style: TextStyles.labelRegular.copyWith(
                    fontSize: 12,
                    color: AppColors.blue1,
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Text(
                    isAvailable ? 'Active' : 'Away',
                    style: TextStyles.labelRegular.copyWith(
                      fontSize: 12,
                      color: isAvailable ? Colors.green : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: isAvailable,
                    activeThumbColor: Colors.green,
                    activeTrackColor: Colors.green.withValues(alpha: 0.3),
                    inactiveThumbColor: AppColors.textMuted,
                    inactiveTrackColor: AppColors.surface,
                    onChanged: (val) {
                      context.read<AuthBloc>().add(AvailabilityToggled(val));
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                onPressed: () async {
                  final shouldLogout = await LogoutConfirmationDialog.show(
                    context,
                  );
                  if (shouldLogout == true && context.mounted) {
                    context.read<AuthBloc>().add(LogoutRequested());
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.blue1,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: TextStyles.headingSemiBold.copyWith(fontSize: 13),
              tabs: _activeTabs.map((status) {
                if (status == RequestStatus.newRequest) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('New'),
                        if (hasUnreadDot) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return Tab(text: status.displayName);
              }).toList(),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: _activeTabs.map((status) {
              return _buildTabList(status, state);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTabList(RequestStatus status, RequestListState state) {
    if (state is RequestListLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue1),
      );
    }

    if (state is RequestListFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('Error loading requests', style: TextStyles.headingSemiBold),
            const SizedBox(height: 4),
            Text(state.message, style: TextStyles.labelRegular),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<RequestListBloc>().add(FetchRequests(status));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is RequestListLoaded) {
      // Safety check to ensure we only render items for this tab's requested status
      if (state.status != status) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.blue1),
        );
      }

      final requests = state.requests;

      if (requests.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<RequestListBloc>().add(FetchRequests(status));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              _buildEmptyState(status),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<RequestListBloc>().add(FetchRequests(status));
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _RequestCard(
              request: req,
              onTap: () async {
                await context.push(
                  AppRoutes.requestDetail.replaceAll(':id', req.id),
                  extra: req,
                );
                if (context.mounted) {
                  context.read<RequestListBloc>().add(FetchRequests(status));
                }
              },
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(RequestStatus status) {
    String message = 'No new requests yet';
    String sub = 'New customer requests will show up here.';
    IconData icon = Icons.mark_email_read_outlined;
    Color color = AppColors.info;

    if (status == RequestStatus.inProgress) {
      message = 'No active schedule';
      sub = 'Confirm a request to schedule an appointment.';
      icon = Icons.hourglass_empty_rounded;
      color = AppColors.warning;
    } else if (status == RequestStatus.completed) {
      message = 'No completed appointments';
      sub = 'Your resolved appointments will be archived here.';
      icon = Icons.done_all_rounded;
      color = AppColors.success;
    } else if (status == RequestStatus.cancelled) {
      message = 'No cancelled appointments';
      sub = 'Your cancelled booking requests will show up here.';
      icon = Icons.cancel_outlined;
      color = AppColors.error;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              sub,
              style: TextStyles.labelRegular,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = AppColors.info;
    String statusLabel = 'New';

    if (request.status == RequestStatus.inProgress) {
      badgeColor = AppColors.warning;
      statusLabel = 'Confirmed';
    } else if (request.status == RequestStatus.completed) {
      badgeColor = AppColors.success;
      statusLabel = 'Completed';
    } else if (request.status == RequestStatus.cancelled) {
      badgeColor = AppColors.error;
      statusLabel = 'Cancelled';
    }

    // Format timestamp
    final String timeStr = _formatTimestamp(request.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Initials
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.blue2,
                    child: Text(
                      request.patientInitials,
                      style: TextStyles.headingBold.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Patient & Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.patientName,
                          style: TextStyles.headingSemiBold.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: TextStyles.labelRegular.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyles.bodyMedium.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                request.description,
                style: TextStyles.bodyRegular.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
