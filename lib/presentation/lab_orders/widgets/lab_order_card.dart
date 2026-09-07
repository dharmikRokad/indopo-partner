import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/lab_order_model.dart';

class LabOrderCard extends StatefulWidget {
  final LabDispatchModel dispatch;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isAccepting;

  const LabOrderCard({
    super.key,
    required this.dispatch,
    required this.onTap,
    this.onAccept,
    this.onReject,
    this.isAccepting = false,
  });

  @override
  State<LabOrderCard> createState() => _LabOrderCardState();
}

class _LabOrderCardState extends State<LabOrderCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LabOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dispatch.dispatchId != widget.dispatch.dispatchId ||
        oldWidget.dispatch.notifiedAt != widget.dispatch.notifiedAt ||
        oldWidget.dispatch.dispatchStatus != widget.dispatch.dispatchStatus) {
      _startTickerIfNeeded();
    }
  }

  void _startTickerIfNeeded() {
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
    final order = dispatch.order;
    final isPendingWindow = dispatch.isWindowActive;
    final onTap = widget.onTap;
    final onAccept = widget.onAccept;
    final onReject = widget.onReject;
    final isAccepting = widget.isAccepting;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPendingWindow
              ? AppColors.amber.withValues(alpha: 0.6)
              : AppColors.surface.withValues(alpha: 0.5),
          width: isPendingWindow ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Patient Name & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.blue1.withValues(alpha: 0.15),
                    child: Text(
                      order.patientName.isNotEmpty
                          ? order.patientName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: AppColors.blue1,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.patientPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.patientPhone,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(dispatch),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.surface, height: 1),
              const SizedBox(height: 12),

              // Summary: Package Items & Total
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.science_outlined,
                    size: 18,
                    color: AppColors.blue1,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.itemsSummary,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (order.allTests.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: order.allTests.take(4).map((test) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.surface,
                                  ),
                                ),
                                child: Text(
                                  test,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Timer Ticker Banner for NOTIFIED / Active Window
              if (dispatch.dispatchStatus == LabDispatchStatus.notified &&
                  order.status == LabOrderStatus.pending) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPendingWindow
                        ? AppColors.amber.withValues(alpha: 0.1)
                        : AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPendingWindow
                          ? AppColors.amber.withValues(alpha: 0.3)
                          : AppColors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: isPendingWindow
                            ? AppColors.amber
                            : AppColors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPendingWindow
                            ? 'Acceptance Window: '
                            : 'Acceptance Window: Expired',
                        style: TextStyle(
                          color: isPendingWindow
                              ? AppColors.amber
                              : AppColors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (isPendingWindow)
                        Text(
                          dispatch.formattedRemainingTime,
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Action Buttons (Accept / Reject)
              if (isPendingWindow) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(color: AppColors.surface),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Reject / Pass'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAccepting ? null : onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: isAccepting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Accept Order',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LabDispatchModel dispatch) {
    Color bg;
    Color fg;
    String label;

    if (dispatch.order.status == LabOrderStatus.expired) {
      bg = AppColors.red.withValues(alpha: 0.15);
      fg = AppColors.red;
      label = 'EXPIRED';
    } else {
      switch (dispatch.dispatchStatus) {
        case LabDispatchStatus.accepted:
          bg = AppColors.green.withValues(alpha: 0.15);
          fg = AppColors.green;
          label = 'ACCEPTED';
          break;
        case LabDispatchStatus.notified:
          if (dispatch.isWindowActive) {
            bg = AppColors.amber.withValues(alpha: 0.15);
            fg = AppColors.amber;
            label = 'NOTIFIED';
          } else {
            bg = AppColors.red.withValues(alpha: 0.15);
            fg = AppColors.red;
            label = 'EXPIRED';
          }
          break;
        case LabDispatchStatus.timedOut:
          bg = AppColors.red.withValues(alpha: 0.15);
          fg = AppColors.red;
          label = 'EXPIRED';
          break;
        case LabDispatchStatus.skipped:
          bg = AppColors.textMuted.withValues(alpha: 0.15);
          fg = AppColors.textMuted;
          label = 'SKIPPED';
          break;
        case LabDispatchStatus.pending:
          bg = AppColors.blue1.withValues(alpha: 0.15);
          fg = AppColors.blue1;
          label = 'QUEUED';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
