import 'package:equatable/equatable.dart';

abstract class RequestDetailEvent extends Equatable {
  const RequestDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchRequestDetail extends RequestDetailEvent {
  final String id;

  const FetchRequestDetail(this.id);

  @override
  List<Object?> get props => [id];
}

class AcceptRequest extends RequestDetailEvent {
  final String id;
  final String? partnerId;
  final String? partnerName;
  final String? patientId;
  final String? patientName;

  const AcceptRequest(
    this.id, {
    this.partnerId,
    this.partnerName,
    this.patientId,
    this.patientName,
  });

  @override
  List<Object?> get props => [
    id,
    partnerId,
    partnerName,
    patientId,
    patientName,
  ];
}

class RejectRequest extends RequestDetailEvent {
  final String id;
  final String reason;

  const RejectRequest({required this.id, required this.reason});

  @override
  List<Object?> get props => [id, reason];
}

class CompleteRequest extends RequestDetailEvent {
  final String id;

  const CompleteRequest(this.id);

  @override
  List<Object?> get props => [id];
}

class StartPrescriptionChat extends RequestDetailEvent {
  final String id;
  final String? partnerId;
  final String? patientId;
  final String? prescriptionUrl;
  final String? notes;
  final String? notificationId;

  const StartPrescriptionChat({
    required this.id,
    this.partnerId,
    this.patientId,
    this.prescriptionUrl,
    this.notes,
    this.notificationId,
  });

  @override
  List<Object?> get props => [
    id,
    partnerId,
    patientId,
    prescriptionUrl,
    notes,
    notificationId,
  ];
}

class AppointmentConfirmed extends RequestDetailEvent {
  final dynamic appointment;

  const AppointmentConfirmed(this.appointment);

  @override
  List<Object?> get props => [appointment];
}
