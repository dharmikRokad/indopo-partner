import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/service_model.dart';
import '../../../data/repositories/service_repo.dart';
import '../../../data/repositories/dropdown_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/services_bloc.dart';
import '../bloc/services_event.dart';
import '../bloc/services_state.dart';
import 'add_edit_service_dialog.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final partner = authState.partner;

    return BlocProvider(
      create: (context) => ServicesBloc(
        serviceRepository: context.read<ServiceRepository>(),
        dropdownRepository: context.read<DropdownRepository>(),
        authBloc: context.read<AuthBloc>(),
      )..add(LoadServices(partnerId: partner.id, role: partner.role)),
      child: const _ServicesContent(),
    );
  }
}

class _ServicesContent extends StatefulWidget {
  const _ServicesContent();

  @override
  State<_ServicesContent> createState() => _ServicesContentState();
}

class _ServicesContentState extends State<_ServicesContent> {
  void _openAddServiceDialog(List<String> categories, String partnerId) async {
    final result = await showModalBottomSheet<ServiceModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditServiceDialog(
        categories: categories,
        partnerId: partnerId,
      ),
    );

    if (result != null && mounted) {
      context.read<ServicesBloc>().add(AddService(result));
      AppSnackBar.showSuccess(context, 'Service created successfully!');
    }
  }

  void _openEditServiceDialog(ServiceModel service, List<String> categories, String partnerId) async {
    final result = await showModalBottomSheet<ServiceModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditServiceDialog(
        service: service,
        categories: categories,
        partnerId: partnerId,
      ),
    );

    if (result != null && mounted) {
      context.read<ServicesBloc>().add(UpdateService(result));
      AppSnackBar.showSuccess(context, 'Service updated successfully!');
    }
  }

  void _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Service', style: TextStyles.headingSemiBold),
        content: Text(
          'Are you sure you want to delete this service? This action cannot be undone.',
          style: TextStyles.bodyRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<ServicesBloc>().add(DeleteService(id));
      AppSnackBar.showSuccess(context, 'Service deleted successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state as AuthSuccess;
    final partner = authState.partner;

    return Scaffold(
      backgroundColor: AppColors.blue3,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Services', style: TextStyles.headingSemiBold.copyWith(fontSize: 18)),
            BlocBuilder<ServicesBloc, ServicesState>(
              builder: (context, state) {
                if (state is ServicesLoaded) {
                  final count = state.allServices.length;
                  return Text(
                    '$count ${count == 1 ? 'service' : 'services'} total',
                    style: TextStyles.labelRegular.copyWith(fontSize: 12),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      body: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, state) {
          if (state is ServicesLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.blue1));
          }

          if (state is ServicesFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load services',
                      style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyles.labelRegular,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ServicesBloc>().add(LoadServices(
                          partnerId: partner.id,
                          role: partner.role,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ServicesLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Horizontal category filter chips
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      final isSelected = state.selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: AppColors.blue2,
                          checkmarkColor: Colors.white,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.blue1 : AppColors.blue2.withValues(alpha: 0.3),
                            ),
                          ),
                          onSelected: (_) {
                            context.read<ServicesBloc>().add(FilterServicesByCategory(category));
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Main services list
                Expanded(
                  child: state.filteredServices.isEmpty
                      ? _buildEmptyState(context, state.categories, partner.id)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = state.filteredServices[index];
                            return _buildServiceCard(context, service, state.categories, partner.id);
                          },
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, state) {
          if (state is ServicesLoaded) {
            return FloatingActionButton(
              onPressed: () => _openAddServiceDialog(state.categories, partner.id),
              backgroundColor: AppColors.blue1,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, List<String> categories, String partnerId) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blue2.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.layers_clear_outlined, size: 64, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(
            'No Services Found',
            style: TextStyles.headingSemiBold.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Add services to your profile so that patients can browse and schedule appointments.',
            style: TextStyles.labelRegular,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openAddServiceDialog(categories, partnerId),
            icon: const Icon(Icons.add),
            label: const Text('Add Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceModel service, List<String> categories, String partnerId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: service.isAvailable ? AppColors.blue2.withValues(alpha: 0.3) : AppColors.surface,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyles.headingSemiBold.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service.category,
                          style: TextStyles.bodyMedium.copyWith(color: AppColors.blue1, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${service.price}',
                  style: TextStyles.headingBold.copyWith(color: AppColors.blue1, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service.description,
              style: TextStyles.bodyRegular.copyWith(color: AppColors.textMuted, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.blue3, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Available',
                      style: TextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        color: service.isAvailable ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: service.isAvailable,
                      activeThumbColor: AppColors.blue1,
                      activeTrackColor: AppColors.blue2,
                      inactiveThumbColor: AppColors.textMuted,
                      inactiveTrackColor: AppColors.surface,
                      onChanged: (val) {
                        context.read<ServicesBloc>().add(ToggleAvailability(
                          id: service.id,
                          isAvailable: val,
                        ));
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.blue1),
                      onPressed: () => _openEditServiceDialog(service, categories, partnerId),
                      tooltip: 'Edit Service',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      onPressed: () => _confirmDelete(service.id),
                      tooltip: 'Delete Service',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
