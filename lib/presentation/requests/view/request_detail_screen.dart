import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/request_detail_bloc.dart';
import '../bloc/request_detail_event.dart';
import '../bloc/request_detail_state.dart';
import '../widgets/assign_appointment_dialog.dart';

class RequestDetailScreen extends StatelessWidget {
  final String id;
  final RequestModel? request;

  const RequestDetailScreen({super.key, required this.id, this.request});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = RequestDetailBloc(
          requestRepository: context.read<RequestRepository>(),
          request: request,
        );
        if (request == null) {
          bloc.add(FetchRequestDetail(id));
        }
        return bloc;
      },
      child: _RequestDetailContent(id: id),
    );
  }
}

class _RequestDetailContent extends StatefulWidget {
  final String id;
  const _RequestDetailContent({required this.id});

  @override
  State<_RequestDetailContent> createState() => _RequestDetailContentState();
}

class _RequestDetailContentState extends State<_RequestDetailContent> {
  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    PartnerType partnerRole = PartnerType.doctor;
    if (authState is AuthSuccess) {
      partnerRole = authState.partner.role;
    }

    return Scaffold(
      backgroundColor: AppColors.blue3,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Request Details', style: TextStyles.headingSemiBold),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<RequestDetailBloc, RequestDetailState>(
        listener: (context, state) {
          if (state is RequestActionSuccess) {
            if (state.actionType == 'reject') {
              AppSnackBar.showSuccess(
                context,
                'Request cancelled successfully',
              );
              context.pop(); // Go back to request list
            } else if (state.actionType == 'complete') {
              AppSnackBar.showSuccess(
                context,
                'Appointment completed successfully',
              );
              context.pop(); // Go back to request list
            } else if (state.actionType == 'accept') {
              AppSnackBar.showSuccess(
                context,
                'Appointment confirmed successfully',
              );
              context.replace(AppRoutes.chat.replaceAll(':id', widget.id));
            }
          } else if (state is RequestDetailFailure) {
            AppSnackBar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is RequestDetailLoading || state is RequestDetailInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue1),
            );
          }

          if (state is RequestDetailFailure && state is! RequestDetailLoaded) {
            return Center(
              child: Text(
                'Failed to load request: ${state.message}',
                style: TextStyles.bodyRegular,
              ),
            );
          }

          RequestModel? request;
          if (state is RequestDetailLoaded) {
            request = state.request;
          } else if (state is RequestActionSuccess) {
            request = state.request;
          }

          if (request == null) {
            return const Center(child: Text('No request details found'));
          }
          final req = request;

          final String timeStr =
              '${req.timestamp.day}/${req.timestamp.month}/${req.timestamp.year} at ${req.timestamp.hour.toString().padLeft(2, '0')}:${req.timestamp.minute.toString().padLeft(2, '0')}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Header Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.blue2,
                            child: Text(
                              req.patientInitials,
                              style: TextStyles.headingBold.copyWith(
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.patientName,
                                  style: TextStyles.headingBold.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${req.patientAge} years • ${req.patientGender}',
                                  style: TextStyles.labelRegular.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 36,
                        color: AppColors.surface,
                        thickness: 1.5,
                      ),

                      // Contact Details
                      Text(
                        'Contact Info',
                        style: TextStyles.headingSemiBold.copyWith(
                          fontSize: 14,
                          color: AppColors.blue1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        req.patientContact,
                        style: TextStyles.bodyRegular.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Description',
                        style: TextStyles.headingSemiBold.copyWith(
                          fontSize: 14,
                          color: AppColors.blue1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        req.description,
                        style: TextStyles.bodyRegular.copyWith(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Attachments
                      Text(
                        'Attachments / Reports',
                        style: TextStyles.headingSemiBold.copyWith(
                          fontSize: 14,
                          color: AppColors.blue1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (req.attachments.isEmpty)
                        Text(
                          'No attachments available.',
                          style: TextStyles.labelRegular.copyWith(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        ...req.attachments.map(
                          (url) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: AppColors.surface,
                            child: ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: AppColors.error,
                              ),
                              title: Text(
                                url.split('/').last,
                                style: TextStyles.bodyRegular,
                              ),
                              trailing: const Icon(
                                Icons.download,
                                color: AppColors.blue1,
                              ),
                              onTap: () {
                                AppSnackBar.showInfo(
                                  context,
                                  'Simulated download: ${url.split('/').last}',
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Request ID & Timestamp info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request ID',
                                style: TextStyles.labelRegular.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    req.id.length > 12
                                        ? '${req.id.substring(0, 6)}...${req.id.substring(req.id.length - 6)}'
                                        : req.id,
                                    style: TextStyles.bodyMedium.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: req.id),
                                      );
                                      AppSnackBar.showSuccess(
                                        context,
                                        'Request ID copied to clipboard',
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2.0),
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 14,
                                        color: AppColors.blue1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Received At',
                                style: TextStyles.labelRegular.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: TextStyles.bodyMedium.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              if (request.status == RequestStatus.newRequest)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectBottomSheet(
                              context,
                              isPending: true,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyles.headingSemiBold.copyWith(
                                color: AppColors.error,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Confirm Button
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [AppColors.blue1, AppColors.blue2],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (partnerRole == PartnerType.medical) {
                                  context.read<RequestDetailBloc>().add(
                                    AcceptRequest(widget.id),
                                  );
                                } else {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (modalContext) =>
                                        AssignAppointmentDialog(
                                          requestId: widget.id,
                                          onConfirmed: () {
                                            context
                                                .pop(); // Close detail screen after appointment scheduled
                                          },
                                        ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Confirm',
                                style: TextStyles.headingBold.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (request.status == RequestStatus.inProgress)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectBottomSheet(
                              context,
                              isPending: false,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyles.headingSemiBold.copyWith(
                                color: AppColors.error,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Complete / Open Chat Button
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [AppColors.blue1, AppColors.blue2],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (partnerRole == PartnerType.medical) {
                                  context.push(
                                    AppRoutes.chat.replaceAll(':id', widget.id),
                                  );
                                } else {
                                  context.read<RequestDetailBloc>().add(
                                    CompleteRequest(widget.id),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                partnerRole == PartnerType.medical
                                    ? 'Open Chat'
                                    : 'Complete',
                                style: TextStyles.headingBold.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showRejectBottomSheet(
    BuildContext parentContext, {
    required bool isPending,
  }) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: AppColors.blue3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 24.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isPending ? 'Cancel Request' : 'Cancel Appointment',
              style: TextStyles.headingSemiBold.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Please provide a brief reason for cancelling this request.'
                  : 'Please provide a brief reason for cancelling this appointment.',
              style: TextStyles.labelRegular,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter reason (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.error,
              ),
              child: ElevatedButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  parentContext.read<RequestDetailBloc>().add(
                    RejectRequest(
                      id: widget.id,
                      reason: reason.isEmpty ? 'No reason provided' : reason,
                    ),
                  );
                  context.pop(); // Close bottom sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirm Rejection',
                  style: TextStyles.headingBold.copyWith(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
