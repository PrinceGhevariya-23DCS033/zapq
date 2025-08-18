class AppConstants {
  // App Info
  static const String appName = 'ZapQ';
  static const String appTagline = 'Smart Virtual Queue & Shop Management';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String businessesCollection = 'businesses';
  static const String queuesCollection = 'queues';
  static const String bookingsCollection = 'bookings';
  static const String feedbackCollection = 'feedback';
  static const String notificationsCollection = 'notifications';

  // User Types
  static const String customerUserType = 'customer';
  static const String businessOwnerUserType = 'business_owner';

  // Queue Status
  static const String queueStatusActive = 'active';
  static const String queueStatusWaiting = 'waiting';
  static const String queueStatusCompleted = 'completed';
  static const String queueStatusCancelled = 'cancelled';

  // Business Categories
  static const List<String> businessCategories = [
    'Restaurant',
    'Clinic',
    'Bank',
    'Government Office',
    'Salon & Spa',
    'Retail Store',
    'Service Center',
    'Educational Institution',
    'Entertainment',
    'Other'
  ];

  // Notification Types
  static const String notificationTypeBookingConfirmed = 'booking_confirmed';
  static const String notificationTypeTurnNear = 'turn_near';
  static const String notificationTypeTurnReady = 'turn_ready';
  static const String notificationTypeBookingCancelled = 'booking_cancelled';
  static const String notificationTypeQueueUpdate = 'queue_update';

  // Map Settings
  static const double defaultZoom = 14.0;
  static const double markerZoom = 16.0;
  static const int searchRadius = 5000; // meters

  // Queue Settings
  static const int defaultMaxCustomersPerDay = 50;
  static const int defaultServiceTimeMinutes = 15;
  static const int turnNearThreshold = 3; // positions before user's turn

  // Validation
  static const int minPasswordLength = 6;
  static const int maxBusinessNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxFeedbackLength = 300;
}
