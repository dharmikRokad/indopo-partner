import 'package:indopo_partner/core/constants/app_routes.dart';

import '../models/deep_link_data.dart';

class DeepLinkNavigator {
  DeepLinkNavigator._();

  static String resolveRoute(DeepLinkData data) {
    switch (data.type) {
      case DeepLinkType.resetPassword:
        final token = data.token;
        if (token != null && token.isNotEmpty) {
          return '${AppRoutes.resetPassword}?token=${Uri.encodeComponent(token)}';
        }
        return AppRoutes.login;
      case DeepLinkType.unknown:
        return AppRoutes.requestList;
    }
  }
}
