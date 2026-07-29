import 'package:equatable/equatable.dart';
import '../../../data/models/service_model.dart';

enum ServicesStatus { initial, loading, loaded, failure }

class ServicesState extends Equatable {
  static const Object _kNoChange = Object();

  final ServicesStatus status;
  final List<ServiceModel> allServices;
  final List<ServiceModel> filteredServices;
  final String selectedCategory;
  final List<String> categories;
  final String? errorMessage;

  const ServicesState({
    this.status = ServicesStatus.initial,
    this.allServices = const [],
    this.filteredServices = const [],
    this.selectedCategory = 'All',
    this.categories = const [],
    this.errorMessage,
  });

  factory ServicesState.initial() =>
      const ServicesState(status: ServicesStatus.initial);

  ServicesState copyWith({
    ServicesStatus? status,
    List<ServiceModel>? allServices,
    List<ServiceModel>? filteredServices,
    String? selectedCategory,
    List<String>? categories,
    Object? errorMessage = _kNoChange,
  }) {
    return ServicesState(
      status: status ?? this.status,
      allServices: allServices ?? this.allServices,
      filteredServices: filteredServices ?? this.filteredServices,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categories: categories ?? this.categories,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allServices,
        filteredServices,
        selectedCategory,
        categories,
        errorMessage,
      ];
}
