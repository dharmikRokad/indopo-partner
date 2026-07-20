import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/service_model.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class AddEditServiceDialog extends StatefulWidget {
  final ServiceModel? service;
  final List<String> categories;
  final String partnerId;

  const AddEditServiceDialog({
    super.key,
    this.service,
    required this.categories,
    required this.partnerId,
  });

  @override
  State<AddEditServiceDialog> createState() => _AddEditServiceDialogState();
}

class _AddEditServiceDialogState extends State<AddEditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryCubit = ValueCubit<String?>(null);

  @override
  void initState() {
    super.initState();
    // Filter out 'All' category if present
    final validCategories = widget.categories.where((c) => c != 'All').toList();
    
    String? initialCategory;
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _priceController.text = widget.service!.price;
      _descriptionController.text = widget.service!.description;
      if (validCategories.contains(widget.service!.category)) {
        initialCategory = widget.service!.category;
      } else if (validCategories.isNotEmpty) {
        initialCategory = validCategories.first;
      }
    } else {
      if (validCategories.isNotEmpty) {
        initialCategory = validCategories.first;
      }
    }
    _categoryCubit.update(initialCategory);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryCubit.close();
    super.dispose();
  }

  void _submit() {
    final selectedCategory = _categoryCubit.state;
    if (!_formKey.currentState!.validate() || selectedCategory == null) return;

    final now = DateTime.now().toIso8601String();
    final service = ServiceModel(
      id: widget.service?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      partnerId: widget.partnerId,
      name: _nameController.text.trim(),
      category: selectedCategory,
      description: _descriptionController.text.trim(),
      price: _priceController.text.trim(),
      isAvailable: widget.service?.isAvailable ?? true,
      createdAt: widget.service?.createdAt ?? now,
    );

    Navigator.of(context).pop(service);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.service != null;
    final validCategories = widget.categories.where((c) => c != 'All').toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.blue3,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Service' : 'Add New Service',
                      style: TextStyles.headingSemiBold.copyWith(fontSize: 20),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Service Name
                _buildLabel('Service Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g., Whole Body PET Scan',
                  ),
                  validator: (v) => Validators.validateRequired(v, 'Service name'),
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                _buildLabel('Category'),
                const SizedBox(height: 8),
                BlocBuilder<ValueCubit<String?>, String?>(
                  bloc: _categoryCubit,
                  builder: (context, selectedCategory) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: validCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, style: TextStyles.bodyRegular),
                        );
                      }).toList(),
                      onChanged: (val) {
                        _categoryCubit.update(val);
                      },
                      validator: (v) => v == null ? 'Please select a category' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Price
                _buildLabel('Price'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g., 800',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final numValue = double.tryParse(v.trim());
                    if (numValue == null || numValue <= 0) {
                      return 'Please enter a valid price greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description
                _buildLabel('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Provide details about the service...',
                  ),
                  validator: (v) => Validators.validateRequired(v, 'Description'),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.blue2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyles.headingSemiBold.copyWith(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEdit ? 'Save Changes' : 'Create Service',
                            style: TextStyles.headingBold.copyWith(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyles.headingSemiBold.copyWith(fontSize: 14, color: AppColors.blue1),
    );
  }
}
