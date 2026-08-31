enum LabDispatchStatus {
  pending('PENDING'),
  notified('NOTIFIED'),
  accepted('ACCEPTED'),
  timedOut('TIMED_OUT'),
  skipped('SKIPPED');

  final String value;
  const LabDispatchStatus(this.value);

  static LabDispatchStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'PENDING':
        return LabDispatchStatus.pending;
      case 'NOTIFIED':
        return LabDispatchStatus.notified;
      case 'ACCEPTED':
        return LabDispatchStatus.accepted;
      case 'TIMED_OUT':
        return LabDispatchStatus.timedOut;
      case 'SKIPPED':
        return LabDispatchStatus.skipped;
      default:
        return LabDispatchStatus.pending;
    }
  }
}

enum LabOrderStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  expired('EXPIRED'),
  cancelled('CANCELLED');

  final String value;
  const LabOrderStatus(this.value);

  static LabOrderStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'PENDING':
        return LabOrderStatus.pending;
      case 'ACCEPTED':
        return LabOrderStatus.accepted;
      case 'EXPIRED':
        return LabOrderStatus.expired;
      case 'CANCELLED':
        return LabOrderStatus.cancelled;
      default:
        return LabOrderStatus.pending;
    }
  }
}

class LabPackageBriefModel {
  final String id;
  final String? category;
  final List<String> tests;

  LabPackageBriefModel({
    required this.id,
    this.category,
    required this.tests,
  });

  factory LabPackageBriefModel.fromJson(Map<String, dynamic> json) {
    final rawTests = json['tests'] as List? ?? [];
    return LabPackageBriefModel(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString(),
      tests: rawTests.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'tests': tests,
    };
  }
}

class LabOrderItemModel {
  final String id;
  final String packageName;
  final double price;
  final int quantity;
  final LabPackageBriefModel? labPackage;

  LabOrderItemModel({
    required this.id,
    required this.packageName,
    required this.price,
    required this.quantity,
    this.labPackage,
  });

  double get itemTotal => price * quantity;

  factory LabOrderItemModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    return LabOrderItemModel(
      id: json['id']?.toString() ?? '',
      packageName: json['packageName']?.toString() ?? 'Lab Test Package',
      price: parsedPrice,
      quantity: (json['quantity'] as int?) ?? 1,
      labPackage: json['labPackage'] != null && json['labPackage'] is Map
          ? LabPackageBriefModel.fromJson(
              json['labPackage'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'price': price.toStringAsFixed(2),
      'quantity': quantity,
      'labPackage': labPackage?.toJson(),
    };
  }
}

class LabOrderPatientModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;

  LabOrderPatientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory LabOrderPatientModel.fromJson(Map<String, dynamic> json) {
    return LabOrderPatientModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
    };
  }
}

class LabOrderModel {
  final String id;
  final String patientName;
  final String patientPhone;
  final double? patientLat;
  final double? patientLong;
  final LabOrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LabOrderItemModel> items;
  final LabOrderPatientModel? patient;

  LabOrderModel({
    required this.id,
    required this.patientName,
    required this.patientPhone,
    this.patientLat,
    this.patientLong,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.patient,
  });

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.itemTotal);
  }

  String get itemsSummary {
    if (items.isEmpty) return 'No items';
    return items
        .map((i) => '${i.packageName} x${i.quantity}')
        .join(', ');
  }

  List<String> get allTests {
    final Set<String> testsSet = {};
    for (final item in items) {
      if (item.labPackage != null) {
        testsSet.addAll(item.labPackage!.tests);
      }
    }
    return testsSet.toList();
  }

  factory LabOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return LabOrderModel(
      id: json['id']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Patient',
      patientPhone: json['patientPhone']?.toString() ?? '',
      patientLat: json['patientLat'] != null
          ? double.tryParse(json['patientLat'].toString())
          : null,
      patientLong: json['patientLong'] != null
          ? double.tryParse(json['patientLong'].toString())
          : null,
      status: LabOrderStatus.fromString(json['status']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: rawItems
          .map((itemJson) =>
              LabOrderItemModel.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
      patient: json['patient'] != null && json['patient'] is Map
          ? LabOrderPatientModel.fromJson(
              json['patient'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'patientLat': patientLat,
      'patientLong': patientLong,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'patient': patient?.toJson(),
    };
  }
}

class LabDispatchModel {
  final String dispatchId;
  final LabDispatchStatus dispatchStatus;
  final DateTime? notifiedAt;
  final DateTime? respondedAt;
  final LabOrderModel order;

  LabDispatchModel({
    required this.dispatchId,
    required this.dispatchStatus,
    this.notifiedAt,
    this.respondedAt,
    required this.order,
  });

  /// Computes remaining seconds for the 5-minute (300 seconds) window based on [notifiedAt].
  int get remainingSeconds {
    if (notifiedAt == null) return 0;
    final expiresAt = notifiedAt!.add(const Duration(minutes: 5));
    final remainingMs = expiresAt.difference(DateTime.now()).inMilliseconds;
    return remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;
  }

  bool get isWindowActive {
    return dispatchStatus == LabDispatchStatus.notified &&
        order.status == LabOrderStatus.pending &&
        remainingSeconds > 0;
  }

  String get formattedRemainingTime {
    final sec = remainingSeconds;
    if (sec <= 0) return 'Expired';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory LabDispatchModel.fromJson(Map<String, dynamic> json) {
    return LabDispatchModel(
      dispatchId: json['dispatchId']?.toString() ?? '',
      dispatchStatus:
          LabDispatchStatus.fromString(json['dispatchStatus']?.toString()),
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.tryParse(json['notifiedAt'].toString())
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'].toString())
          : null,
      order: LabOrderModel.fromJson(
        (json['order'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dispatchId': dispatchId,
      'dispatchStatus': dispatchStatus.value,
      'notifiedAt': notifiedAt?.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'order': order.toJson(),
    };
  }
}
