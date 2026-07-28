import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../core/network_copy/local_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final LocalStorage _localStorage;

  AuthBloc({
    required AuthRepository authRepository,
    required LocalStorage localStorage,
  })  : _authRepository = authRepository,
        _localStorage = localStorage,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<PartnerUpdated>(_onPartnerUpdated);
    on<RoleSelected>(_onRoleSelected);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<AvailabilityToggled>(_onAvailabilityToggled);
  }

  Future<void> _onPartnerUpdated(
    PartnerUpdated event,
    Emitter<AuthState> emit,
  ) async {
    if (!event.partner.isActive) {
      await _authRepository.logout();
      emit(const AccountSuspended('Account is suspended, contact support'));
      return;
    }
    emit(AuthSuccess(event.partner));
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final partner = await _authRepository.checkActiveSession();
      if (partner != null) {
        if (!partner.isActive) {
          emit(const AccountSuspended('Account is suspended, contact support'));
        } else {
          emit(AuthSuccess(partner));
        }
      } else {
        final cachedRoleKey = _localStorage.getSelectedRole();
        final cachedRole = cachedRoleKey != null 
            ? PartnerTypeExtension.fromKey(cachedRoleKey) 
            : null;
        emit(Unauthenticated(selectedRole: cachedRole));
      }
    } catch (e) {
      emit(const Unauthenticated());
    }
  }

  void _onRoleSelected(
    RoleSelected event,
    Emitter<AuthState> emit,
  ) {
    emit(RoleChosen(event.role));
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    PartnerType? activeRole;
    final currentState = state;
    
    if (currentState is RoleChosen) {
      activeRole = currentState.selectedRole;
    } else if (currentState is AuthFailure) {
      activeRole = currentState.selectedRole;
    } else if (currentState is Unauthenticated) {
      activeRole = currentState.selectedRole;
    }

    if (activeRole == null) {
      emit(const AuthFailure('Please select your role first', PartnerType.doctor));
      return;
    }

    emit(AuthLoading(activeRole));

    try {
      final partner = await _authRepository.login(
        email: event.username,
        password: event.password,
        selectedRole: activeRole,
      );
      emit(AuthSuccess(partner));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage, activeRole));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthInitial());
    await _authRepository.logout();
    emit(const Unauthenticated());
  }

  Future<void> _onAvailabilityToggled(
    AvailabilityToggled event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthSuccess) {
      final oldPartner = currentState.partner;
      try {
        // Optimistically update the UI status first
        emit(AuthSuccess(oldPartner.copyWith(isAvailable: event.isAvailable)));
        await _authRepository.updateAvailability(event.isAvailable);
      } catch (e) {
        // Revert on error
        print('[AuthBloc] Failed to update availability: $e');
        emit(AuthSuccess(oldPartner));
      }
    }
  }
}
