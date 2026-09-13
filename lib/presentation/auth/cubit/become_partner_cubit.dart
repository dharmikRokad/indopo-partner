import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/partner_type.dart';

class BecomePartnerState extends Equatable {
  final PartnerType selectedRole;
  final double? selectedLat;
  final double? selectedLong;

  const BecomePartnerState({
    required this.selectedRole,
    this.selectedLat,
    this.selectedLong,
  });

  BecomePartnerState copyWith({
    PartnerType? selectedRole,
    double? selectedLat,
    double? selectedLong,
  }) {
    return BecomePartnerState(
      selectedRole: selectedRole ?? this.selectedRole,
      selectedLat: selectedLat ?? this.selectedLat,
      selectedLong: selectedLong ?? this.selectedLong,
    );
  }

  @override
  List<Object?> get props => [selectedRole, selectedLat, selectedLong];
}

class BecomePartnerCubit extends Cubit<BecomePartnerState> {
  BecomePartnerCubit({PartnerType? initialRole})
      : super(BecomePartnerState(
          selectedRole: initialRole ?? PartnerType.doctor,
        ));

  void selectRole(PartnerType role) {
    emit(state.copyWith(selectedRole: role));
  }

  void updateLocation(double lat, double long) {
    emit(state.copyWith(selectedLat: lat, selectedLong: long));
  }
}
