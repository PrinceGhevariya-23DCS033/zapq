import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/business_model.dart';
import '../models/time_slot_model.dart';

class BookingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<BookingModel> _userBookings = [];
  List<BookingModel> _businessBookings = [];
  List<TimeSlotModel> _availableSlots = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get userBookings => _userBookings;
  List<BookingModel> get businessBookings => _businessBookings;
  List<BookingModel> get todayBookings => _businessBookings
      .where((booking) => _isToday(booking.appointmentDate))
      .toList();
  List<TimeSlotModel> get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Helper method to check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> loadTodayBookings() async {
    _setLoading(true);
    try {
      print('🔍 Loading today\'s bookings...');
      
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        throw Exception('User not logged in');
      }

      print('📧 Current user: ${user.uid}');

      // First, get the user's business to find the business ID
      final businessSnapshot = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      if (businessSnapshot.docs.isEmpty) {
        print('📝 No business found for this user');
        _businessBookings = [];
        notifyListeners();
        return;
      }

      final businessId = businessSnapshot.docs.first.id;
      print('🏢 Business ID: $businessId');

      // Now get bookings for this business
      print('📅 Loading bookings for business: $businessId');

      // Simplified query to avoid index requirement
      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Filter locally for today's bookings
      _businessBookings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        return BookingModel.fromJson(data);
      }).where((booking) {
        return booking.appointmentDate.isAfter(startOfDay) && 
               booking.appointmentDate.isBefore(endOfDay);
      }).toList();

      print('✅ Loaded ${_businessBookings.length} bookings for today');
      
      // Sort today's bookings by appointment time for daily schedule
      _businessBookings.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      notifyListeners();
    } catch (e) {
      print('❌ Error loading today\'s bookings: $e');
      _setError('Failed to load today\'s bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    try {
      _setLoading(true);
      _setError(null);

      print('🔄 Updating booking $bookingId status to $newStatus');

      // Update in Firestore
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local state
      final bookingIndex = _businessBookings.indexWhere((b) => b.id == bookingId);
      if (bookingIndex != -1) {
        _businessBookings[bookingIndex] = _businessBookings[bookingIndex].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      // Also update in all bookings list
      final allBookingIndex = _userBookings.indexWhere((b) => b.id == bookingId);
      if (allBookingIndex != -1) {
        _userBookings[allBookingIndex] = _userBookings[allBookingIndex].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      print('✅ Booking status updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error updating booking status: $e');
      _setError('Failed to update booking status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create a new booking with automatic confirmation and improved capacity management
  Future<bool> createBooking(BookingModel booking) async {
    try {
      _setLoading(true);
      _setError(null);

      // Check slot availability with proper capacity management
      final slotData = await _checkSlotCapacityAndAvailability(
        booking.businessId,
        booking.serviceId,
        booking.appointmentDate,
        booking.timeSlot,
      );

      if (!slotData['isAvailable']) {
        _setError(slotData['message'] ?? 'This time slot is no longer available.');
        return false;
      }

      // Create booking with automatic confirmation
      final confirmedBooking = booking.copyWith(
        status: BookingStatus.confirmed,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore and wait for completion
      await _firestore.collection('bookings').doc(booking.id).set(confirmedBooking.toJson());
      
      // Wait a brief moment to ensure Firestore consistency
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Add to local state
      _userBookings.add(confirmedBooking);
      
      // Get updated capacity information after booking creation
      final updatedSlotData = await _checkSlotCapacityAndAvailability(
        booking.businessId,
        booking.serviceId,
        booking.appointmentDate,
        booking.timeSlot,
      );
      
      print('✅ Booking created and automatically confirmed: ${booking.id}');
      print('📊 Slot capacity after booking: ${updatedSlotData['currentBookings']}/${updatedSlotData['maxCapacity']}');
      return true;
    } catch (e) {
      print('❌ Error creating booking: $e');
      _setError('Failed to create booking. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Enhanced slot availability check with capacity information
  Future<Map<String, dynamic>> _checkSlotCapacityAndAvailability(
    String businessId,
    String serviceId,
    DateTime date,
    String timeSlot,
  ) async {
    try {
      // Get all bookings for this specific slot with document ID
      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .where('serviceId', isEqualTo: serviceId)
          .where('appointmentDate', isEqualTo: date.toIso8601String().split('T')[0])
          .where('timeSlot', isEqualTo: timeSlot)
          .get();

      // Count active bookings (exclude cancelled and no-show) and include document ID
      final activeBookings = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Add document ID to the data
            return BookingModel.fromJson(data);
          })
          .where((booking) => 
              booking.status != BookingStatus.cancelled && 
              booking.status != BookingStatus.noShow)
          .length;

      // Get service capacity
      final BusinessModel? business = await _getBusinessById(businessId);
      if (business == null) {
        return {
          'isAvailable': false,
          'message': 'Business not found',
          'currentBookings': 0,
          'maxCapacity': 0,
        };
      }

      final service = business.services.firstWhere(
        (s) => s.id == serviceId,
        orElse: () => ServiceModel(
          id: '',
          name: '',
          description: '',
          price: 0,
          durationMinutes: 0,
          maxCapacity: 1,
          isActive: false,
        ),
      );

      final maxCapacity = service.maxCapacity;
      final isAvailable = activeBookings < maxCapacity;
      
      String message = '';
      if (!isAvailable) {
        message = 'This time slot is full ($activeBookings/$maxCapacity). Please select another time.';
      }

      print('📊 Slot Capacity Check: $activeBookings/$maxCapacity (Available: $isAvailable)');

      return {
        'isAvailable': isAvailable,
        'message': message,
        'currentBookings': activeBookings,
        'maxCapacity': maxCapacity,
      };
    } catch (e) {
      print('❌ Error checking slot capacity: $e');
      return {
        'isAvailable': false,
        'message': 'Error checking availability',
        'currentBookings': 0,
        'maxCapacity': 0,
      };
    }
  }

  // Check if a time slot is available (simplified wrapper)
  Future<bool> _checkSlotAvailability(
    String businessId,
    String serviceId,
    DateTime date,
    String timeSlot,
  ) async {
    final result = await _checkSlotCapacityAndAvailability(businessId, serviceId, date, timeSlot);
    return result['isAvailable'] ?? false;
  }

  // Public method to check slot availability
  Future<bool> isSlotAvailable(
    String businessId,
    String serviceId,
    DateTime date,
    String timeSlot,
  ) async {
    return await _checkSlotAvailability(businessId, serviceId, date, timeSlot);
  }

  // Get slot capacity information
  Future<Map<String, dynamic>> getSlotCapacity(
    String businessId,
    String serviceId,
    DateTime date,
    String timeSlot,
  ) async {
    return await _checkSlotCapacityAndAvailability(businessId, serviceId, date, timeSlot);
  }

  // Get business by ID
  Future<BusinessModel?> _getBusinessById(String businessId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return BusinessModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting business: $e');
      return null;
    }
  }

  // Get user bookings
  Future<void> getUserBookings(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simplified query without orderBy to avoid needing composite index
      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .get();

      _userBookings = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return BookingModel.fromJson(data);
          })
          .toList();

      // Sort in memory instead of requiring Firestore index
      _userBookings.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      print('✅ Loaded ${_userBookings.length} bookings for user: $userId');
    } catch (e) {
      print('❌ Error loading user bookings: $e');
      _setError('Failed to load your bookings. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Get business bookings
  Future<void> getBusinessBookings(String businessId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simplified query without orderBy to avoid needing composite index
      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      _businessBookings = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return BookingModel.fromJson(data);
          })
          .toList();

      // Sort in memory instead of requiring Firestore index
      _businessBookings.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      print('✅ Loaded ${_businessBookings.length} bookings for business: $businessId');
    } catch (e) {
      print('❌ Error loading business bookings: $e');
      _setError('Failed to load business bookings. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }
}
