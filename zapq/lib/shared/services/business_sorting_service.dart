import '../models/business_model.dart';
import '../models/review_model.dart';

class BusinessSortingService {
  // Sort businesses by average rating (highest first)
  static List<BusinessModel> sortByRating(
    List<BusinessModel> businesses, {
    bool ascending = false,
  }) {
    final sortedBusinesses = List<BusinessModel>.from(businesses);
    
    sortedBusinesses.sort((a, b) {
      final aRating = a.rating;
      final bRating = b.rating;
      
      return ascending 
          ? aRating.compareTo(bRating)
          : bRating.compareTo(aRating);
    });
    
    return sortedBusinesses;
  }

  // Sort businesses by review count (most reviewed first)
  static List<BusinessModel> sortByReviewCount(
    List<BusinessModel> businesses, {
    bool ascending = false,
  }) {
    final sortedBusinesses = List<BusinessModel>.from(businesses);
    
    sortedBusinesses.sort((a, b) {
      final aCount = a.reviewCount;
      final bCount = b.reviewCount;
      
      return ascending 
          ? aCount.compareTo(bCount)
          : bCount.compareTo(aCount);
    });
    
    return sortedBusinesses;
  }

  // Sort businesses by relevance score (combines rating and review count)
  static List<BusinessModel> sortByRelevance(
    List<BusinessModel> businesses, {
    bool ascending = false,
  }) {
    final sortedBusinesses = List<BusinessModel>.from(businesses);
    
    sortedBusinesses.sort((a, b) {
      final aScore = _calculateRelevanceScore(a);
      final bScore = _calculateRelevanceScore(b);
      
      return ascending 
          ? aScore.compareTo(bScore)
          : bScore.compareTo(aScore);
    });
    
    return sortedBusinesses;
  }

  // Filter businesses by minimum rating
  static List<BusinessModel> filterByMinimumRating(
    List<BusinessModel> businesses,
    double minimumRating,
  ) {
    return businesses.where((business) {
      final rating = business.rating;
      return rating >= minimumRating;
    }).toList();
  }

  // Filter businesses with recent reviews (within specified days)
  static List<BusinessModel> filterByRecentActivity(
    List<BusinessModel> businesses,
    List<ReviewModel> allReviews,
    int withinDays,
  ) {
    final cutoffDate = DateTime.now().subtract(Duration(days: withinDays));
    
    return businesses.where((business) {
      final businessReviews = allReviews.where(
        (review) => review.businessId == business.id,
      );
      
      return businessReviews.any(
        (review) => review.createdAt.isAfter(cutoffDate),
      );
    }).toList();
  }

  // Get top-rated businesses (4+ stars)
  static List<BusinessModel> getTopRatedBusinesses(
    List<BusinessModel> businesses, {
    double minimumRating = 4.0,
    int? limit,
  }) {
    final topRated = filterByMinimumRating(businesses, minimumRating);
    final sorted = sortByRating(topRated);
    
    if (limit != null && sorted.length > limit) {
      return sorted.take(limit).toList();
    }
    
    return sorted;
  }

  // Get trending businesses (high rating + recent reviews)
  static List<BusinessModel> getTrendingBusinesses(
    List<BusinessModel> businesses,
    List<ReviewModel> allReviews, {
    double minimumRating = 4.0,
    int recentDays = 30,
    int? limit,
  }) {
    final highRated = filterByMinimumRating(businesses, minimumRating);
    final withRecentActivity = filterByRecentActivity(
      highRated,
      allReviews,
      recentDays,
    );
    final sorted = sortByRelevance(withRecentActivity);
    
    if (limit != null && sorted.length > limit) {
      return sorted.take(limit).toList();
    }
    
    return sorted;
  }

  // Calculate relevance score combining rating and review count
  static double _calculateRelevanceScore(BusinessModel business) {
    final rating = business.rating;
    final reviewCount = business.reviewCount;
    
    // Wilson score confidence interval for better ranking
    // This prevents businesses with few reviews from ranking too high
    if (reviewCount == 0) return 0.0;
    
    const double z = 1.96; // 95% confidence interval
    final double p = rating / 5.0; // Convert 5-star rating to probability
    final double n = reviewCount.toDouble();
    
    final double numerator = p + (z * z) / (2 * n) - z * 
        (p * (1 - p) / n + (z * z) / (4 * n * n)).abs();
    final double denominator = 1 + (z * z) / n;
    
    final double wilsonScore = numerator / denominator;
    
    // Boost score for businesses with more reviews
    final double reviewBoost = (reviewCount / (reviewCount + 10)).clamp(0.0, 1.0);
    
    return (wilsonScore * 5.0 * (1 + reviewBoost * 0.2)).clamp(0.0, 5.0);
  }

