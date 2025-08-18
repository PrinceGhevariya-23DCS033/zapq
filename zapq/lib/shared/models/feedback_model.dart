class FeedbackModel {
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final bool isVerified; // true if customer actually visited

  FeedbackModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.isVerified = false,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    double? rating,
    String? comment,
    DateTime? createdAt,
    bool? isVerified,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  String get formattedRating => rating.toStringAsFixed(1);
}
