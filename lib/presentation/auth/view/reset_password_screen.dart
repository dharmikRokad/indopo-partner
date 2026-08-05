import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/presentation/bloc/value_cubit.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final String? email;

  const ResetPasswordScreen({super.key, this.token, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _obscureNewPasswordCubit = ValueCubit<bool>(true);
  final _obscureConfirmPasswordCubit = ValueCubit<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.token == null || widget.token!.trim().isEmpty) {
        AppSnackBar.showError(
          context,
          'Something went wrong: Invalid or missing password reset token.',
        );
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _obscureNewPasswordCubit.close();
    _obscureConfirmPasswordCubit.close();
    super.dispose();
  }

  void _submitReset() {
    if (widget.token == null || widget.token!.trim().isEmpty) {
      AppSnackBar.showError(
        context,
        'Something went wrong: Invalid or missing password reset token.',
      );
      context.go(AppRoutes.login);
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final newPassword = _newPasswordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (newPassword != confirmPassword) {
        AppSnackBar.showError(context, 'Passwords do not match.');
        return;
      }

      context.read<AuthBloc>().add(
        ResetPasswordRequested(
          accessToken: widget.token!.trim(),
          email: widget.email!.trim(),
          newPassword: newPassword,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue3,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthBlocStatus.resetPasswordSuccess) {
            AppSnackBar.showSuccess(
              context,
              state.successMessage ?? 'Password reset successfully',
            );
            context.go(AppRoutes.login);
          } else if (state.status == AuthBlocStatus.resetPasswordFailure) {
            AppSnackBar.showError(
              context,
              state.errorMessage ?? 'Failed to reset password',
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthBlocStatus.resetPasswordLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Reset Password',
                      style: TextStyles.headingBold.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your new password below to reset your account password.',
                      style: TextStyles.bodyRegular.copyWith(
                        color: AppColors.blue1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // New Password field
                    Text(
                      'New Password',
                      style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ValueCubit<bool>, bool>(
                      bloc: _obscureNewPasswordCubit,
                      builder: (context, obscure) {
                        return TextFormField(
                          controller: _newPasswordController,
                          obscureText: obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.textMuted,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () =>
                                  _obscureNewPasswordCubit.update(!obscure),
                            ),
                          ),
                          validator: Validators.validatePassword,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password field
                    Text(
                      'Confirm New Password',
                      style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ValueCubit<bool>, bool>(
                      bloc: _obscureConfirmPasswordCubit,
                      builder: (context, obscure) {
                        return TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Re-enter new password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.textMuted,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () =>
                                  _obscureConfirmPasswordCubit.update(!obscure),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (val != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 36),

                    // Submit Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [AppColors.blue1, AppColors.blue2],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue2.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Reset Password',
                                style: TextStyles.headingBold.copyWith(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
