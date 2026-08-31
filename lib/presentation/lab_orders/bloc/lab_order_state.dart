import 'package:equatable/equatable.dart';
import '../../../data/models/lab_order_model.dart';

enum LabOrderBlocStatus { initial, loading, success, failure }

class LabOrderState extends Equatable {
  final LabOrderBlocStatus status;
  final List<LabDispatchModel> dispatches;
  final String? acceptingOrderId;
  final String? actionSuccessMessage;
  final String? errorMessage;

  const LabOrderState({
    this.status = LabOrderBlocStatus.initial,
    this.dispatches = const [],
    this.acceptingOrderId,
    this.actionSuccessMessage,
    this.errorMessage,
  });

  List<LabDispatchModel> get pendingDispatches {
    return dispatches.where((d) {
      return (d.dispatchStatus == LabDispatchStatus.notified ||
              d.dispatchStatus == LabDispatchStatus.pending) &&
          d.order.status == LabOrderStatus.pending;
    }).toList();
  }

  List<LabDispatchModel> get acceptedDispatches {
    return dispatches.where((d) {
      return d.dispatchStatus == LabDispatchStatus.accepted ||
          d.order.status == LabOrderStatus.accepted;
    }).toList();
  }

  List<LabDispatchModel> get historyDispatches {
    return dispatches.where((d) {
      return !pendingDispatches.contains(d) && !acceptedDispatches.contains(d);
    }).toList();
  }

  LabOrderState copyWith({
    LabOrderBlocStatus? status,
    List<LabDispatchModel>? dispatches,
    String? acceptingOrderId,
    String? actionSuccessMessage,
    String? errorMessage,
  }) {
    return LabOrderState(
      status: status ?? this.status,
      dispatches: dispatches ?? this.dispatches,
      acceptingOrderId: acceptingOrderId,
      actionSuccessMessage: actionSuccessMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        dispatches,
        acceptingOrderId,
        actionSuccessMessage,
        errorMessage,
      ];
}
