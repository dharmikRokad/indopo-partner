enum PartnerType {
  doctor,
  medical,
  laboratory,
  imagingCenter,
}

extension PartnerTypeExtension on PartnerType {
  String get key {
    switch (this) {
      case PartnerType.doctor:
        return 'doctor';
      case PartnerType.medical:
        return 'medical';
      case PartnerType.laboratory:
        return 'laboratory';
      case PartnerType.imagingCenter:
        return 'imaging_center';
    }
  }

  static PartnerType fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'doctor':
        return PartnerType.doctor;
      case 'medical':
        return PartnerType.medical;
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
      case PartnerType.medical:
        return 'Medical';
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
      case PartnerType.medical:
        return '💊';
      case PartnerType.laboratory:
        return '🧪';
      case PartnerType.imagingCenter:
        return '🏥';
    }
  }
}
