import 'package:equatable/equatable.dart';
import '../models/deep_link_data.dart';

class DeepLinkState extends Equatable {
  final DeepLinkData? pendingDeepLink;

  const DeepLinkState({this.pendingDeepLink});

  @override
  List<Object?> get props => [pendingDeepLink];
}
