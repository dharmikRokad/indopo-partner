import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../core/network_copy/local_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final LocalStorage _localStorage;

  AuthBloc({required this._authRepository, required this._localStorage})
    : super(AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<PartnerUpdated>(_onPartnerUpdated);
    on<RoleSelected>(_onRoleSelected);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<AvailabilityToggled>(_onAvailabilityToggled);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<BecomePartnerSubmitted>(_onBecomePartnerSubmitted);
  }

  Future<void> _onPartnerUpdated(
    PartnerUpdated event,
    Emitter<AuthState> emit,
  ) async {
    if (!event.partner.isActive) {
      await _authRepository.logout();
      emit(
        state.copyWith(
          status: AuthBlocStatus.accountSuspended,
          errorMessage: 'Account is suspended, contact support',
          partner: null,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AuthBlocStatus.authenticated,
        partner: event.partner,
      ),
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (event.checkExistingSession) {
        final partner = await _authRepository.checkActiveSession();
        if (partner != null) {
          if (!partner.isActive) {
            emit(
              state.copyWith(
                status: AuthBlocStatus.accountSuspended,
                errorMessage: 'Account is suspended, contact support',
              ),
            );
            return;
          } else {
            emit(
              state.copyWith(
                status: AuthBlocStatus.authenticated,
                partner: partner,
              ),
            );
            return;
          }
        }
      }

      final cachedRoleKey = _localStorage.getSelectedRole();
      final cachedRole = cachedRoleKey != null
          ? PartnerTypeExtension.fromKey(cachedRoleKey)
          : null;
      emit(
        state.copyWith(
          status: AuthBlocStatus.unauthenticated,
          selectedRole: cachedRole,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AuthBlocStatus.unauthenticated));
    }
  }

  void _onRoleSelected(RoleSelected event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        status: AuthBlocStatus.roleChosen,
        selectedRole: event.role,
      ),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final activeRole = state.selectedRole;

    if (activeRole == null) {
      emit(
        state.copyWith(
          status: AuthBlocStatus.error,
          errorMessage: 'Please select your role first',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthBlocStatus.loading, errorMessage: null));

    try {
      final partner = await _authRepository.login(
        email: event.username,
        password: event.password,
        selectedRole: activeRole,
      );
      emit(
        state.copyWith(
          status: AuthBlocStatus.authenticated,
          partner: partner,
          errorMessage: null,
        ),
      );
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          status: AuthBlocStatus.error,
          errorMessage: cleanMessage,
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthBlocStatus.loading));
    await _authRepository.logout();
    emit(
      state.copyWith(
        status: AuthBlocStatus.unauthenticated,
        partner: null,
        selectedRole: null,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onAvailabilityToggled(
    AvailabilityToggled event,
    Emitter<AuthState> emit,
  ) async {
    final currentPartner = state.partner;
    if (currentPartner == null) return;
    try {
      // Optimistically update the UI status first
      emit(
        state.copyWith(
          partner: currentPartner.copyWith(isAvailable: event.isAvailable),
        ),
      );
      await _authRepository.updateAvailability(event.isAvailable);
    } catch (e) {
      // Revert on error
      print('[AuthBloc] Failed to update availability: $e');
      emit(state.copyWith(partner: currentPartner));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthBlocStatus.forgotPasswordLoading,
        errorMessage: null,
        successMessage: null,
      ),
    );
    try {
      final message = await _authRepository.requestForgotPassword(
        email: event.email,
      );
      emit(
        state.copyWith(
          status: AuthBlocStatus.forgotPasswordSuccess,
          successMessage: message,
        ),
      );
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          status: AuthBlocStatus.forgotPasswordFailure,
          errorMessage: cleanMessage,
        ),
      );
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthBlocStatus.resetPasswordLoading,
        errorMessage: null,
        successMessage: null,
      ),
    );
    try {
      final message = await _authRepository.resetPassword(
        accessToken: event.accessToken,
        newPassword: event.newPassword,
      );
      emit(
        state.copyWith(
          status: AuthBlocStatus.resetPasswordSuccess,
          successMessage: message,
        ),
      );
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          status: AuthBlocStatus.resetPasswordFailure,
          errorMessage: cleanMessage,
        ),
      );
    }
  }

  Future<void> _onBecomePartnerSubmitted(
    BecomePartnerSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthBlocStatus.becomePartnerLoading,
        errorMessage: null,
        successMessage: null,
      ),
    );
    try {
      final message = await _authRepository.submitBecomePartnerRequest(
        name: event.name,
        email: event.email,
        phone: event.phone,
        orgName: event.orgName,
        orgAddress: event.orgAddress,
        partnerType: event.partnerType,
      );
      emit(
        state.copyWith(
          status: AuthBlocStatus.becomePartnerSuccess,
          successMessage: message,
        ),
      );
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          status: AuthBlocStatus.becomePartnerFailure,
          errorMessage: cleanMessage,
        ),
      );
    }
  }
}
