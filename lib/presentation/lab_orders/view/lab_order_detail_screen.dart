import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../data/models/lab_order_model.dart';
import '../bloc/lab_order_bloc.dart';
import '../bloc/lab_order_event.dart';
import '../bloc/lab_order_state.dart';

class LabOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final LabDispatchModel? dispatch;

  const LabOrderDetailScreen({
    super.key,
    required this.orderId,
    this.dispatch,
  });

  Future<void> _shareReportViaWhatsApp(
    BuildContext context,
    LabOrderModel order,
  ) async {
    final rawPhone = order.patientPhone.isNotEmpty
        ? order.patientPhone
        : (order.patient?.phone ?? '');
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.isEmpty) {
      AppSnackBar.showWarning(
        context,
        'Patient phone number is not available for WhatsApp.',
      );
      return;
    }

    final messageText =
        'Hello ${order.patientName},\n\n'
        'Here is your diagnostic lab report for Order #${order.id} (${order.itemsSummary}).\n\n'
        'Thank you for choosing our laboratory services!';

    final encodedMessage = Uri.encodeComponent(messageText);
    final whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppSnackBar.showError(
          context,
          'Could not open WhatsApp. Please ensure WhatsApp is installed.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Failed to launch WhatsApp: $e');
      }
    }
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
        // Find dispatch matching orderId
        LabDispatchModel? activeDispatch = dispatch;
        if (activeDispatch == null) {
          final matches = state.dispatches.where((d) => d.order.id == orderId);
          if (matches.isNotEmpty) {
            activeDispatch = matches.first;
          }
        }

        if (activeDispatch == null && state.status == LabOrderBlocStatus.loading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Order Details'),
              backgroundColor: AppColors.background,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (activeDispatch == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Order Details'),
              backgroundColor: AppColors.background,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Order #$orderId not found',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<LabOrderBloc>().add(
                            const FetchLabOrders(isRefresh: true),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                    ),
                    child: const Text('Refresh Orders'),
                  ),
                ],
              ),
            ),
          );
        }

        final order = activeDispatch.order;
        final isPendingWindow = activeDispatch.isWindowActive;
        final isAccepted = activeDispatch.dispatchStatus == LabDispatchStatus.accepted ||
            order.status == LabOrderStatus.accepted;
        final isAccepting = state.acceptingOrderId == order.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lab Order Details',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${order.id}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Status & Timer Banner
                      _LabOrderBanner(dispatch: activeDispatch),

                      const SizedBox(height: 16),

                      // 2. Patient Details Card
                      _buildPatientCard(order, isAccepted: isAccepted, context: context),

                      const SizedBox(height: 16),

                      // 3. Package Items & Tests Breakdown
                      const Text(
                        'Ordered Packages & Tests',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...order.items.map((item) => _buildItemCard(item)),

                      const SizedBox(height: 16),

                      // 4. Financial Summary Card
                      _buildFinancialSummary(order),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar for active pending orders
              if (isPendingWindow)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isAccepting
                            ? null
                            : () {
                                context.read<LabOrderBloc>().add(
                                      AcceptLabOrderEvent(order.id),
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isAccepting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Accept Order',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                )
              else if (isAccepted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _shareReportViaWhatsApp(context, order),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                        label: const Text(
                          'Share Report via WhatsApp',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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

  Widget _buildPatientCard(
    LabOrderModel order, {
    bool isAccepted = false,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.blue1.withValues(alpha: 0.2),
                child: Text(
                  order.patientName.isNotEmpty
                      ? order.patientName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.patientName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.patientPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            order.patientPhone,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          if (isAccepted) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _shareReportViaWhatsApp(context, order),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 12,
                                      color: Color(0xFF25D366),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'WhatsApp',
                                      style: TextStyle(
                                        color: Color(0xFF25D366),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (order.patientLat != null && order.patientLong != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.background, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.blue1,
                ),
                const SizedBox(width: 6),
                Text(
                  'Location: (${order.patientLat!.toStringAsFixed(4)}, ${order.patientLong!.toStringAsFixed(4)})',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(LabOrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.packageName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Qty: ${item.quantity}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (item.labPackage?.category != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.labPackage!.category!,
                style: const TextStyle(
                  color: AppColors.blue1,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (item.labPackage?.tests.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            const Text(
              'Included Diagnostic Tests:',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.labPackage!.tests.map((testName) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 12,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        testName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price: ₹${item.price.toStringAsFixed(2)} x ${item.quantity}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                '₹${item.itemTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(LabOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Package Items',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              Text(
                '${order.items.length}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: AppColors.background),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable Amount',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabOrderBanner extends StatefulWidget {
  final LabDispatchModel dispatch;

  const _LabOrderBanner({required this.dispatch});

  @override
  State<_LabOrderBanner> createState() => _LabOrderBannerState();
}

class _LabOrderBannerState extends State<_LabOrderBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _LabOrderBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dispatch.dispatchId != widget.dispatch.dispatchId ||
        oldWidget.dispatch.notifiedAt != widget.dispatch.notifiedAt) {
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (widget.dispatch.isWindowActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {});
        if (!widget.dispatch.isWindowActive) {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dispatch = widget.dispatch;
    if (dispatch.dispatchStatus == LabDispatchStatus.accepted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.green),
            SizedBox(width: 10),
            Text(
              'Order Accepted by your laboratory!',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final isPendingWindow = dispatch.isWindowActive;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPendingWindow
            ? AppColors.amber.withValues(alpha: 0.15)
            : AppColors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPendingWindow
              ? AppColors.amber.withValues(alpha: 0.3)
              : AppColors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPendingWindow ? Icons.timer_rounded : Icons.timer_off_rounded,
            color: isPendingWindow ? AppColors.amber : AppColors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPendingWindow
                      ? '5-Minute Acceptance Window Active'
                      : 'Acceptance Window Expired',
                  style: TextStyle(
                    color: isPendingWindow ? AppColors.amber : AppColors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPendingWindow
                      ? 'Respond before window expires to fulfill this order.'
                      : 'This order has moved to another lab or expired.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isPendingWindow)
            Text(
              dispatch.formattedRemainingTime,
              style: const TextStyle(
                color: AppColors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}
