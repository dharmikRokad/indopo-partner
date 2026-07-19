import '../../../data/models/service_model.dart';

abstract class ServicesState {
  const ServicesState();
}

class ServicesInitial extends ServicesState {}

class ServicesLoading extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<ServiceModel> allServices;
  final List<ServiceModel> filteredServices;
  final String selectedCategory;
  final List<String> categories;

  const ServicesLoaded({
    required this.allServices,
    required this.filteredServices,
    required this.selectedCategory,
    required this.categories,
  });

  ServicesLoaded copyWith({
    List<ServiceModel>? allServices,
    List<ServiceModel>? filteredServices,
    String? selectedCategory,
    List<String>? categories,
  }) {
    return ServicesLoaded(
      allServices: allServices ?? this.allServices,
      filteredServices: filteredServices ?? this.filteredServices,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categories: categories ?? this.categories,
    );
  }
}

class ServicesFailure extends ServicesState {
  final String message;

  const ServicesFailure(this.message);
}
