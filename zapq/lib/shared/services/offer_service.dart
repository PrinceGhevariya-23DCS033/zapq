import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new offer
  Future<bool> createOffer(OfferModel offer) async {
    try {
      print('🎯 Creating offer: ${offer.title} for business: ${offer.businessId}');
      
      await _firestore.collection('offers').doc(offer.id).set(offer.toJson());
      
      print('✅ Offer created successfully: ${offer.id}');
      return true;
    } catch (e) {
      print('❌ Error creating offer: $e');
      return false;
    }
  }

  // Update an existing offer
  Future<bool> updateOffer(OfferModel offer) async {
    try {
      print('🎯 Updating offer: ${offer.id}');
      
      await _firestore.collection('offers').doc(offer.id).update(offer.toJson());
      
      print('✅ Offer updated successfully: ${offer.id}');
      return true;
    } catch (e) {
      print('❌ Error updating offer: $e');
      return false;
    }
  }

  // Get all offers for a business
  Future<List<OfferModel>> getBusinessOffers(String businessId) async {
    try {
      print('🎯 Getting offers for business: $businessId');
      
      final querySnapshot = await _firestore
          .collection('offers')
          .where('businessId', isEqualTo: businessId)
          .get();

      final offers = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return OfferModel.fromJson(data);
          })
          .toList();

      // Sort by creation date (newest first)
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Retrieved ${offers.length} offers for business: $businessId');
      return offers;
    } catch (e) {
      print('❌ Error fetching business offers: $e');
      return [];
    }
  }

  // Get active offers for a business (for customers to see)
  Future<List<OfferModel>> getActiveBusinessOffers(String businessId) async {
    try {
      print('🎯 Getting active offers for business: $businessId');
      
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('offers')
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .get();

      final offers = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return OfferModel.fromJson(data);
          })
          .where((offer) => 
              offer.startDate.isBefore(now) && 
              offer.endDate.isAfter(now))
          .toList();

      // Sort by creation date (newest first)
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Retrieved ${offers.length} active offers for business: $businessId');
      return offers;
    } catch (e) {
      print('❌ Error fetching active business offers: $e');
      return [];
    }
  }

  // Get all active offers (for customers to browse)
  Future<List<OfferModel>> getAllActiveOffers() async {
    try {
      print('🌐 Getting all active offers');
      
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .get();

      final offers = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return OfferModel.fromJson(data);
          })
          .where((offer) => 
              offer.startDate.isBefore(now) && 
              offer.endDate.isAfter(now))
          .toList();

      // Sort by creation date (newest first)
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Retrieved ${offers.length} active offers from all businesses');
      return offers;
    } catch (e) {
      print('❌ Error fetching all active offers: $e');
      return [];
    }
  }

  // Delete an offer
  Future<bool> deleteOffer(String offerId) async {
    try {
      print('🎯 Deleting offer: $offerId');
      
      await _firestore.collection('offers').doc(offerId).delete();
      
      print('✅ Offer deleted successfully: $offerId');
      return true;
    } catch (e) {
      print('❌ Error deleting offer: $e');
      return false;
    }
  }

  // Get offer by ID
  Future<OfferModel?> getOfferById(String offerId) async {
    try {
      print('🎯 Getting offer: $offerId');
      
      final doc = await _firestore.collection('offers').doc(offerId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final offer = OfferModel.fromJson(data);
        print('✅ Retrieved offer: ${offer.title}');
        return offer;
      } else {
        print('⚠️ Offer not found: $offerId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching offer: $e');
      return null;
    }
  }

  // Get offer statistics for a business
  Future<Map<String, dynamic>> getOfferStatistics(String businessId) async {
    try {
      print('📊 Getting offer statistics for business: $businessId');
      
      final offers = await getBusinessOffers(businessId);
      final now = DateTime.now();
      
      final activeOffers = offers.where((offer) => 
          offer.isActive && 
          offer.startDate.isBefore(now) && 
          offer.endDate.isAfter(now)).length;
      
      final expiredOffers = offers.where((offer) => 
          offer.endDate.isBefore(now)).length;
      
      final upcomingOffers = offers.where((offer) => 
          offer.startDate.isAfter(now)).length;

      final statistics = {
        'totalOffers': offers.length,
        'activeOffers': activeOffers,
        'expiredOffers': expiredOffers,
        'upcomingOffers': upcomingOffers,
      };

      print('📊 Offer statistics: $statistics');
      return statistics;
    } catch (e) {
      print('❌ Error getting offer statistics: $e');
      return {
        'totalOffers': 0,
        'activeOffers': 0,
        'expiredOffers': 0,
        'upcomingOffers': 0,
      };
    }
  }
}