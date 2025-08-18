class TimeSlotModel {
  final String id; // Format: "{serviceId}_{date}_{time}" e.g., "service123_2025-08-17_09:00"
  final String businessId;
  final String serviceId;
  final String date; // Format: "2025-08-17"
  final String time; // Format: "09:00"
  final int maxCapacity;
  final int currentBookings;
  final List<String> bookingIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeSlotModel({
    required this.id,
    required this.businessId,
    required this.serviceId,
    required this.date,
    required this.time,
    required this.maxCapacity,
    this.currentBookings = 0,
    this.bookingIds = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => currentBookings < maxCapacity && isActive;
  bool get isFull => currentBookings >= maxCapacity;
  int get availableSpots => maxCapacity - currentBookings;

  // Generate slot ID from components
  static String generateId(String serviceId, String date, String time) {
    return "${serviceId}_${date}_$time";
  }

  TimeSlotModel copyWith({
    String? id,
    String? businessId,
    String? serviceId,
    String? date,
    String? time,
    int? maxCapacity,
    int? currentBookings,
    List<String>? bookingIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      serviceId: serviceId ?? this.serviceId,
      date: date ?? this.date,
      time: time ?? this.time,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentBookings: currentBookings ?? this.currentBookings,
      bookingIds: bookingIds ?? this.bookingIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'serviceId': serviceId,
      'date': date,
      'time': time,
      'maxCapacity': maxCapacity,
      'currentBookings': currentBookings,
      'bookingIds': bookingIds,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      maxCapacity: json['maxCapacity'] ?? 1,
      currentBookings: json['currentBookings'] ?? 0,
      bookingIds: List<String>.from(json['bookingIds'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'TimeSlot($time: $currentBookings/$maxCapacity)';
  }
}
