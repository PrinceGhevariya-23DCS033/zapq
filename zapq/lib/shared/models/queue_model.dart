class QueueModel {
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final int position;
  final String status; // 'waiting', 'active', 'completed', 'cancelled'
  final DateTime bookedAt;
  final DateTime? servicedAt;
  final DateTime? completedAt;
  final String? notes;
  final int estimatedWaitTimeMinutes;

  QueueModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.position,
    required this.status,
    required this.bookedAt,
    this.servicedAt,
    this.completedAt,
    this.notes,
    this.estimatedWaitTimeMinutes = 0,
  });

  factory QueueModel.fromJson(Map<String, dynamic> json) {
    return QueueModel(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      position: json['position'] ?? 0,
      status: json['status'] ?? 'waiting',
      bookedAt: DateTime.parse(json['bookedAt'] ?? DateTime.now().toIso8601String()),
      servicedAt: json['servicedAt'] != null ? DateTime.parse(json['servicedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      notes: json['notes'],
      estimatedWaitTimeMinutes: json['estimatedWaitTimeMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'position': position,
      'status': status,
      'bookedAt': bookedAt.toIso8601String(),
      'servicedAt': servicedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'estimatedWaitTimeMinutes': estimatedWaitTimeMinutes,
    };
  }

  QueueModel copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    int? position,
    String? status,
    DateTime? bookedAt,
    DateTime? servicedAt,
    DateTime? completedAt,
    String? notes,
    int? estimatedWaitTimeMinutes,
  }) {
    return QueueModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      position: position ?? this.position,
      status: status ?? this.status,
      bookedAt: bookedAt ?? this.bookedAt,
      servicedAt: servicedAt ?? this.servicedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      estimatedWaitTimeMinutes: estimatedWaitTimeMinutes ?? this.estimatedWaitTimeMinutes,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  String get formattedEstimatedWaitTime {
    final hours = estimatedWaitTimeMinutes ~/ 60;
    final minutes = estimatedWaitTimeMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
