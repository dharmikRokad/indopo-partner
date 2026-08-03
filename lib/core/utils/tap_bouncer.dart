import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility to prevent rapid double-tapping on buttons or interactive widgets.
class TapBouncer {
  final Duration cooldown;
  int _lastClickTime = 0;
  bool _isBusy = false;

  TapBouncer({this.cooldown = const Duration(milliseconds: 600)});

  /// Returns true if the tap is allowed, false if it was debounced/throttled.
  bool allowTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastClickTime < cooldown.inMilliseconds || _isBusy) {
      return false;
    }
    _lastClickTime = now;
    return true;
  }

  /// Executes [onTap] only if the tap is allowed within the cooldown period.
  void run(VoidCallback onTap) {
    if (allowTap()) {
      onTap();
    }
  }

  /// Runs an asynchronous task [onTap], setting busy state during execution.
  Future<void> runAsync(Future<void> Function() onTap) async {
    if (!allowTap()) return;
    _isBusy = true;
    try {
      await onTap();
    } finally {
      _isBusy = false;
    }
  }

  void reset() {
    _lastClickTime = 0;
    _isBusy = false;
  }
}

/// Helper function to create a debounced VoidCallback with a specified cooldown.
VoidCallback debouncedCallback(
  VoidCallback callback, {
  Duration cooldown = const Duration(milliseconds: 600),
}) {
  int lastClickTime = 0;
  return () {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastClickTime < cooldown.inMilliseconds) return;
    lastClickTime = now;
    callback();
  };
}
