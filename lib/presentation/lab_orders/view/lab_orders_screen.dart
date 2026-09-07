import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../data/models/lab_order_model.dart';
import '../../../data/repositories/lab_order_repository.dart';
import '../../../core/presentation/widgets/logout_confirmation_dialog.dart';
import '../../../core/theme/text_styles.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/lab_order_bloc.dart';
import '../bloc/lab_order_event.dart';
import '../bloc/lab_order_state.dart';
import '../widgets/lab_order_card.dart';
import 'lab_order_detail_screen.dart';

class LabOrdersScreen extends StatelessWidget {
  const LabOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LabOrderBloc>(
      create: (context) => LabOrderBloc(
        repository: context.read<LabOrderRepository>(),
      )..add(const FetchLabOrders()),
      child: const _LabOrdersView(),
    );
  }
}

class _LabOrdersView extends StatefulWidget {
  const _LabOrdersView();

  @override
  State<_LabOrdersView> createState() => _LabOrdersViewState();
}

class _LabOrdersViewState extends State<_LabOrdersView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDetailScreen(BuildContext context, LabDispatchModel dispatch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<LabOrderBloc>(),
          child: LabOrderDetailScreen(
            orderId: dispatch.order.id,
            dispatch: dispatch,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LabOrderBloc, LabOrderState>(
      listener: (context, state) {
        if (state.actionSuccessMessage != null) {
          AppSnackBar.showSuccess(context, state.actionSuccessMessage!);
        }
        if (state.errorMessage != null) {
          AppSnackBar.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final pendingCount = state.pendingDispatches.length;
        final authState = context.watch<AuthBloc>().state;
        final partner = authState.partner;
        final isAvailable = partner?.isAvailable ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: const Text(
              'Lab Orders',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (authState.status == AuthBlocStatus.authenticated && partner != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Row(
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
                ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                ),
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
              indicatorColor: AppColors.blue1,
              labelColor: AppColors.blue1,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pending'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Accepted'),
                const Tab(text: 'History'),
              ],
            ),
          ),
          body: state.status == LabOrderBlocStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Pending Orders
                    _buildOrdersList(
                      context,
                      dispatches: state.pendingDispatches,
                      emptyMessage: 'No pending lab orders right now',
                      emptySubtitle:
                          'New lab requests will appear here with a 5-minute window.',
                      acceptingOrderId: state.acceptingOrderId,
                    ),

                    // Tab 2: Accepted Orders
                    _buildOrdersList(
                      context,
                      dispatches: state.acceptedDispatches,
                      emptyMessage: 'No accepted lab orders yet',
                      emptySubtitle:
                          'Orders accepted by your lab will be listed here.',
                      acceptingOrderId: state.acceptingOrderId,
                    ),

                    // Tab 3: History Orders
                    _buildOrdersList(
                      context,
                      dispatches: state.historyDispatches,
                      emptyMessage: 'No order history',
                      emptySubtitle:
                          'Past timed out, skipped, or cancelled orders will appear here.',
                      acceptingOrderId: state.acceptingOrderId,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildOrdersList(
    BuildContext context, {
    required List<LabDispatchModel> dispatches,
    required String emptyMessage,
    required String emptySubtitle,
    String? acceptingOrderId,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<LabOrderBloc>().add(
              const FetchLabOrders(isRefresh: true),
            );
      },
      child: dispatches.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            emptySubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: dispatches.length,
              itemBuilder: (context, index) {
                final dispatch = dispatches[index];
                return LabOrderCard(
                  dispatch: dispatch,
                  isAccepting: acceptingOrderId == dispatch.order.id,
                  onTap: () => _openDetailScreen(context, dispatch),
                  onAccept: () {
                    context.read<LabOrderBloc>().add(
                          AcceptLabOrderEvent(dispatch.order.id),
                        );
                  },
                );
              },
            ),
    );
  }
}
