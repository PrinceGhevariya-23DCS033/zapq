class OfferModel {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final String? posterUrl; // Image URL for the offer poster
  final double? discountPercentage;
  final double? originalPrice;
  final double? discountedPrice;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> terms; // Terms and conditions
  final String? category; // Type of offer (discount, buy-one-get-one, etc.)

  OfferModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    this.posterUrl,
    this.discountPercentage,
    this.originalPrice,
    this.discountedPrice,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.terms = const [],
    this.category,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['posterUrl'],
      discountPercentage: json['discountPercentage']?.toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      discountedPrice: json['discountedPrice']?.toDouble(),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().add(Duration(days: 30)).toIso8601String()),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      terms: List<String>.from(json['terms'] ?? []),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'discountPercentage': discountPercentage,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'terms': terms,
      'category': category,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isValid => isActive && !isExpired && DateTime.now().isAfter(startDate);

  OfferModel copyWith({
    String? id,
    String? businessId,
    String? title,
    String? description,
    String? posterUrl,
    double? discountPercentage,
    double? originalPrice,
    double? discountedPrice,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? terms,
    String? category,
  }) {
    return OfferModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      terms: terms ?? this.terms,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'OfferModel(id: $id, title: $title, businessId: $businessId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfferModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}