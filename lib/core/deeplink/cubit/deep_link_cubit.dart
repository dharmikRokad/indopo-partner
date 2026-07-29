import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/deep_link_data.dart';
import '../services/deep_link_service.dart';
import 'deep_link_state.dart';

class DeepLinkCubit extends Cubit<DeepLinkState> {
  StreamSubscription? _sub;

  DeepLinkCubit() : super(const DeepLinkState()) {
    // Check if there's a pending link before the cubit was created
    final pending = DeepLinkService.instance.consumePendingDeepLink();
    if (pending != null) {
      emit(DeepLinkState(pendingDeepLink: pending));
    }

    // Listen for incoming deep links
    _sub = DeepLinkService.instance.deepLinkStream.listen((link) {
      if (link != null) {
        emit(DeepLinkState(pendingDeepLink: link));
      }
    });
  }

  void setDeepLink(DeepLinkData link) {
    emit(DeepLinkState(pendingDeepLink: link));
  }

  void consumeDeepLink() {
    emit(const DeepLinkState(pendingDeepLink: null));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
