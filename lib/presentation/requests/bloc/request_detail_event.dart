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

  const AcceptRequest(this.id);

  @override
  List<Object?> get props => [id];
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
