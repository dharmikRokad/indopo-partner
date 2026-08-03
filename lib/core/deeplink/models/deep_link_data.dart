import 'package:equatable/equatable.dart';

enum DeepLinkType { resetPassword, unknown }

class DeepLinkData extends Equatable {
  final DeepLinkType type;
  final Map<String, String?> params;

  const DeepLinkData({required this.type, required this.params});

  bool get hasValidRoute => type != DeepLinkType.unknown;

  String? get token =>
      params['token'] ??
      params['access_token'] ??
      params['accesstoken'] ??
      params['code'];

  factory DeepLinkData.fromMap(Map<dynamic, dynamic> rawParams) {
    final params = <String, String?>{};
    for (final entry in rawParams.entries) {
      if (entry.key is! String) continue;
      params[(entry.key as String).trim().toLowerCase()] = entry.value
          ?.toString();
    }

    final action = params['action'] ?? params['type'] ?? '';
    DeepLinkType type = DeepLinkType.unknown;

    if (action.contains('reset') || action.contains('recovery')) {
      type = DeepLinkType.resetPassword;
    }

    return DeepLinkData(type: type, params: params);
  }

  factory DeepLinkData.fromUri(Uri uri) {
    // Validate scheme or host
    final isIndopoScheme = uri.scheme.toLowerCase() == 'indopo-partner';
    final isIndopoHost =
        uri.host.toLowerCase() == 'indopo-partner' ||
        uri.host.toLowerCase() == 'link.indopo.com';

    if (!isIndopoScheme && !isIndopoHost) {
      return const DeepLinkData(type: DeepLinkType.unknown, params: {});
    }

    final params = Map<String, String?>.from(uri.queryParameters);

    // Extract fragment parameters (e.g., Supabase Auth #access_token=...&type=recovery)
    if (uri.fragment.isNotEmpty) {
      try {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        params.addAll(fragmentParams);
      } catch (_) {}
    }

    // Determine action from the first path segment after domain name (indopo / link.indopo.com)
    String action = '';
    if (uri.pathSegments.isNotEmpty) {
      action = uri.pathSegments.first;
    } else if (isIndopoScheme &&
        uri.host.isNotEmpty &&
        uri.host.toLowerCase() != 'indopo-partner' &&
        uri.host.toLowerCase() != 'link.indopo.com') {
      // e.g. indopo://reset-password where 'reset-password' is parsed as Uri host
      action = uri.host;
    }

    if (action.isEmpty) {
      action = params['action'] ?? params['type'] ?? '';
    }

    params['action'] = action;

    return DeepLinkData.fromMap(params);
  }

  @override
  List<Object?> get props => [type, params];
}
