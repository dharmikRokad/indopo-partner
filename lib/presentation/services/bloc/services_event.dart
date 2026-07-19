import '../../../data/models/service_model.dart';
import '../../../data/models/partner_type.dart';

abstract class ServicesEvent {
  const ServicesEvent();
}

class LoadServices extends ServicesEvent {
  final String partnerId;
  final PartnerType role;

  const LoadServices({required this.partnerId, required this.role});
}

class AddService extends ServicesEvent {
  final ServiceModel service;

  const AddService(this.service);
}

class UpdateService extends ServicesEvent {
  final ServiceModel service;

  const UpdateService(this.service);
}

class ToggleAvailability extends ServicesEvent {
  final String id;
  final bool isAvailable;

  const ToggleAvailability({required this.id, required this.isAvailable});
}

class DeleteService extends ServicesEvent {
  final String id;

  const DeleteService(this.id);
}

class FilterServicesByCategory extends ServicesEvent {
  final String category;

  const FilterServicesByCategory(this.category);
}
