class BookingModel {
  final String id;
  final String customerId;
  final String businessId;
  final String serviceId;
  final DateTime appointmentDate;
  final String timeSlot;
  final BookingStatus status;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional properties for enhanced functionality
  final String? customerName;
  final String? serviceName;
  final String? businessName;
  final String? businessAddress;
  final DateTime? bookingTime;
  final String? customerPhone;
  final String? customerEmail;
  final int? queueNumber;
  final String? appointmentSlot;
  final double? servicePrice;
  final int? estimatedDuration;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.businessId,
    required this.serviceId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.serviceName,
    this.businessName,
    this.businessAddress,
    this.bookingTime,
    this.customerPhone,
    this.customerEmail,
    this.queueNumber,
    this.appointmentSlot,
    this.servicePrice,
    this.estimatedDuration,
  });

  BookingModel copyWith({
    String? id,
    String? customerId,
    String? businessId,
    String? serviceId,
    DateTime? appointmentDate,
    String? timeSlot,
    BookingStatus? status,
    double? totalPrice,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? serviceName,
    String? businessName,
    String? businessAddress,
    DateTime? bookingTime,
    String? customerPhone,
    String? customerEmail,
    int? queueNumber,
    String? appointmentSlot,
    double? servicePrice,
    int? estimatedDuration,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      businessId: businessId ?? this.businessId,
      serviceId: serviceId ?? this.serviceId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      serviceName: serviceName ?? this.serviceName,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      bookingTime: bookingTime ?? this.bookingTime,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      queueNumber: queueNumber ?? this.queueNumber,
      appointmentSlot: appointmentSlot ?? this.appointmentSlot,
      servicePrice: servicePrice ?? this.servicePrice,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'businessId': businessId,
      'serviceId': serviceId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status.name,
      'totalPrice': totalPrice,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'customerName': customerName,
      'serviceName': serviceName,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'bookingTime': bookingTime?.toIso8601String(),
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'queueNumber': queueNumber,
      'appointmentSlot': appointmentSlot,
      'servicePrice': servicePrice,
      'estimatedDuration': estimatedDuration,
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      customerId: json['customerId'],
      businessId: json['businessId'],
      serviceId: json['serviceId'],
      appointmentDate: DateTime.parse(json['appointmentDate']),
      timeSlot: json['timeSlot'],
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      totalPrice: (json['totalPrice']).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      customerName: json['customerName'],
      serviceName: json['serviceName'],
      businessName: json['businessName'],
      businessAddress: json['businessAddress'],
      bookingTime: json['bookingTime'] != null 
          ? DateTime.parse(json['bookingTime'])
          : null,
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      queueNumber: json['queueNumber'],
      appointmentSlot: json['appointmentSlot'],
      servicePrice: json['servicePrice']?.toDouble(),
      estimatedDuration: json['estimatedDuration'],
    );
  }
}

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  String get color {
    switch (this) {
      case BookingStatus.pending:
        return '#FF9800';
      case BookingStatus.confirmed:
        return '#4CAF50';
      case BookingStatus.inProgress:
        return '#2196F3';
      case BookingStatus.completed:
        return '#8BC34A';
      case BookingStatus.cancelled:
        return '#F44336';
      case BookingStatus.noShow:
        return '#9E9E9E';
    }
  }
}
