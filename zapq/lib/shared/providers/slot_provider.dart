import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/time_slot_model.dart';

class SlotProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<TimeSlotModel> _availableSlots = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TimeSlotModel> get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Generate time slots for a day (e.g., 09:00, 09:30, 10:00, etc.)
  List<String> _generateTimeSlots() {
    final List<String> slots = [];
    for (int hour = 9; hour <= 18; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      if (hour < 18) {
        slots.add('${hour.toString().padLeft(2, '0')}:30');
      }
    }
    return slots;
  }

  // Initialize slots for a service on a specific date
  Future<void> initializeSlotsForService(
    String businessId,
    String serviceId,
    String date,
    int maxCapacity,
  ) async {
    try {
      final timeSlots = _generateTimeSlots();
      final batch = _firestore.batch();

      for (String time in timeSlots) {
        final slotId = TimeSlotModel.generateId(serviceId, date, time);
        final slotRef = _firestore.collection('timeSlots').doc(slotId);

        // Check if slot already exists
        final existingSlot = await slotRef.get();
        if (!existingSlot.exists) {
          final newSlot = TimeSlotModel(
            id: slotId,
            businessId: businessId,
            serviceId: serviceId,
            date: date,
            time: time,
            maxCapacity: maxCapacity,
            currentBookings: 0,
            bookingIds: [],
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          batch.set(slotRef, newSlot.toJson());
        }
      }

      await batch.commit();
      print('✅ Initialized slots for service $serviceId on $date');
    } catch (e) {
      print('❌ Error initializing slots: $e');
      _setError('Failed to initialize slots');
    }
  }

  // Get available slots for a service on a specific date
  Future<List<TimeSlotModel>> getAvailableSlots(
    String serviceId,
    String date,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      final QuerySnapshot snapshot = await _firestore
          .collection('timeSlots')
          .where('serviceId', isEqualTo: serviceId)
          .where('date', isEqualTo: date)
          .where('isActive', isEqualTo: true)
          .get();

      _availableSlots = snapshot.docs
          .map((doc) => TimeSlotModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((slot) => slot.isAvailable) // Only return available slots
          .toList();

      // Sort by time
      _availableSlots.sort((a, b) => a.time.compareTo(b.time));

      print('✅ Loaded ${_availableSlots.length} available slots for $serviceId on $date');
      notifyListeners();
      return _availableSlots;
    } catch (e) {
      print('❌ Error loading available slots: $e');
      _setError('Failed to load available slots');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Reserve a slot atomically (used during booking)
  Future<bool> reserveSlot(
    String serviceId,
    String date,
    String time,
    String bookingId,
  ) async {
    try {
      final slotId = TimeSlotModel.generateId(serviceId, date, time);
      final slotRef = _firestore.collection('timeSlots').doc(slotId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final slotDoc = await transaction.get(slotRef);
        
        if (!slotDoc.exists) {
          print('❌ Slot does not exist: $slotId');
          return false;
        }

        final slot = TimeSlotModel.fromJson(slotDoc.data() as Map<String, dynamic>);
        
        // Check if slot is active
        if (!slot.isActive) {
          print('❌ Slot is not active: $slotId');
          return false;
        }
        
        // Check if slot is already at capacity (critical check)
        if (slot.currentBookings >= slot.maxCapacity) {
          print('❌ Slot is full: ${slot.currentBookings}/${slot.maxCapacity} for $slotId');
          return false;
        }
        
        // Check if this booking ID is already in the slot (prevent duplicates)
        if (slot.bookingIds.contains(bookingId)) {
          print('❌ Booking already exists in slot: $bookingId in $slotId');
          return false;
        }

        // Reserve the slot
        final updatedBookingIds = List<String>.from(slot.bookingIds)..add(bookingId);
        final updatedSlot = slot.copyWith(
          currentBookings: slot.currentBookings + 1,
          bookingIds: updatedBookingIds,
          updatedAt: DateTime.now(),
        );

        // Final safety check before update
        if (updatedSlot.currentBookings > updatedSlot.maxCapacity) {
          print('❌ Would exceed capacity: ${updatedSlot.currentBookings}/${updatedSlot.maxCapacity} for $slotId');
          return false;
        }

        transaction.update(slotRef, updatedSlot.toJson());
        
        print('✅ Reserved slot $slotId: ${updatedSlot.currentBookings}/${updatedSlot.maxCapacity}');
        return true;
      });
    } catch (e) {
      print('❌ Error reserving slot: $e');
      return false;
    }
  }

  // Release a slot atomically (used during cancellation)
  Future<bool> releaseSlot(
    String serviceId,
    String date,
    String time,
    String bookingId,
  ) async {
    try {
      final slotId = TimeSlotModel.generateId(serviceId, date, time);
      final slotRef = _firestore.collection('timeSlots').doc(slotId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final slotDoc = await transaction.get(slotRef);
        
        if (!slotDoc.exists) {
          throw Exception('Slot does not exist');
        }

        final slot = TimeSlotModel.fromJson(slotDoc.data() as Map<String, dynamic>);
        
        if (!slot.bookingIds.contains(bookingId)) {
          throw Exception('Booking not found in slot');
        }

        // Release the slot
        final updatedBookingIds = List<String>.from(slot.bookingIds)..remove(bookingId);
        final updatedSlot = slot.copyWith(
          currentBookings: math.max(0, slot.currentBookings - 1),
          bookingIds: updatedBookingIds,
          updatedAt: DateTime.now(),
        );

        transaction.update(slotRef, updatedSlot.toJson());
        
        print('✅ Released slot $slotId: ${updatedSlot.currentBookings}/${updatedSlot.maxCapacity}');
        return true;
      });
    } catch (e) {
      print('❌ Error releasing slot: $e');
      return false;
    }
  }

  // Get slot capacity info
  Future<Map<String, dynamic>> getSlotCapacity(
    String serviceId,
    String date,
    String time,
  ) async {
    try {
      final slotId = TimeSlotModel.generateId(serviceId, date, time);
      final slotDoc = await _firestore.collection('timeSlots').doc(slotId).get();
      
      if (!slotDoc.exists) {
        return {
          'isAvailable': false,
          'currentBookings': 0,
          'maxCapacity': 0,
          'message': 'Slot not found',
        };
      }

      final slot = TimeSlotModel.fromJson(slotDoc.data() as Map<String, dynamic>);
      
      return {
        'isAvailable': slot.isAvailable,
        'currentBookings': slot.currentBookings,
        'maxCapacity': slot.maxCapacity,
        'message': slot.isAvailable ? '' : 'Slot is full',
      };
    } catch (e) {
      print('❌ Error getting slot capacity: $e');
      return {
        'isAvailable': false,
        'currentBookings': 0,
        'maxCapacity': 0,
        'message': 'Error checking slot',
      };
    }
  }
}
