import 'package:equatable/equatable.dart';

abstract class LabOrderEvent extends Equatable {
  const LabOrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchLabOrders extends LabOrderEvent {
  final bool isRefresh;
  const FetchLabOrders({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class AcceptLabOrderEvent extends LabOrderEvent {
  final String orderId;
  const AcceptLabOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class RejectLabOrderEvent extends LabOrderEvent {
  final String orderId;
  const RejectLabOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class LabTimerTickEvent extends LabOrderEvent {
  const LabTimerTickEvent();
}
