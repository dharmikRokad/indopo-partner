import 'package:flutter_bloc/flutter_bloc.dart';
import 'services_event.dart';
import 'services_state.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/repositories/service_repo.dart';
import '../../../data/repositories/dropdown_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/bloc/auth_event.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository _serviceRepository;
  final DropdownRepository _dropdownRepository;
  final AuthBloc _authBloc;

  ServicesBloc({
    required ServiceRepository serviceRepository,
    required DropdownRepository dropdownRepository,
    required AuthBloc authBloc,
  })  : _serviceRepository = serviceRepository,
        _dropdownRepository = dropdownRepository,
        _authBloc = authBloc,
        super(ServicesState.initial()) {
    on<LoadServices>(_onLoadServices);
    on<AddService>(_onAddService);
    on<UpdateService>(_onUpdateService);
    on<ToggleAvailability>(_onToggleAvailability);
    on<DeleteService>(_onDeleteService);
    on<FilterServicesByCategory>(_onFilterServicesByCategory);
  }

  PartnerModel get _currentPartner {
    final authState = _authBloc.state;
    if (authState.status == AuthBlocStatus.authenticated &&
        authState.partner != null) {
      return authState.partner!;
    }
    throw Exception('User is not authenticated');
  }

  List<String> _getCategories(PartnerType role) {
    final categories = _dropdownRepository.getServiceCategoriesForRole(role);
    return ['All', ...categories];
  }

  Future<void> _onLoadServices(
      LoadServices event, Emitter<ServicesState> emit) async {
    emit(state.copyWith(status: ServicesStatus.loading, errorMessage: null));
    try {
      final services = await _serviceRepository.fetchServices();
      final categories = _getCategories(event.role);

      // Update local AuthBloc with the loaded services
      final updatedPartner = _currentPartner.copyWith(services: services);
      _authBloc.add(PartnerUpdated(updatedPartner));

      emit(state.copyWith(
        status: ServicesStatus.loaded,
        allServices: services,
        filteredServices: services,
        selectedCategory: 'All',
        categories: categories,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddService(
      AddService event, Emitter<ServicesState> emit) async {
    if (state.status != ServicesStatus.loaded) return;
    final savedState = state;

    emit(state.copyWith(status: ServicesStatus.loading));
    try {
      // 1. Add via repository
      final addedService = await _serviceRepository.addService(event.service);

      // 2. Prepare updated list
      final updatedServices =
          List<ServiceModel>.from(savedState.allServices)..add(addedService);

      // 3. Update AuthBloc
      final partner = _currentPartner.copyWith(services: updatedServices);
      _authBloc.add(PartnerUpdated(partner));

      // 4. Apply filtering and emit loaded state
      final categories = _getCategories(partner.role);
      emit(state.copyWith(
        status: ServicesStatus.loaded,
        allServices: updatedServices,
        filteredServices:
            _applyFilter(updatedServices, savedState.selectedCategory),
        selectedCategory: savedState.selectedCategory,
        categories: categories,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to add service: $e',
      ));
      // Restore previous state after failure
      emit(savedState);
    }
  }

  Future<void> _onUpdateService(
      UpdateService event, Emitter<ServicesState> emit) async {
    if (state.status != ServicesStatus.loaded) return;
    final savedState = state;

    emit(state.copyWith(status: ServicesStatus.loading));
    try {
      // 1. Update via repository
      final updatedService = await _serviceRepository.editService(event.service);

      // 2. Prepare updated list
      final updatedServices = savedState.allServices.map((e) {
        return e.id == updatedService.id ? updatedService : e;
      }).toList();

      // 3. Update AuthBloc
      final partner = _currentPartner.copyWith(services: updatedServices);
      _authBloc.add(PartnerUpdated(partner));

      // 4. Apply filtering and emit loaded state
      final categories = _getCategories(partner.role);
      emit(state.copyWith(
        status: ServicesStatus.loaded,
        allServices: updatedServices,
        filteredServices:
            _applyFilter(updatedServices, savedState.selectedCategory),
        selectedCategory: savedState.selectedCategory,
        categories: categories,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to update service: $e',
      ));
      emit(savedState);
    }
  }

  Future<void> _onToggleAvailability(
      ToggleAvailability event, Emitter<ServicesState> emit) async {
    if (state.status != ServicesStatus.loaded) return;
    final savedState = state;

    emit(state.copyWith(status: ServicesStatus.loading));
    try {
      // 1. Toggle via repository
      final updatedService = await _serviceRepository.toggleAvailability(
          event.id, event.isAvailable);

      // 2. Prepare updated list
      final updatedServices = savedState.allServices.map((e) {
        return e.id == updatedService.id ? updatedService : e;
      }).toList();

      // 3. Update AuthBloc
      final partner = _currentPartner.copyWith(services: updatedServices);
      _authBloc.add(PartnerUpdated(partner));

      // 4. Apply filtering and emit loaded state
      final categories = _getCategories(partner.role);
      emit(state.copyWith(
        status: ServicesStatus.loaded,
        allServices: updatedServices,
        filteredServices:
            _applyFilter(updatedServices, savedState.selectedCategory),
        selectedCategory: savedState.selectedCategory,
        categories: categories,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to toggle availability: $e',
      ));
      emit(savedState);
    }
  }

  Future<void> _onDeleteService(
      DeleteService event, Emitter<ServicesState> emit) async {
    if (state.status != ServicesStatus.loaded) return;
    final savedState = state;

    emit(state.copyWith(status: ServicesStatus.loading));
    try {
      // 1. Delete via repository
      await _serviceRepository.deleteService(event.id);

      // 2. Prepare updated list
      final updatedServices =
          savedState.allServices.where((e) => e.id != event.id).toList();

      // 3. Update AuthBloc
      final partner = _currentPartner.copyWith(services: updatedServices);
      _authBloc.add(PartnerUpdated(partner));

      // 4. Apply filtering and emit loaded state
      final categories = _getCategories(partner.role);
      emit(state.copyWith(
        status: ServicesStatus.loaded,
        allServices: updatedServices,
        filteredServices:
            _applyFilter(updatedServices, savedState.selectedCategory),
        selectedCategory: savedState.selectedCategory,
        categories: categories,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to delete service: $e',
      ));
      emit(savedState);
    }
  }

  void _onFilterServicesByCategory(
      FilterServicesByCategory event, Emitter<ServicesState> emit) {
    if (state.status != ServicesStatus.loaded) return;

    emit(state.copyWith(
      filteredServices: _applyFilter(state.allServices, event.category),
      selectedCategory: event.category,
    ));
  }

  List<ServiceModel> _applyFilter(List<ServiceModel> services, String category) {
    if (category == 'All') {
      return services;
    }
    return services
        .where((element) =>
            element.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}