  // Group businesses by rating ranges
  static Map<String, List<BusinessModel>> groupByRatingRanges(
    List<BusinessModel> businesses,
  ) {
    final Map<String, List<BusinessModel>> grouped = {
      'Excellent (4.5+)': [],
      'Very Good (4.0-4.4)': [],
      'Good (3.5-3.9)': [],
      'Average (3.0-3.4)': [],
      'Below Average (<3.0)': [],
      'No Reviews': [],
    };
    
    for (final business in businesses) {
      final rating = business.rating;
      
      if (rating == 0.0) {
        grouped['No Reviews']!.add(business);
      } else if (rating >= 4.5) {
        grouped['Excellent (4.5+)']!.add(business);
      } else if (rating >= 4.0) {
        grouped['Very Good (4.0-4.4)']!.add(business);
      } else if (rating >= 3.5) {
        grouped['Good (3.5-3.9)']!.add(business);
      } else if (rating >= 3.0) {
        grouped['Average (3.0-3.4)']!.add(business);
      } else {
        grouped['Below Average (<3.0)']!.add(business);
      }
    }
    
    // Sort businesses within each group by rating
    grouped.forEach((key, value) {
      grouped[key] = sortByRating(value);
    });
    
    return grouped;
  }

  // Get business performance metrics
  static Map<String, dynamic> getBusinessMetrics(
    BusinessModel business,
    List<ReviewModel> businessReviews,
  ) {
    if (businessReviews.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': [0, 0, 0, 0, 0],
        'recentReviews': 0,
        'responseRate': 0.0,
        'improvementTrend': 'neutral',
      };
    }

    final ratings = businessReviews.map((r) => r.rating).toList();
    final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
    
    // Rating distribution (1-5 stars)
    final distribution = List.filled(5, 0);
    for (final rating in ratings) {
      if (rating >= 1 && rating <= 5) {
        distribution[rating.round() - 1]++;
      }
    }
    
    // Recent reviews (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentReviews = businessReviews
        .where((review) => review.createdAt.isAfter(thirtyDaysAgo))
        .length;
    
    // Response rate (placeholder - can be implemented when business response feature is added)
    final reviewsWithResponse = 0; // TODO: Implement when business response feature is added
    final responseRate = reviewsWithResponse / businessReviews.length;
    
    // Improvement trend (comparing recent vs older reviews)
    final improvement = _calculateImprovementTrend(businessReviews);
    
    return {
      'averageRating': averageRating,
      'totalReviews': businessReviews.length,
      'ratingDistribution': distribution,
      'recentReviews': recentReviews,
      'responseRate': responseRate,
      'improvementTrend': improvement,
    };
  }

  // Calculate improvement trend
  static String _calculateImprovementTrend(List<ReviewModel> reviews) {
    if (reviews.length < 6) return 'neutral';
    
    final sortedReviews = List<ReviewModel>.from(reviews);
    sortedReviews.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    final recentReviews = sortedReviews.reversed.take(3).toList();
    final olderReviews = sortedReviews.take(3).toList();
    
    final recentAvg = recentReviews
        .map((r) => r.rating)
        .reduce((a, b) => a + b) / recentReviews.length;
    final olderAvg = olderReviews
        .map((r) => r.rating)
        .reduce((a, b) => a + b) / olderReviews.length;
    
    final difference = recentAvg - olderAvg;
    
    if (difference > 0.3) return 'improving';
    if (difference < -0.3) return 'declining';
    return 'neutral';
  }

  // Search and sort businesses
  static List<BusinessModel> searchAndSort(
    List<BusinessModel> businesses,
    String query, {
    SortOption sortBy = SortOption.relevance,
    double? minimumRating,
  }) {
    // First filter by search query
    List<BusinessModel> filtered = businesses.where((business) {
      final searchText = query.toLowerCase();
      return business.name.toLowerCase().contains(searchText) ||
             business.description.toLowerCase().contains(searchText) ||
             business.category.toLowerCase().contains(searchText) ||
             business.address.toLowerCase().contains(searchText);
    }).toList();
    
    // Apply minimum rating filter if specified
    if (minimumRating != null) {
      filtered = filterByMinimumRating(filtered, minimumRating);
    }
    
    // Sort by specified option
    switch (sortBy) {
      case SortOption.rating:
        return sortByRating(filtered);
      case SortOption.reviewCount:
        return sortByReviewCount(filtered);
      case SortOption.relevance:
        return sortByRelevance(filtered);
      case SortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        return filtered;
    }
  }
}

enum SortOption {
  relevance,
  rating,
  reviewCount,
  name,
}