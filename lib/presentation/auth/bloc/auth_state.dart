import 'package:equatable/equatable.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/partner_type.dart';

enum AuthBlocStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  roleChosen,
  forgotPasswordLoading,
  forgotPasswordSuccess,
  forgotPasswordFailure,
  resetPasswordLoading,
  resetPasswordSuccess,
  resetPasswordFailure,
  becomePartnerLoading,
  becomePartnerSuccess,
  becomePartnerFailure,
  error,
  accountSuspended,
}

class AuthState extends Equatable {
  static const Object _kNoChange = Object();

  final AuthBlocStatus status;
  final PartnerType? selectedRole;
  final PartnerModel? partner;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthBlocStatus.initial,
    this.selectedRole,
    this.partner,
    this.errorMessage,
    this.successMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthBlocStatus.initial);

  AuthState copyWith({
    AuthBlocStatus? status,
    Object? selectedRole = _kNoChange,
    Object? partner = _kNoChange,
    Object? errorMessage = _kNoChange,
    Object? successMessage = _kNoChange,
  }) {
    return AuthState(
      status: status ?? this.status,
      selectedRole: selectedRole == _kNoChange
          ? this.selectedRole
          : selectedRole as PartnerType?,
      partner: partner == _kNoChange ? this.partner : partner as PartnerModel?,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: successMessage == _kNoChange
          ? this.successMessage
          : successMessage as String?,
    );
  }

  @override
  List<Object?> get props =>
      [status, selectedRole, partner, errorMessage, successMessage];
}
