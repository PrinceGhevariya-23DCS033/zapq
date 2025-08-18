import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/time_slot_model.dart';
import 'slot_provider.dart';

class BookingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SlotProvider _slotProvider = SlotProvider();
  
  List<BookingModel> _userBookings = [];
  List<BookingModel> _businessBookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get userBookings => _userBookings;
  List<BookingModel> get businessBookings => _businessBookings;
  List<BookingModel> get todayBookings => _businessBookings
      .where((booking) => _isToday(booking.appointmentDate))
      .toList();
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

  // Update booking status with slot management
  Future<bool> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    try {
      _setLoading(true);
      _setError(null);

      print('🔄 Updating booking $bookingId status to $newStatus');

      // Get the booking first to access slot information
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        _setError('Booking not found');
        return false;
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      bookingData['id'] = bookingDoc.id;
      final booking = BookingModel.fromJson(bookingData);

      // Handle slot release for cancellations
      if (newStatus == BookingStatus.cancelled || newStatus == BookingStatus.noShow) {
        final date = booking.appointmentDate.toIso8601String().split('T')[0];
        await _slotProvider.releaseSlot(
          booking.serviceId,
          date,
          booking.timeSlot,
          booking.id,
        );
        print('✅ Released slot for cancelled/no-show booking');
      }

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

  // Create a new booking with automatic confirmation using slot system
  Future<bool> createBooking(BookingModel booking) async {
    try {
      _setLoading(true);
      _setError(null);

      final date = booking.appointmentDate.toIso8601String().split('T')[0];
      
      print('🔄 Attempting to book slot: ${booking.serviceId}_${date}_${booking.timeSlot}');
      
      // Try to reserve the slot atomically
      final slotReserved = await _slotProvider.reserveSlot(
        booking.serviceId,
        date,
        booking.timeSlot,
        booking.id,
      );

      if (!slotReserved) {
        _setError('❌ This time slot is no longer available. Please select another time.');
        print('❌ Failed to reserve slot for booking: ${booking.id}');
        return false;
      }

      // Create booking with automatic confirmation
      final confirmedBooking = booking.copyWith(
        status: BookingStatus.confirmed,
        updatedAt: DateTime.now(),
      );

      // Save booking to Firestore
      await _firestore.collection('bookings').doc(booking.id).set(confirmedBooking.toJson());
      
      // Add to local state
      _userBookings.add(confirmedBooking);
      
      // Get updated capacity for logging
      final slotCapacity = await _slotProvider.getSlotCapacity(
        booking.serviceId,
        date,
        booking.timeSlot,
      );
      
      print('✅ Booking created and automatically confirmed: ${booking.id}');
      print('📊 Slot capacity: ${slotCapacity['currentBookings']}/${slotCapacity['maxCapacity']}');
      
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error creating booking: $e');
      _setError('Failed to create booking. Please try again.');
      
      // Try to release the slot if booking creation failed
      final date = booking.appointmentDate.toIso8601String().split('T')[0];
      await _slotProvider.releaseSlot(
        booking.serviceId,
        date,
        booking.timeSlot,
        booking.id,
      );
      
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Public method to check slot availability (delegates to SlotProvider)
  Future<bool> isSlotAvailable(
    String businessId,
    String serviceId,
    DateTime date,
    String timeSlot,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final capacity = await _slotProvider.getSlotCapacity(serviceId, dateStr, timeSlot);
    return capacity['isAvailable'] ?? false;
  }

  // Get slot capacity information (delegates to SlotProvider)
  Future<Map<String, dynamic>> getSlotCapacity(
    String businessId,
    String serviceId,
    DateTime date,
    String timeSlot,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await _slotProvider.getSlotCapacity(serviceId, dateStr, timeSlot);
  }

  // Initialize slots for a service (helper method)
  Future<void> initializeSlotsForService(
    String businessId,
    String serviceId,
    String date,
    int maxCapacity,
  ) async {
    await _slotProvider.initializeSlotsForService(businessId, serviceId, date, maxCapacity);
  }

  // Get available slots for a service on a date
  Future<List<TimeSlotModel>> getAvailableSlots(
    String serviceId,
    String date,
  ) async {
    return await _slotProvider.getAvailableSlots(serviceId, date);
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

      // Sort in memory: RECENT BOOKINGS FIRST (by creation date, then by appointment date)
      _businessBookings.sort((a, b) {
        // First sort by creation date (most recent first)
        final createdAtComparison = b.createdAt.compareTo(a.createdAt);
        if (createdAtComparison != 0) return createdAtComparison;
        
        // If created at same time, sort by appointment date (upcoming first)
        return a.appointmentDate.compareTo(b.appointmentDate);
      });

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
