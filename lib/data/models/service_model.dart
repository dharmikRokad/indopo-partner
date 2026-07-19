class ServiceModel {
  final String id;
  final String partnerId;
  final String name;
  final String category;
  final String description;
  final String price;
  final bool isAvailable;
  final String createdAt;

  ServiceModel({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.isAvailable,
    required this.createdAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? partnerId,
    String? name,
    String? category,
    String? description,
    String? price,
    bool? isAvailable,
    String? createdAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
