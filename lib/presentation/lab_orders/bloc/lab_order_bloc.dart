import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/lab_order_model.dart';
import '../../../data/repositories/lab_order_repository.dart';
import 'lab_order_event.dart';
import 'lab_order_state.dart';

class LabOrderBloc extends Bloc<LabOrderEvent, LabOrderState> {
  final LabOrderRepository _repository;
  Timer? _tickerTimer;

  LabOrderBloc({required LabOrderRepository repository})
      : _repository = repository,
        super(const LabOrderState()) {
    on<FetchLabOrders>(_onFetchLabOrders);
    on<AcceptLabOrderEvent>(_onAcceptLabOrder);
    on<RejectLabOrderEvent>(_onRejectLabOrder);
    on<LabTimerTickEvent>(_onTimerTick);

    _startTicker();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) {
        add(const LabTimerTickEvent());
      }
    });
  }

  Future<void> _onFetchLabOrders(
    FetchLabOrders event,
    Emitter<LabOrderState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: LabOrderBlocStatus.loading));
    }

    try {
      final dispatches = await _repository.fetchLabOrders();
      emit(state.copyWith(
        status: LabOrderBlocStatus.success,
        dispatches: dispatches,
        errorMessage: null,
      ));
    } catch (e) {
      print('[LabOrderBloc] Fetch failed: $e');
      emit(state.copyWith(
        status: LabOrderBlocStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAcceptLabOrder(
    AcceptLabOrderEvent event,
    Emitter<LabOrderState> emit,
  ) async {
    emit(state.copyWith(
      acceptingOrderId: event.orderId,
      actionSuccessMessage: null,
      errorMessage: null,
    ));

    try {
      final message = await _repository.acceptLabOrder(event.orderId);

      // Refresh dispatches list to fetch updated ACCEPTED status
      final updatedDispatches = await _repository.fetchLabOrders();

      emit(state.copyWith(
        status: LabOrderBlocStatus.success,
        dispatches: updatedDispatches,
        acceptingOrderId: null,
        actionSuccessMessage: message,
      ));
    } catch (e) {
      final errorStr = e.toString().replaceAll('Exception: ', '');
      emit(state.copyWith(
        acceptingOrderId: null,
        errorMessage: errorStr,
      ));
    }
  }

  void _onRejectLabOrder(
    RejectLabOrderEvent event,
    Emitter<LabOrderState> emit,
  ) {
    // Client-side local rejection: remove from pending or mark as skipped locally
    final updated = state.dispatches.map((d) {
      if (d.order.id == event.orderId) {
        return LabDispatchModel(
          dispatchId: d.dispatchId,
          dispatchStatus: LabDispatchStatus.timedOut,
          notifiedAt: d.notifiedAt,
          respondedAt: DateTime.now(),
          order: d.order,
        );
      }
      return d;
    }).toList();

    emit(state.copyWith(
      dispatches: updated,
      actionSuccessMessage: 'Order dismissed',
    ));
  }

  void _onTimerTick(
    LabTimerTickEvent event,
    Emitter<LabOrderState> emit,
  ) {
    // Re-emit state to trigger UI updates for remainingSeconds timer
    if (state.pendingDispatches.isNotEmpty) {
      emit(state.copyWith(dispatches: List.from(state.dispatches)));
    }
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    return super.close();
  }
}
