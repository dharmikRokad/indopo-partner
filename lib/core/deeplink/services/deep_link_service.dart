import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deep_link_data.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _controller = StreamController<DeepLinkData?>.broadcast();
  Stream<DeepLinkData?> get deepLinkStream => _controller.stream;

  DeepLinkData? _pendingDeepLink;

  DeepLinkData? get pendingDeepLink => _pendingDeepLink;

  DeepLinkData? consumePendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    return link;
  }

  Future<void> initialize() async {
    final appLinks = AppLinks();

    // Background/Foreground links
    appLinks.uriLinkStream.listen(_handleIncomingUri);

    // Cold start links
    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) {
        _handleIncomingUri(uri);
      }
    } catch (_) {
      // Handle potential cold start link extraction errors gracefully
    }

    // Deferred Deep Link check on first launch
    Future.delayed(const Duration(milliseconds: 500), _checkDeferredLink);
  }

  void _handleIncomingUri(Uri uri) {
    final data = DeepLinkData.fromUri(uri);
    if (data.hasValidRoute) {
      _pendingDeepLink = data;
      _controller.add(data);
    }
  }

  Future<void> _checkDeferredLink() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('has_run_before') ?? false) return;

    if (PlatformDispatcher.instance.views.isNotEmpty) {
      final view = PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;

      // Fingerprint details for backend query if needed
      final fingerprint = {
        'osName': Platform.isAndroid ? 'android' : 'ios',
        'screenWidth': size.width.toInt(),
        'screenHeight': size.height.toInt(),
      };
      
      // Deferred check placeholder - logic for GET/POST /deferred-deeplink backend call if implemented
      // ignore: unused_local_variable
      final _ = fingerprint;
    }

    await prefs.setBool('has_run_before', true);
  }

  void dispose() {
    _controller.close();
  }
}
