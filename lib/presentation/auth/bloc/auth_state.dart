import 'package:equatable/equatable.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/partner_type.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class Unauthenticated extends AuthState {
  final PartnerType? selectedRole;

  const Unauthenticated({this.selectedRole});

  @override
  List<Object?> get props => [selectedRole];
}

class RoleChosen extends AuthState {
  final PartnerType selectedRole;

  const RoleChosen(this.selectedRole);

  @override
  List<Object?> get props => [selectedRole];
}

class AuthLoading extends AuthState {
  final PartnerType selectedRole;

  const AuthLoading(this.selectedRole);

  @override
  List<Object?> get props => [selectedRole];
}

class AuthSuccess extends AuthState {
  final PartnerModel partner;

  const AuthSuccess(this.partner);

  @override
  List<Object?> get props => [partner];
}

class AuthFailure extends AuthState {
  final String message;
  final PartnerType selectedRole;

  const AuthFailure(this.message, this.selectedRole);

  @override
  List<Object?> get props => [message, selectedRole];
}

class AccountSuspended extends AuthState {
  final String message;

  const AccountSuspended([this.message = 'Account is suspended, contact support']);

  @override
  List<Object?> get props => [message];
}
