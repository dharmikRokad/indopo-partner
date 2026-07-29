import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/presentation/widgets/logout_confirmation_dialog.dart';
import '../../../core/theme/text_styles.dart';
import 'package:indopo_partner/data/models/partner_type.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/request_list_bloc.dart';
import '../bloc/request_list_event.dart';
import '../bloc/request_list_state.dart';

class MedicalRequestsScreen extends StatelessWidget {
  const MedicalRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RequestListBloc(
        requestRepository: context.read<RequestRepository>(),
        isMedical: true,
      )..add(const FetchRequests(RequestStatus.newRequest)),
      child: const _MedicalRequestsContent(),
    );
  }
}

class _MedicalRequestsContent extends StatelessWidget {
  const _MedicalRequestsContent();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String partnerName = 'Medical Store';
    String roleBadge = '💊 Medical';
    bool isAvailable = false;

    if (authState.status == AuthBlocStatus.authenticated && authState.partner != null) {
      final p = authState.partner!;
      partnerName = p.details['full_name'] ??
          p.details['pharmacy_name'] ??
          p.details['lab_name'] ??
          p.name;
      roleBadge = '${p.role.icon} ${p.role.displayName}';
      isAvailable = p.isAvailable;
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
              final shouldLogout = await LogoutConfirmationDialog.show(context);
              if (shouldLogout == true && context.mounted) {
                context.read<AuthBloc>().add(LogoutRequested());
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<RequestListBloc, RequestListState>(
        builder: (context, state) {
          if (state.status == RequestListStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue1),
            );
          }

          if (state.status == RequestListStatus.failure) {
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
                  Text('Error loading prescription requests',
                      style: TextStyles.headingSemiBold),
                  const SizedBox(height: 4),
                  Text(state.errorMessage ?? 'Unknown error', style: TextStyles.labelRegular),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<RequestListBloc>().add(
                            const FetchRequests(RequestStatus.newRequest),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.status == RequestListStatus.loaded) {
            final requests = state.requests;

            if (requests.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<RequestListBloc>().add(
                        const FetchRequests(RequestStatus.newRequest),
                      );
                },
                color: AppColors.blue1,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No prescription requests',
                            style: TextStyles.headingSemiBold
                                .copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prescription inquiries from patients will appear here',
                            style: TextStyles.labelRegular
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<RequestListBloc>().add(
                      const FetchRequests(RequestStatus.newRequest),
                    );
              },
              color: AppColors.blue1,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return _MedicalRequestCard(request: request);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MedicalRequestCard extends StatefulWidget {
  final RequestModel request;

  const _MedicalRequestCard({required this.request});

  @override
  State<_MedicalRequestCard> createState() => _MedicalRequestCardState();
}

class _MedicalRequestCardState extends State<_MedicalRequestCard> {
  bool _isLoadingChat = false;

  Future<void> _handleGoToChat() async {
    setState(() => _isLoadingChat = true);

    try {
      final authState = context.read<AuthBloc>().state;
      String? partnerId;
      if (authState.status == AuthBlocStatus.authenticated && authState.partner != null) {
        partnerId = authState.partner!.id;
      }

      final supabaseRepo = context.read<SupabaseChatRepository>();
      final chatId = await supabaseRepo.openPrescriptionChat(
        patientId: widget.request.patientId ?? '',
        prescriptionUrl: widget.request.attachments.isNotEmpty
            ? widget.request.attachments.first
            : '',
        notes: widget.request.description,
        partnerId: partnerId,
        notificationId: widget.request.notificationId ?? widget.request.id,
      );

      if (!mounted) return;
      context.push(
        '${AppRoutes.chat.replaceAll(':id', chatId)}?appointmentId=${widget.request.id}',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to open chat: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final formattedTime =
        '${request.timestamp.day}/${request.timestamp.month}/${request.timestamp.year} ${request.timestamp.hour.toString().padLeft(2, '0')}:${request.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.blue2.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.blue2,
                  child: Text(
                    request.patientInitials,
                    style: TextStyles.headingBold.copyWith(
                      color: Colors.white,
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
                        request.patientName,
                        style: TextStyles.headingSemiBold.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.patientAge} yrs • ${request.patientGender}',
                        style: TextStyles.labelRegular.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue3,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formattedTime,
                    style: TextStyles.labelRegular.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.blue3),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: AppColors.blue1,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Prescription Inquiry Details',
                      style: TextStyles.headingSemiBold.copyWith(
                        fontSize: 13,
                        color: AppColors.blue1,
                      ),
                    ),
                  ],
                ),
                if (request.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue3.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.blue2.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Note: "${request.description}"',
                      style: TextStyles.bodyRegular.copyWith(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (request.attachments.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showPrescriptionSheet(
                      context,
                      request.attachments.first,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            request.attachments.first,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 60,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.blue3,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.picture_as_pdf, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Prescription PDF Attached', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.blue3,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.receipt_rounded, color: AppColors.blue1, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Prescription Image / Document Available',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.blue3),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push(
                        AppRoutes.requestDetail.replaceAll(':id', request.id),
                        extra: request,
                      );
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.blue2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingChat ? null : _handleGoToChat,
                    icon: _isLoadingChat
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: Text(_isLoadingChat ? 'Opening...' : 'Go to Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showPrescriptionSheet(BuildContext context, String imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1117),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.image_search_rounded,
                        color: AppColors.blue1, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Prescription Image',
                      style: TextStyles.headingSemiBold.copyWith(fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Zoomable image
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.blue1,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_rounded,
                                color: Colors.white38, size: 64),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load image',
                              style: TextStyles.labelRegular.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Hint
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Text(
                  'Pinch to zoom • Drag to pan',
                  style: TextStyles.labelRegular.copyWith(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
