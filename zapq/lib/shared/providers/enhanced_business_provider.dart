import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/business_model.dart';
import '../models/booking_model.dart';

class BusinessProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<BusinessModel> _businesses = [];
  List<BusinessModel> _userBusinesses = [];
  final List<BookingModel> _businessBookings = [];
  BusinessModel? _selectedBusiness;
  bool _isLoading = false;
  String? _errorMessage;

  List<BusinessModel> get businesses => _businesses;
  List<BusinessModel> get userBusinesses => _userBusinesses;
  List<BookingModel> get businessBookings => _businessBookings;
  BusinessModel? get selectedBusiness => _selectedBusiness;
  BusinessModel? get userBusiness => _userBusinesses.isNotEmpty ? _userBusinesses.first : null;
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

  // Create a new business
  Future<bool> createBusiness(BusinessModel business) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('businesses').doc(business.id).set(business.toJson());
      
      _userBusinesses.add(business);
      _businesses.add(business);
      
      print('✅ Business created successfully: ${business.name}');
      return true;
    } catch (e) {
      print('❌ Error creating business: $e');
      _setError('Failed to create business. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register a new business for the current user
  Future<bool> registerBusiness(BusinessModel business) async {
    try {
      _setLoading(true);
      _setError(null);

      print('🏢 Starting business registration...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not logged in');
        _setError('User not logged in');
        return false;
      }

      print('✅ User authenticated: ${user.uid}');

      // Create business with proper IDs
      final businessWithId = business.copyWith(
        id: _firestore.collection('businesses').doc().id,
        ownerId: user.uid,
      );

      print('💾 Saving business to Firestore...');
      print('📄 Business data: ${businessWithId.toJson()}');

      // Save to Firestore
      await _firestore.collection('businesses').doc(businessWithId.id).set(businessWithId.toJson());
      
      print('✅ Business saved to Firestore');

      // Update local state
      _userBusinesses.clear();
      _userBusinesses.add(businessWithId);
      _businesses.add(businessWithId);
      
      print('✅ Business registered successfully: ${businessWithId.name}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error registering business: $e');
      _setError('Failed to register business: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle business active status
  Future<bool> toggleBusinessStatus(String businessId, bool isActive) async {
    try {
      _setLoading(true);
      _setError(null);

      print('🔄 Toggling business status: $businessId to ${isActive ? "Open" : "Closed"}');

      // Update in Firestore
      await _firestore.collection('businesses').doc(businessId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local state
      final businessIndex = _userBusinesses.indexWhere((b) => b.id == businessId);
      if (businessIndex != -1) {
        _userBusinesses[businessIndex] = _userBusinesses[businessIndex].copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
      }

      final allBusinessIndex = _businesses.indexWhere((b) => b.id == businessId);
      if (allBusinessIndex != -1) {
        _businesses[allBusinessIndex] = _businesses[allBusinessIndex].copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
      }

      print('✅ Business status updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error toggling business status: $e');
      _setError('Failed to update business status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get businesses by category
  Future<void> getBusinessesByCategory(String category) async {
    try {
      _setLoading(true);
      _setError(null);

      Query query = _firestore
          .collection('businesses')
          .where('isActive', isEqualTo: true);
      
      if (category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      final QuerySnapshot snapshot = await query.get();
      
      List<BusinessModel> allBusinesses = snapshot.docs
          .map((doc) => BusinessModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Debug logging
      print('🔍 All businesses loaded: ${allBusinesses.length}');
      for (var business in allBusinesses) {
        print('   - ${business.name}: category="${business.category}"');
      }

      if (category != 'all') {
        // Also try to match with old category format for backward compatibility
        List<String> alternativeCategories = _getAlternativeCategories(category);
        
        List<BusinessModel> matchingBusinesses = allBusinesses.where((business) {
          return business.category == category || 
                 alternativeCategories.contains(business.category);
        }).toList();
        
        print('🎯 Matching businesses for "$category": ${matchingBusinesses.length}');
        _businesses = matchingBusinesses;
      } else {
        _businesses = allBusinesses;
      }

      print('✅ Final result: ${_businesses.length} businesses for category: $category');
    } catch (e) {
      print('❌ Error loading businesses: $e');
      _setError('Failed to load businesses. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to get alternative category names for backward compatibility
  List<String> _getAlternativeCategories(String category) {
    switch (category) {
      case 'salon':
        return ['Salon', 'Hair Salon'];
      case 'beauty_parlor':
        return ['Beauty Parlor'];
      case 'barbershop':
        return ['Barber Shop', 'Barbershop'];
      case 'spa':
        return ['Spa & Wellness', 'Spa'];
      case 'medical':
        return ['Medical Clinic', 'Medical'];
      case 'dental':
        return ['Dental Clinic', 'Dental'];
      case 'fitness':
        return ['Gym & Fitness', 'Fitness'];
      default:
        return ['Other'];
    }
  }

  // Get user's businesses
  Future<void> getUserBusinesses(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final QuerySnapshot snapshot = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: userId)
          .get();

      _userBusinesses = snapshot.docs
          .map((doc) => BusinessModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      print('✅ Loaded ${_userBusinesses.length} businesses for user: $userId');
    } catch (e) {
      print('❌ Error loading user businesses: $e');
      _setError('Failed to load your businesses. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Search businesses
  Future<void> searchBusinesses(String searchTerm) async {
    try {
      _setLoading(true);
      _setError(null);

      if (searchTerm.isEmpty) {
        await getBusinessesByCategory('all');
        return;
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('businesses')
          .where('isActive', isEqualTo: true)
          .get();

      _businesses = snapshot.docs
          .map((doc) => BusinessModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((business) => 
              business.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
              business.description.toLowerCase().contains(searchTerm.toLowerCase()) ||
              business.address.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();

      print('✅ Found ${_businesses.length} businesses for search: $searchTerm');
    } catch (e) {
      print('❌ Error searching businesses: $e');
      _setError('Failed to search businesses. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Update business
  Future<bool> updateBusiness(BusinessModel business) async {
    try {
      _setLoading(true);
      _setError(null);

      print('💾 Updating business in Firestore:');
      print('📸 ProfileImageUrl: ${business.profileImageUrl}');
      print('📷 ImageUrls: ${business.imageUrls}');
      final businessJson = business.toJson();
      print('📄 Business JSON: $businessJson');

      await _firestore.collection('businesses').doc(business.id).update(businessJson);
      
      // Update local lists
      final index = _userBusinesses.indexWhere((b) => b.id == business.id);
      if (index != -1) {
        _userBusinesses[index] = business;
      }
      
      final businessIndex = _businesses.indexWhere((b) => b.id == business.id);
      if (businessIndex != -1) {
        _businesses[businessIndex] = business;
      }

      print('✅ Business updated successfully: ${business.name}');
      return true;
    } catch (e) {
      print('❌ Error updating business: $e');
      _setError('Failed to update business. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedBusiness(BusinessModel? business) {
    _selectedBusiness = business;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearBusinesses() {
    _businesses.clear();
    notifyListeners();
  }

  // Load user's businesses
  Future<void> loadUserBusiness() async {
    try {
      _setLoading(true);
      _setError(null);

      print('🔍 Loading businesses for current user...');
      
      // Get current user ID from auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        _setError('User not authenticated');
        return;
      }

      print('📧 Loading businesses for user: ${user.uid}');
      
      // Query businesses owned by current user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      _userBusinesses = querySnapshot.docs
          .map((doc) => BusinessModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      print('✅ Loaded ${_userBusinesses.length} businesses for user: ${user.uid}');
      
      if (_userBusinesses.isNotEmpty) {
        print('📋 Business names: ${_userBusinesses.map((b) => b.name).join(', ')}');
      } else {
        print('📝 No businesses found for this user');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error loading user businesses: $e');
      _setError('Failed to load user businesses: $e');
    } finally {
      _setLoading(false);
    }
  }
}
