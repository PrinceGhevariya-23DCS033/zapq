class ReviewModel {
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final double rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bookingId; // Reference to the completed booking

  ReviewModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.bookingId,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      bookingId: json['bookingId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bookingId': bookingId,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? customerEmail,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bookingId,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookingId: bookingId ?? this.bookingId,
    );
  }

  @override
  String toString() {
    return 'ReviewModel(id: $id, businessId: $businessId, customerId: $customerId, rating: $rating, comment: $comment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}