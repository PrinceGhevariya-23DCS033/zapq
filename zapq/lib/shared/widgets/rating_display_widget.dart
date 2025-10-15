import 'package:flutter/material.dart';
import '../../../shared/models/review_model.dart';
import '../../../core/theme/app_colors.dart';

class RatingDisplayWidget extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;
  final bool showCount;
  final Color? color;

  const RatingDisplayWidget({
    Key? key,
    required this.rating,
    this.reviewCount = 0,
    this.size = 16,
    this.showCount = true,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            // Full star
            return Icon(
              Icons.star,
              size: size,
              color: color ?? Colors.amber,
            );
          } else if (index < rating) {
            // Half star
            return Icon(
              Icons.star_half,
              size: size,
              color: color ?? Colors.amber,
            );
          } else {
            // Empty star
            return Icon(
              Icons.star_border,
              size: size,
              color: color ?? Colors.grey[400],
            );
          }
        }),
        if (showCount && reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

class ReviewListWidget extends StatelessWidget {
  final List<ReviewModel> reviews;
  final bool showAll;
  final VoidCallback? onViewAll;

  const ReviewListWidget({
    Key? key,
    required this.reviews,
    this.showAll = false,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayReviews = showAll ? reviews : reviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!showAll && reviews.length > 3)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to leave a review!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayReviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final review = displayReviews[index];
              return ReviewItemWidget(review: review);
            },
          ),
      ],
    );
  }
}

class ReviewItemWidget extends StatelessWidget {
  final ReviewModel review;

  const ReviewItemWidget({
    Key? key,
    required this.review,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  review.customerName.isNotEmpty 
                      ? review.customerName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              RatingDisplayWidget(
                rating: review.rating,
                size: 18,
                showCount: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Review comment
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class RatingSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown;

  const RatingSummaryWidget({
    Key? key,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Average rating display
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    RatingDisplayWidget(
                      rating: averageRating,
                      size: 20,
                      showCount: false,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews review${totalReviews != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rating breakdown
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = ratingBreakdown[rating] ?? 0;
                    final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$rating',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}