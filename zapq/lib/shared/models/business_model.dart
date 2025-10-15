class BusinessModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final String address;
  final String phoneNumber;
  final String? email;
  final List<String> imageUrls;
  final List<String> galleryUrls; // Additional photo gallery
  final String? profileImageUrl; // Main business profile image
  final Map<String, String> operatingHours; // day: "09:00-18:00"
  final int maxCustomersPerDay;
  final int averageServiceTimeMinutes;
  final bool isActive;
  final double rating;
  final int totalRatings;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional properties for enhanced functionality
  final List<ServiceModel> services;
  final BusinessHours businessHours;

  BusinessModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.phoneNumber,
    this.email,
    this.imageUrls = const [],
    this.galleryUrls = const [],
    this.profileImageUrl,
    this.operatingHours = const {},
    this.maxCustomersPerDay = 50,
    this.averageServiceTimeMinutes = 15,
    this.isActive = true,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.services = const [],
    BusinessHours? businessHours,
  }) : businessHours = businessHours ?? BusinessHours.defaultHours();

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      galleryUrls: List<String>.from(json['galleryUrls'] ?? []),
      profileImageUrl: json['profileImageUrl'],
      operatingHours: Map<String, String>.from(json['operatingHours'] ?? {}),
      maxCustomersPerDay: json['maxCustomersPerDay'] ?? 50,
      averageServiceTimeMinutes: json['averageServiceTimeMinutes'] ?? 15,
      isActive: json['isActive'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => ServiceModel.fromJson(e))
          .toList() ?? [],
      businessHours: json['businessHours'] != null
          ? BusinessHours.fromJson(json['businessHours'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'imageUrls': imageUrls,
      'galleryUrls': galleryUrls,
      'profileImageUrl': profileImageUrl,
      'operatingHours': operatingHours,
      'maxCustomersPerDay': maxCustomersPerDay,
      'averageServiceTimeMinutes': averageServiceTimeMinutes,
      'isActive': isActive,
      'rating': rating,
      'totalRatings': totalRatings,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'services': services.map((service) => service.toJson()).toList(),
      'businessHours': businessHours.toJson(),
    };
  }

  BusinessModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? category,
    String? address,
    String? phoneNumber,
    String? email,
    List<String>? imageUrls,
    List<String>? galleryUrls,
    String? profileImageUrl,
    Map<String, String>? operatingHours,
    int? maxCustomersPerDay,
    int? averageServiceTimeMinutes,
    bool? isActive,
    double? rating,
    int? totalRatings,
    int? reviewCount,
    List<ServiceModel>? services,
    BusinessHours? businessHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      imageUrls: imageUrls ?? this.imageUrls,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      operatingHours: operatingHours ?? this.operatingHours,
      maxCustomersPerDay: maxCustomersPerDay ?? this.maxCustomersPerDay,
      averageServiceTimeMinutes: averageServiceTimeMinutes ?? this.averageServiceTimeMinutes,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      reviewCount: reviewCount ?? this.reviewCount,
      services: services ?? this.services,
      businessHours: businessHours ?? this.businessHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedRating => rating.toStringAsFixed(1);
  
  bool get hasImages => imageUrls.isNotEmpty;
  
  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}

// Service Model for business services
class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final int maxCapacity;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    this.maxCapacity = 1,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      durationMinutes: json['durationMinutes'] ?? 15,
      maxCapacity: json['maxCapacity'] ?? 1,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'maxCapacity': maxCapacity,
      'isActive': isActive,
    };
  }
}

// Business Hours Model
class BusinessHours {
  final Map<String, DayHours> hours;

  BusinessHours({required this.hours});

  static BusinessHours defaultHours() {
    return BusinessHours(
      hours: {
        'monday': DayHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'tuesday': DayHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'wednesday': DayHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'thursday': DayHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'friday': DayHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'saturday': DayHours(isOpen: true, openTime: '10:00', closeTime: '16:00'),
        'sunday': DayHours(isOpen: false, openTime: '00:00', closeTime: '00:00'),
      },
    );
  }

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    Map<String, DayHours> hours = {};
    json.forEach((key, value) {
      hours[key] = DayHours.fromJson(value);
    });
    return BusinessHours(hours: hours);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    hours.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }
}

// Day Hours Model
class DayHours {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  DayHours({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  factory DayHours.fromJson(Map<String, dynamic> json) {
    return DayHours(
      isOpen: json['isOpen'] ?? false,
      openTime: json['openTime'] ?? '00:00',
      closeTime: json['closeTime'] ?? '00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }
}
