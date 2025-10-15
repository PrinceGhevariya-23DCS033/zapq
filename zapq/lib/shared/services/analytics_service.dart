import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Financial Analytics
  Future<Map<String, dynamic>> getFinancialAnalytics(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('📊 Getting financial analytics for: $businessId');
      
      // Get all bookings for this business (simplified query to avoid index requirements)
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      // Filter in memory to avoid complex Firestore indexes
      final allBookings = bookingsQuery.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();

      // Filter current period bookings (include both confirmed and completed for revenue)
      final currentPeriodBookings = allBookings
          .where((booking) => 
              booking.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
              booking.createdAt.isBefore(endDate.add(const Duration(days: 1))) &&
              (booking.status.toString().split('.').last == 'confirmed' ||
               booking.status.toString().split('.').last == 'completed'))
          .toList();

      // Get previous period for comparison
      final previousStartDate = startDate.subtract(endDate.difference(startDate));
      final previousPeriodBookings = allBookings
          .where((booking) => 
              booking.createdAt.isAfter(previousStartDate.subtract(const Duration(days: 1))) &&
              booking.createdAt.isBefore(startDate.add(const Duration(days: 1))) &&
              (booking.status.toString().split('.').last == 'confirmed' ||
               booking.status.toString().split('.').last == 'completed'))
          .toList();

      // Calculate current period metrics
      double totalRevenue = 0;
      int totalBookings = currentPeriodBookings.length;
      Map<String, double> dailyRevenue = {};
      Map<String, int> dailyBookings = {};

      for (var booking in currentPeriodBookings) {
        // Use servicePrice if totalPrice is not available or is 0
        double bookingRevenue = booking.totalPrice > 0 
            ? booking.totalPrice.toDouble() 
            : (booking.servicePrice ?? 0.0);
        totalRevenue += bookingRevenue;

        // Group by day for trends
        final dayKey = _getDayKey(booking.createdAt);
        dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + bookingRevenue;
        dailyBookings[dayKey] = (dailyBookings[dayKey] ?? 0) + 1;
      }

      // Calculate previous period metrics
      double previousRevenue = 0;
      int previousBookingsCount = previousPeriodBookings.length;

      for (var booking in previousPeriodBookings) {
        // Use servicePrice if totalPrice is not available or is 0
        double bookingRevenue = booking.totalPrice > 0 
            ? booking.totalPrice.toDouble() 
            : (booking.servicePrice ?? 0.0);
        previousRevenue += bookingRevenue;
      }

      // Calculate growth percentages
      double revenueGrowth = previousRevenue > 0 
          ? ((totalRevenue - previousRevenue) / previousRevenue) * 100 
          : 0;
      double bookingGrowth = previousBookingsCount > 0 
          ? ((totalBookings - previousBookingsCount) / previousBookingsCount) * 100 
          : 0;

      // Calculate average booking value
      double averageBookingValue = totalBookings > 0 ? totalRevenue / totalBookings : 0;

      return {
        'totalRevenue': totalRevenue,
        'totalBookings': totalBookings,
        'revenueGrowth': revenueGrowth.round(),
        'bookingGrowth': bookingGrowth.round(),
        'averageBookingValue': averageBookingValue,
        'dailyRevenue': dailyRevenue,
        'dailyBookings': dailyBookings,
        'previousRevenue': previousRevenue,
        'previousBookings': previousBookingsCount,
      };
    } catch (e) {
      print('❌ Error getting financial analytics: $e');
      return {
        'totalRevenue': 0,
        'totalBookings': 0,
        'revenueGrowth': 0,
        'bookingGrowth': 0,
        'averageBookingValue': 0,
        'dailyRevenue': <String, double>{},
        'dailyBookings': <String, int>{},
        'previousRevenue': 0,
        'previousBookings': 0,
      };
    }
  }

  // Customer Analytics
  Future<Map<String, dynamic>> getCustomerAnalytics(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('👥 Getting customer analytics for: $businessId');

      // Get all bookings to analyze customers (simplified query)
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      // Get reviews for ratings
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('businessId', isEqualTo: businessId)
          .get();

      // Filter bookings by date range in memory
      final filteredBookings = bookingsQuery.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .where((booking) => 
              booking.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
              booking.createdAt.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      Set<String> uniqueCustomers = {};
      Map<String, int> customerBookingCount = {};
      int totalBookings = 0;
      
      for (var booking in filteredBookings) {
        uniqueCustomers.add(booking.customerId);
        customerBookingCount[booking.customerId] = 
            (customerBookingCount[booking.customerId] ?? 0) + 1;
        totalBookings++;
      }

      // Calculate ratings
      double totalRating = 0;
      int totalReviews = 0;
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in reviewsQuery.docs) {
        final review = ReviewModel.fromJson(doc.data());
        totalRating += review.rating;
        totalReviews++;
        ratingDistribution[review.rating.round()] = 
            (ratingDistribution[review.rating.round()] ?? 0) + 1;
      }

      double averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;

      // Calculate repeat customers
      int repeatCustomers = customerBookingCount.values
          .where((count) => count > 1).length;
      
      double customerRetentionRate = uniqueCustomers.length > 0 
          ? (repeatCustomers / uniqueCustomers.length) * 100 
          : 0;

      // Calculate customer growth compared to previous period
      final previousStartDate = startDate.subtract(endDate.difference(startDate));
      final previousPeriodBookings = bookingsQuery.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .where((booking) => 
              booking.createdAt.isAfter(previousStartDate.subtract(const Duration(days: 1))) &&
              booking.createdAt.isBefore(startDate.add(const Duration(days: 1))))
          .toList();

      Set<String> previousUniqueCustomers = {};
      for (var booking in previousPeriodBookings) {
        previousUniqueCustomers.add(booking.customerId);
      }

      double customerGrowth = previousUniqueCustomers.length > 0 
          ? ((uniqueCustomers.length - previousUniqueCustomers.length) / previousUniqueCustomers.length) * 100 
          : uniqueCustomers.length > 0 ? 100 : 0;

      return {
        'newCustomers': uniqueCustomers.length,
        'totalCustomers': uniqueCustomers.length,
        'repeatCustomers': repeatCustomers,
        'customerRetentionRate': customerRetentionRate,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'ratingDistribution': ratingDistribution,
        'customerGrowth': customerGrowth.round(),
        'averageBookingsPerCustomer': uniqueCustomers.length > 0 
            ? totalBookings / uniqueCustomers.length : 0,
      };
    } catch (e) {
      print('❌ Error getting customer analytics: $e');
      return {
        'newCustomers': 0,
        'totalCustomers': 0,
        'repeatCustomers': 0,
        'customerRetentionRate': 0,
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        'customerGrowth': 0,
        'averageBookingsPerCustomer': 0,
      };
    }
  }

  // Service Analytics
  Future<Map<String, dynamic>> getServiceAnalytics(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('🔧 Getting service analytics for: $businessId');

      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      // Filter bookings by date range and status in memory
      final filteredBookings = bookingsQuery.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .where((booking) => 
              booking.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
              booking.createdAt.isBefore(endDate.add(const Duration(days: 1))) &&
              (booking.status.toString().split('.').last == 'confirmed' ||
               booking.status.toString().split('.').last == 'completed'))
          .toList();

      Map<String, int> serviceBookingCount = {};
      Map<String, double> serviceRevenue = {};
      Map<String, List<double>> servicePrices = {};

      for (var booking in filteredBookings) {
        final serviceName = booking.serviceName ?? 'Unknown Service';
        // Use totalPrice if available and > 0, otherwise fall back to servicePrice
        final revenue = booking.totalPrice > 0 
            ? booking.totalPrice.toDouble() 
            : (booking.servicePrice ?? 0.0);
        
        serviceBookingCount[serviceName] = 
            (serviceBookingCount[serviceName] ?? 0) + 1;
        serviceRevenue[serviceName] = 
            (serviceRevenue[serviceName] ?? 0) + revenue;
        
        if (!servicePrices.containsKey(serviceName)) {
          servicePrices[serviceName] = [];
        }
        servicePrices[serviceName]!.add(revenue);
      }

      // Find most popular service
      String mostPopularService = '';
      int maxBookings = 0;
      for (var entry in serviceBookingCount.entries) {
        if (entry.value > maxBookings) {
          maxBookings = entry.value;
          mostPopularService = entry.key;
        }
      }

      // Find most profitable service
      String mostProfitableService = '';
      double maxRevenue = 0;
      for (var entry in serviceRevenue.entries) {
        if (entry.value > maxRevenue) {
          maxRevenue = entry.value;
          mostProfitableService = entry.key;
        }
      }

      return {
        'totalServices': serviceBookingCount.length,
        'serviceBookingCount': serviceBookingCount,
        'serviceRevenue': serviceRevenue,
        'mostPopularService': mostPopularService,
        'mostProfitableService': mostProfitableService,
        'servicePerformance': _calculateServicePerformance(
            serviceBookingCount, serviceRevenue),
      };
    } catch (e) {
      print('❌ Error getting service analytics: $e');
      return {
        'totalServices': 0,
        'serviceBookingCount': <String, int>{},
        'serviceRevenue': <String, double>{},
        'mostPopularService': '',
        'mostProfitableService': '',
        'servicePerformance': <Map<String, dynamic>>[],
      };
    }
  }

  // Get recent bookings
  Future<List<BookingModel>> getRecentBookings(String businessId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      // Sort in memory and limit results
      final bookings = querySnapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
      
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return bookings.take(limit).toList();
    } catch (e) {
      print('❌ Error getting recent bookings: $e');
      return [];
    }
  }

  // Revenue trends for charts
  Future<List<Map<String, dynamic>>> getRevenueTrends(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      // Filter bookings by date range and status in memory
      final filteredBookings = bookingsQuery.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .where((booking) => 
              booking.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
              booking.createdAt.isBefore(endDate.add(const Duration(days: 1))) &&
              (booking.status.toString().split('.').last == 'confirmed' ||
               booking.status.toString().split('.').last == 'completed'))
          .toList();

      Map<String, double> dailyRevenue = {};
      
      for (var booking in filteredBookings) {
        final dayKey = _getDayKey(booking.createdAt);
        // Use servicePrice if totalPrice is not available or is 0
        double bookingRevenue = booking.totalPrice > 0 
            ? booking.totalPrice.toDouble() 
            : (booking.servicePrice ?? 0.0);
        dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + bookingRevenue;
      }

      print('🔧 TRENDS: Filtered bookings count: ${filteredBookings.length}');
      print('🔧 TRENDS: Daily revenue: $dailyRevenue');

      // Convert to list of maps for chart data
      List<Map<String, dynamic>> chartData = [];
      dailyRevenue.entries.forEach((entry) {
        chartData.add({
          'date': entry.key,
          'revenue': entry.value,
        });
      });

      // Sort by date
      chartData.sort((a, b) => a['date'].compareTo(b['date']));
      
      return chartData;
    } catch (e) {
      print('❌ Error getting revenue trends: $e');
      return [];
    }
  }

  // Customer growth trends
  Future<List<Map<String, dynamic>>> getCustomerGrowthTrends(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      // Filter bookings by date range in memory
      final filteredBookings = bookingsQuery.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .where((booking) => 
              booking.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
              booking.createdAt.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      Map<String, Set<String>> dailyCustomers = {};
      
      for (var booking in filteredBookings) {
        final dayKey = _getDayKey(booking.createdAt);
        
        if (!dailyCustomers.containsKey(dayKey)) {
          dailyCustomers[dayKey] = <String>{};
        }
        dailyCustomers[dayKey]!.add(booking.customerId);
      }

      // Convert to cumulative customer count
      List<Map<String, dynamic>> chartData = [];
      Set<String> totalCustomers = {};
      
      final sortedDays = dailyCustomers.keys.toList()..sort();
      
      for (var day in sortedDays) {
        totalCustomers.addAll(dailyCustomers[day]!);
        chartData.add({
          'date': day,
          'customers': totalCustomers.length,
        });
      }
      
      return chartData;
    } catch (e) {
      print('❌ Error getting customer growth trends: $e');
      return [];
    }
  }

  // Helper methods
  String _getDayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _calculateServicePerformance(
    Map<String, int> bookingCount,
    Map<String, double> revenue,
  ) {
    List<Map<String, dynamic>> performance = [];
    
    for (var serviceName in bookingCount.keys) {
      final bookings = bookingCount[serviceName] ?? 0;
      final totalRevenue = revenue[serviceName] ?? 0;
      final avgPrice = bookings > 0 ? totalRevenue / bookings : 0;
      
      performance.add({
        'serviceName': serviceName,
        'bookings': bookings,
        'revenue': totalRevenue,
        'averagePrice': avgPrice,
        'popularityScore': bookings * 0.6 + (totalRevenue / 100) * 0.4,
      });
    }
    
    // Sort by popularity score
    performance.sort((a, b) => b['popularityScore'].compareTo(a['popularityScore']));
    
    return performance;
  }

  // Get top customers
  Future<List<Map<String, dynamic>>> getTopCustomers(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();

      // Filter bookings by date range in memory
      final filteredBookings = bookingsQuery.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .where((booking) => 
              booking.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
              booking.createdAt.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      Map<String, Map<String, dynamic>> customerData = {};
      
      for (var booking in filteredBookings) {
        final customerId = booking.customerId;
        
        if (!customerData.containsKey(customerId)) {
          customerData[customerId] = {
            'customerId': customerId,
            'customerName': booking.customerName ?? 'Unknown Customer',
            'totalBookings': 0,
            'totalSpent': 0.0,
            'lastBooking': booking.createdAt,
          };
        }
        
        customerData[customerId]!['totalBookings']++;
        // Use totalPrice if available and > 0, otherwise fall back to servicePrice
        final revenue = booking.totalPrice > 0 
            ? booking.totalPrice.toDouble() 
            : (booking.servicePrice ?? 0.0);
        customerData[customerId]!['totalSpent'] += revenue;
        
        if (booking.createdAt.isAfter(customerData[customerId]!['lastBooking'])) {
          customerData[customerId]!['lastBooking'] = booking.createdAt;
        }
      }

      List<Map<String, dynamic>> topCustomers = customerData.values.toList();
      
      // Sort by total spent
      topCustomers.sort((a, b) => b['totalSpent'].compareTo(a['totalSpent']));
      
      return topCustomers.take(10).toList();
    } catch (e) {
      print('❌ Error getting top customers: $e');
      return [];
    }
  }
}