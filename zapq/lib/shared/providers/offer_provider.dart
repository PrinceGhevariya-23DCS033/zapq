import 'package:flutter/material.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';

class OfferProvider extends ChangeNotifier {
  final OfferService _offerService = OfferService();
  
  List<OfferModel> _businessOffers = [];
  List<OfferModel> _activeOffers = [];
  Map<String, dynamic> _offerStatistics = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<OfferModel> get businessOffers => _businessOffers;
  List<OfferModel> get activeOffers => _activeOffers;
  Map<String, dynamic> get offerStatistics => _offerStatistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get active offers for a specific business
  List<OfferModel> getOffersForBusiness(String businessId) {
    // If we loaded active offers for a specific business, return those
    // (they are already filtered for the business and are active)
    final filteredActiveOffers = _activeOffers.where((offer) => offer.businessId == businessId).toList();
    print('🎯 OfferProvider: Returning ${filteredActiveOffers.length} active offers for $businessId');
    
    // Additional debug info
    print('🎯 OfferProvider: Total active offers in memory: ${_activeOffers.length}');
    for (var offer in _activeOffers) {
      print('📋 Available offer: ${offer.title} (Business: ${offer.businessId})');
    }
    
    return filteredActiveOffers;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Load business offers
  Future<void> loadBusinessOffers(String businessId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _businessOffers = await _offerService.getBusinessOffers(businessId);
      print('✅ OfferProvider: Loaded ${_businessOffers.length} business offers');
    } catch (e) {
      print('❌ OfferProvider: Error loading business offers: $e');
      _setError('Failed to load offers');
    } finally {
      _setLoading(false);
    }
  }

  // Load all active offers (for customers)
  Future<void> loadActiveOffers() async {
    _setLoading(true);
    _setError(null);
    
    try {
      // For now, we'll load all active offers from all businesses
      // This could be optimized to load only nearby businesses or favorites
      _activeOffers = await _offerService.getAllActiveOffers();
      print('✅ OfferProvider: Loaded ${_activeOffers.length} active offers');
    } catch (e) {
      print('❌ OfferProvider: Error loading active offers: $e');
      _setError('Failed to load active offers');
    } finally {
      _setLoading(false);
    }
  }

  // Load active offers for a business (for customers)
  Future<void> loadActiveBusinessOffers(String businessId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _activeOffers = await _offerService.getActiveBusinessOffers(businessId);
      print('✅ OfferProvider: Loaded ${_activeOffers.length} active offers');
    } catch (e) {
      print('❌ OfferProvider: Error loading active offers: $e');
      _setError('Failed to load active offers');
    } finally {
      _setLoading(false);
    }
  }

  // Load offer statistics
  Future<void> loadOfferStatistics(String businessId) async {
    try {
      _offerStatistics = await _offerService.getOfferStatistics(businessId);
      print('✅ OfferProvider: Loaded offer statistics');
      notifyListeners();
    } catch (e) {
      print('❌ OfferProvider: Error loading offer statistics: $e');
    }
  }

  // Create a new offer
  Future<bool> createOffer(OfferModel offer) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final success = await _offerService.createOffer(offer);
      if (success) {
        _businessOffers.insert(0, offer); // Add to beginning of list
        print('✅ OfferProvider: Offer created and added to list');
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('❌ OfferProvider: Error creating offer: $e');
      _setError('Failed to create offer');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing offer
  Future<bool> updateOffer(OfferModel offer) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final success = await _offerService.updateOffer(offer);
      if (success) {
        // Update the offer in the list
        final index = _businessOffers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _businessOffers[index] = offer;
          print('✅ OfferProvider: Offer updated in list');
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      print('❌ OfferProvider: Error updating offer: $e');
      _setError('Failed to update offer');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete an offer
  Future<bool> deleteOffer(String offerId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final success = await _offerService.deleteOffer(offerId);
      if (success) {
        _businessOffers.removeWhere((o) => o.id == offerId);
        _activeOffers.removeWhere((o) => o.id == offerId);
        print('✅ OfferProvider: Offer removed from lists');
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('❌ OfferProvider: Error deleting offer: $e');
      _setError('Failed to delete offer');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear all offers (on logout)
  void clearOffers() {
    _businessOffers.clear();
    _activeOffers.clear();
    _offerStatistics.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh offers (pull to refresh)
  Future<void> refreshOffers(String businessId) async {
    await loadBusinessOffers(businessId);
    await loadActiveBusinessOffers(businessId);
    await loadOfferStatistics(businessId);
  }
}