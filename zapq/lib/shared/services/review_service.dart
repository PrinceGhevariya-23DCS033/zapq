import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';


class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Test method to verify Firestore connectivity
  Future<bool> testFirestoreConnection() async {
    try {
      print('🧪 Testing Firestore connection...');
      
      final testDoc = {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Firestore connection test'
      };
      
      await _firestore.collection('test').doc('connection-test').set(testDoc);
      print('✅ Firestore connection test successful');
      
      // Clean up test document
      await _firestore.collection('test').doc('connection-test').delete();
      print('🧹 Test document cleaned up');
      
      return true;
    } catch (e) {
      print('❌ Firestore connection test failed: $e');
      return false;
    }
  }

  // Submit a new review
  Future<bool> submitReview(ReviewModel review) async {
    try {
      print('🌟 STARTING review submission...');
      print('📋 Review Data: ${review.toJson()}');
      print('🔑 Review ID: ${review.id}');
      print('🏢 Business ID: ${review.businessId}');
      print('� Customer ID: ${review.customerId}');
      print('⭐ Rating: ${review.rating}');
      print('💬 Comment: "${review.comment}"');

      // Validate review data
      if (review.businessId.isEmpty) {
        throw Exception('Business ID is empty');
      }
      if (review.customerId.isEmpty) {
        throw Exception('Customer ID is empty');
      }
      if (review.rating < 1 || review.rating > 5) {
        throw Exception('Invalid rating: ${review.rating}');
      }

      print('🔄 Saving review to Firestore...');
      final reviewData = review.toJson();
      print('📤 Sending data: $reviewData');
      
      // Save review to Firestore with timeout
      try {
        await _firestore.collection('reviews').doc(review.id).set(reviewData)
            .timeout(const Duration(seconds: 10));
        print('✨ Firestore write operation completed');
      } catch (firestoreError) {
        print('🔥 Firestore write error: $firestoreError');
        throw Exception('Failed to save review to Firestore: $firestoreError');
      }
      
      print('✅ Review saved to Firestore successfully');

      // Update business rating and review count
      print('🔄 Updating business rating...');
      await _updateBusinessRating(review.businessId)
          .timeout(const Duration(seconds: 10));
      
      print('✅ Business rating updated successfully');
      print('🎉 Review submission completed successfully!');
      return true;
    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR submitting review: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  // Get all reviews for a business
  Future<List<ReviewModel>> getBusinessReviews(String businessId) async {
    try {
      print('📋 Fetching reviews for business: $businessId');
      
      // Debug: First, let's see all reviews in the database
      final allReviewsQuery = await _firestore.collection('reviews').get();
      print('🔍 DEBUG: Total reviews in database: ${allReviewsQuery.docs.length}');
      
      for (var doc in allReviewsQuery.docs) {
        final data = doc.data();
        print('🔍 DEBUG: Review ${doc.id} - businessId: ${data['businessId']}, customerId: ${data['customerId']}');
      }
      
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('businessId', isEqualTo: businessId)
          .get();

      print('📊 Query returned ${querySnapshot.docs.length} documents');
      
      final reviews = querySnapshot.docs
          .map((doc) {
            print('📄 Processing review document: ${doc.id}');
            print('📋 Document data: ${doc.data()}');
            return ReviewModel.fromJson(doc.data());
          })
          .toList();
      
      print('✅ Retrieved ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      return [];
    }
  }

  // Get reviews for a specific customer
  Future<List<ReviewModel>> getCustomerReviews(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching customer reviews: $e');
      return [];
    }
  }

  // Update business rating based on all reviews
  Future<void> _updateBusinessRating(String businessId) async {
    try {
      print('📊 Starting business rating update for: $businessId');
      
      // Get all reviews for this business directly
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('businessId', isEqualTo: businessId)
          .get()
          .timeout(const Duration(seconds: 10));
      
      print('📊 Found ${querySnapshot.docs.length} reviews for rating calculation');
      
      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ No reviews found, skipping rating update');
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] ?? 0).toDouble();
        totalRating += rating;
        print('📊 Review ${doc.id}: $rating stars');
      }
      
      final averageRating = totalRating / querySnapshot.docs.length;
      final reviewCount = querySnapshot.docs.length;

      print('📊 Calculated average rating: $averageRating (from $reviewCount reviews)');

      // Update business document
      try {
        await _firestore.collection('businesses').doc(businessId).update({
          'rating': averageRating,
          'reviewCount': reviewCount,
          'totalRatings': reviewCount, // For compatibility
          'updatedAt': DateTime.now().toIso8601String(),
        }).timeout(const Duration(seconds: 10));
        print('✅ Business rating updated successfully: $averageRating stars');
      } catch (updateError) {
        print('❌ Error updating business document: $updateError');
        // Don't throw error here as the review was still saved
      }
    } catch (e) {
      print('❌ Error updating business rating: $e');
      // Don't throw error here as the review was still saved
    }
  }

  // Check if customer has already reviewed a business for a specific booking
  Future<bool> hasCustomerReviewedBooking(String customerId, String businessId, String? bookingId) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('customerId', isEqualTo: customerId)
          .where('businessId', isEqualTo: businessId);

      if (bookingId != null) {
        query = query.where('bookingId', isEqualTo: bookingId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking existing review: $e');
      return false;
    }
  }

  // Delete a review (admin/business owner feature)
  Future<bool> deleteReview(String reviewId, String businessId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      
      // Update business rating after deletion
      await _updateBusinessRating(businessId);
      
      return true;
    } catch (e) {
      print('❌ Error deleting review: $e');
      return false;
    }
  }

  // Get review statistics for a business
  Future<Map<String, dynamic>> getReviewStatistics(String businessId) async {
    try {
      final reviews = await getBusinessReviews(businessId);
      
      if (reviews.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': [0, 0, 0, 0, 0], // 1-5 stars
        };
      }

      final totalReviews = reviews.length;
      final averageRating = reviews.fold<double>(0, (sum, review) => sum + review.rating) / totalReviews;
      
      // Count ratings for each star level
      final ratingDistribution = [0, 0, 0, 0, 0];
      for (final review in reviews) {
        final starIndex = (review.rating.round() - 1).clamp(0, 4);
        ratingDistribution[starIndex]++;
      }

      return {
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('❌ Error getting review statistics: $e');
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': [0, 0, 0, 0, 0],
      };
    }
  }
}