enum PartnerType { doctor, pharmacy, laboratory, imagingCenter }

extension PartnerTypeExtension on PartnerType {
  String get key {
    switch (this) {
      case PartnerType.doctor:
        return 'doctor';
      case PartnerType.pharmacy:
        return 'pharmacy';
      case PartnerType.laboratory:
        return 'laboratory';
      case PartnerType.imagingCenter:
        return 'imaging_center';
    }
  }

  String get apiValue {
    switch (this) {
      case PartnerType.doctor:
        return 'DOCTOR';
      case PartnerType.pharmacy:
        return 'PHARMACY';
      case PartnerType.laboratory:
        return 'LABORATORY';
      case PartnerType.imagingCenter:
        return 'IMAGING_CENTER';
    }
  }

  static PartnerType fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'doctor':
        return PartnerType.doctor;
      case 'pharmacy':
        return PartnerType.pharmacy;
      case 'laboratory':
      case 'lab':
        return PartnerType.laboratory;
      case 'imaging_center':
      case 'imagingcenter':
      case 'imaging':
        return PartnerType.imagingCenter;
      default:
        return PartnerType.doctor;
    }
  }

  String get displayName {
    switch (this) {
      case PartnerType.doctor:
        return 'Doctor';
      case PartnerType.pharmacy:
        return 'Pharmacy';
      case PartnerType.laboratory:
        return 'Laboratory';
      case PartnerType.imagingCenter:
        return 'Imaging Center';
    }
  }

  String get icon {
    switch (this) {
      case PartnerType.doctor:
        return '🩺';
      case PartnerType.pharmacy:
        return '💊';
      case PartnerType.laboratory:
        return '🧪';
      case PartnerType.imagingCenter:
        return '🏥';
    }
  }
}
