import 'package:flutter_bloc/flutter_bloc.dart';
import 'services_event.dart';
import 'services_state.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/repositories/service_repo.dart';
import '../../../data/repositories/profile_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/bloc/auth_event.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository _serviceRepository;
  final ProfileRepository _profileRepository;
  final AuthBloc _authBloc;

  ServicesBloc({
    required ServiceRepository serviceRepository,
    required ProfileRepository profileRepository,
    required AuthBloc authBloc,
  })  : _serviceRepository = serviceRepository,
        _profileRepository = profileRepository,
        _authBloc = authBloc,
        super(ServicesInitial()) {
    on<LoadServices>(_onLoadServices);
    on<AddService>(_onAddService);
    on<UpdateService>(_onUpdateService);
    on<ToggleAvailability>(_onToggleAvailability);
    on<DeleteService>(_onDeleteService);
    on<FilterServicesByCategory>(_onFilterServicesByCategory);
  }

  PartnerModel get _currentPartner {
    final state = _authBloc.state;
    if (state is AuthSuccess) {
      return state.partner;
    }
    throw Exception('User is not authenticated');
  }

  List<String> _getMockCategories(PartnerType role) {
    if (role == PartnerType.laboratory) {
      return [
        'All',
        'Blood Test',
        'Pathology',
        'Urine Test',
        'Biochemistry',
        'Hematology',
        'Immunology',
        'Hormone Test',
        'Microbiology'
      ];
    } else if (role == PartnerType.imagingCenter) {
      return [
        'All',
        'X-Ray',
        'CT Scan',
        'MRI',
        'Ultrasound',
        'PET Scan',
        'Mammography',
        'DEXA Scan',
        'Echocardiography'
      ];
    }
    return ['All'];
  }

  Future<void> _onLoadServices(LoadServices event, Emitter<ServicesState> emit) async {
    emit(ServicesLoading());
    try {
      final services = await _serviceRepository.fetchServices(
        partnerId: event.partnerId,
        role: event.role,
      );
      final categories = _getMockCategories(event.role);
      emit(ServicesLoaded(
        allServices: services,
        filteredServices: services,
        selectedCategory: 'All',
        categories: categories,
      ));
    } catch (e) {
      emit(ServicesFailure(e.toString()));
    }
  }

  Future<void> _onAddService(AddService event, Emitter<ServicesState> emit) async {
    final currentState = state;
    if (currentState is! ServicesLoaded) return;

    emit(ServicesLoading());
    try {
      // 1. Add via repository
      final addedService = await _serviceRepository.addService(event.service);
      
      // 2. Prepare updated list
      final updatedServices = List<ServiceModel>.from(currentState.allServices)..add(addedService);
      
      // 3. Call saveProfile API to sync services in profile endpoint
      final partner = _currentPartner.copyWith(services: updatedServices);
      final savedPartner = await _profileRepository.saveProfile(partner);
      
      // 4. Update AuthBloc
      _authBloc.add(PartnerUpdated(savedPartner));

      // 5. Apply filtering and emit loaded state
      final categories = _getMockCategories(partner.role);
      emit(ServicesLoaded(
        allServices: updatedServices,
        filteredServices: _applyFilter(updatedServices, currentState.selectedCategory),
        selectedCategory: currentState.selectedCategory,
        categories: categories,
      ));
    } catch (e) {
      emit(ServicesFailure('Failed to add service: $e'));
      // Emit the previous state after failure to let the user retry
      emit(currentState);
    }
  }

  Future<void> _onUpdateService(UpdateService event, Emitter<ServicesState> emit) async {
    final currentState = state;
    if (currentState is! ServicesLoaded) return;

    emit(ServicesLoading());
    try {
      // 1. Update via repository
      final updatedService = await _serviceRepository.editService(event.service);
      
      // 2. Prepare updated list
      final updatedServices = currentState.allServices.map((e) {
        return e.id == updatedService.id ? updatedService : e;
      }).toList();

      // 3. Call saveProfile API to sync services in profile endpoint
      final partner = _currentPartner.copyWith(services: updatedServices);
      final savedPartner = await _profileRepository.saveProfile(partner);
      
      // 4. Update AuthBloc
      _authBloc.add(PartnerUpdated(savedPartner));

      // 5. Apply filtering and emit loaded state
      final categories = _getMockCategories(partner.role);
      emit(ServicesLoaded(
        allServices: updatedServices,
        filteredServices: _applyFilter(updatedServices, currentState.selectedCategory),
        selectedCategory: currentState.selectedCategory,
        categories: categories,
      ));
    } catch (e) {
      emit(ServicesFailure('Failed to update service: $e'));
      emit(currentState);
    }
  }

  Future<void> _onToggleAvailability(ToggleAvailability event, Emitter<ServicesState> emit) async {
    final currentState = state;
    if (currentState is! ServicesLoaded) return;

    emit(ServicesLoading());
    try {
      // 1. Toggle via repository
      final updatedService = await _serviceRepository.toggleAvailability(event.id, event.isAvailable);
      
      // 2. Prepare updated list
      final updatedServices = currentState.allServices.map((e) {
        return e.id == updatedService.id ? updatedService : e;
      }).toList();

      // 3. Call saveProfile API to sync services in profile endpoint
      final partner = _currentPartner.copyWith(services: updatedServices);
      final savedPartner = await _profileRepository.saveProfile(partner);
      
      // 4. Update AuthBloc
      _authBloc.add(PartnerUpdated(savedPartner));

      // 5. Apply filtering and emit loaded state
      final categories = _getMockCategories(partner.role);
      emit(ServicesLoaded(
        allServices: updatedServices,
        filteredServices: _applyFilter(updatedServices, currentState.selectedCategory),
        selectedCategory: currentState.selectedCategory,
        categories: categories,
      ));
    } catch (e) {
      emit(ServicesFailure('Failed to toggle availability: $e'));
      emit(currentState);
    }
  }

  Future<void> _onDeleteService(DeleteService event, Emitter<ServicesState> emit) async {
    final currentState = state;
    if (currentState is! ServicesLoaded) return;

    emit(ServicesLoading());
    try {
      // 1. Delete via repository
      await _serviceRepository.deleteService(event.id);
      
      // 2. Prepare updated list
      final updatedServices = currentState.allServices.where((e) => e.id != event.id).toList();

      // 3. Call saveProfile API to sync services in profile endpoint
      final partner = _currentPartner.copyWith(services: updatedServices);
      final savedPartner = await _profileRepository.saveProfile(partner);
      
      // 4. Update AuthBloc
      _authBloc.add(PartnerUpdated(savedPartner));

      // 5. Apply filtering and emit loaded state
      final categories = _getMockCategories(partner.role);
      emit(ServicesLoaded(
        allServices: updatedServices,
        filteredServices: _applyFilter(updatedServices, currentState.selectedCategory),
        selectedCategory: currentState.selectedCategory,
        categories: categories,
      ));
    } catch (e) {
      emit(ServicesFailure('Failed to delete service: $e'));
      emit(currentState);
    }
  }

  void _onFilterServicesByCategory(FilterServicesByCategory event, Emitter<ServicesState> emit) {
    final currentState = state;
    if (currentState is! ServicesLoaded) return;

    emit(ServicesLoaded(
      allServices: currentState.allServices,
      filteredServices: _applyFilter(currentState.allServices, event.category),
      selectedCategory: event.category,
      categories: currentState.categories,
    ));
  }

  List<ServiceModel> _applyFilter(List<ServiceModel> services, String category) {
    if (category == 'All') {
      return services;
    }
    return services.where((element) => element.category.toLowerCase() == category.toLowerCase()).toList();
  }
}
