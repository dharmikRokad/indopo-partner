import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/partner_type.dart';
import '../../../core/presentation/bloc/value_cubit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _obscurePasswordCubit = ValueCubit<bool>(true);
  final _credentialsFilledCubit = ValueCubit<bool>(false);

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _obscurePasswordCubit.close();
    _credentialsFilledCubit.close();
    super.dispose();
  }

  void _updateButtonState() {
    final isFilled =
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (_credentialsFilledCubit.state != isFilled) {
      _credentialsFilledCubit.update(isFilled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue3,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            AppSnackBar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          // Determine active selected role
          PartnerType? selectedRole;
          bool isLoading = false;

          if (state is RoleChosen) {
            selectedRole = state.selectedRole;
          } else if (state is AuthLoading) {
            selectedRole = state.selectedRole;
            isLoading = true;
          } else if (state is AuthFailure) {
            selectedRole = state.selectedRole;
          } else if (state is Unauthenticated) {
            selectedRole = state.selectedRole;
          }

          final bool isRoleSelected = selectedRole != null;

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
                    const SizedBox(height: 20),
                    // Header Area
                    Text(
                      'Welcome to Indopo',
                      style: TextStyles.headingBold.copyWith(fontSize: 32),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Healthcare Partner Portal',
                      style: TextStyles.bodyRegular.copyWith(
                        color: AppColors.blue1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // STEP 1: Role Selection Grid
                    Text(
                      AppStrings.selectRoleHeader,
                      style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.25,
                      children: [
                        _RoleCard(
                          label: AppStrings.doctor,
                          icon: '🩺',
                          isSelected: selectedRole == PartnerType.doctor,
                          onTap: () => _selectRole(PartnerType.doctor),
                        ),
                        _RoleCard(
                          label: AppStrings.medical,
                          icon: '💊',
                          isSelected: selectedRole == PartnerType.pharmacy,
                          onTap: () => _selectRole(PartnerType.pharmacy),
                        ),
                        _RoleCard(
                          label: AppStrings.laboratory,
                          icon: '🧪',
                          isSelected: selectedRole == PartnerType.laboratory,
                          onTap: () => _selectRole(PartnerType.laboratory),
                        ),
                        _RoleCard(
                          label: AppStrings.imagingCenter,
                          icon: '🏥',
                          isSelected: selectedRole == PartnerType.imagingCenter,
                          onTap: () => _selectRole(PartnerType.imagingCenter),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Inline hint when no role selected
                    if (!isRoleSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '* ${AppStrings.selectRoleHint}',
                          style: TextStyles.bodyRegular.copyWith(
                            color: AppColors.warning,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    const SizedBox(height: 32),

                    // STEP 2: Credentials Form
                    Opacity(
                      opacity: isRoleSelected ? 1.0 : 0.4,
                      child: AbsorbPointer(
                        absorbing: !isRoleSelected,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email/Username field
                            Text(
                              AppStrings.emailUsernameLabel,
                              style: TextStyles.headingSemiBold.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              enabled: isRoleSelected,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Enter your email or username',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 20),

                            // Password field
                            Text(
                              AppStrings.passwordLabel,
                              style: TextStyles.headingSemiBold.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<ValueCubit<bool>, bool>(
                              bloc: _obscurePasswordCubit,
                              builder: (context, obscurePassword) {
                                return TextFormField(
                                  controller: _passwordController,
                                  obscureText: obscurePassword,
                                  enabled: isRoleSelected,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: AppColors.textMuted,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.textMuted,
                                      ),
                                      onPressed: () {
                                        _obscurePasswordCubit.update(
                                          !obscurePassword,
                                        );
                                      },
                                    ),
                                  ),
                                  validator: Validators.validatePassword,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // CTA Login button
                    BlocBuilder<ValueCubit<bool>, bool>(
                      bloc: _credentialsFilledCubit,
                      builder: (context, credentialsFilled) {
                        final bool isLoginButtonEnabled =
                            isRoleSelected && credentialsFilled && !isLoading;
                        return _LoginButton(
                          isEnabled: isLoginButtonEnabled,
                          isLoading: isLoading,
                          onPressed: _submitLogin,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectRole(PartnerType role) {
    context.read<AuthBloc>().add(RoleSelected(role));
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        LoginSubmitted(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }
}

class _RoleCard extends StatefulWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? const LinearGradient(
                      colors: [AppColors.blue1, AppColors.blue2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isSelected ? null : AppColors.blue3,
              border: Border.all(
                color: widget.isSelected ? AppColors.blue1 : AppColors.blue2,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.blue1.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        widget.label,
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (widget.isSelected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isEnabled
            ? const LinearGradient(
                colors: [AppColors.blue1, AppColors.blue2],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isEnabled ? null : AppColors.surface.withValues(alpha: 0.5),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.blue2.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
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
                AppStrings.confirmLoginButton,
                style: TextStyles.headingBold.copyWith(
                  fontSize: 16,
                  color: isEnabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
      ),
    );
  }
}
