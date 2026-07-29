import 'package:equatable/equatable.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/models/partner_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class PartnerUpdated extends AuthEvent {
  final PartnerModel partner;

  const PartnerUpdated(this.partner);

  @override
  List<Object?> get props => [partner];
}

class RoleSelected extends AuthEvent {
  final PartnerType role;

  const RoleSelected(this.role);

  @override
  List<Object?> get props => [role];
}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;

  const LoginSubmitted({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class LogoutRequested extends AuthEvent {}

class AvailabilityToggled extends AuthEvent {
  final bool isAvailable;

  const AvailabilityToggled(this.isAvailable);

  @override
  List<Object?> get props => [isAvailable];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String accessToken;
  final String newPassword;

  const ResetPasswordRequested({
    required this.accessToken,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [accessToken, newPassword];
}
