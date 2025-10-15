import 'package:flutter/material.dart';
import '../../../shared/models/review_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/theme/app_colors.dart';

class ReviewSubmissionWidget extends StatefulWidget {
  final BusinessModel business;
  final UserModel customer;
  final String? bookingId;
  final Future<void> Function(ReviewModel) onReviewSubmitted;

  const ReviewSubmissionWidget({
    Key? key,
    required this.business,
    required this.customer,
    required this.onReviewSubmitted,
    this.bookingId,
  }) : super(key: key);

  @override
  State<ReviewSubmissionWidget> createState() => _ReviewSubmissionWidgetState();
}

class _ReviewSubmissionWidgetState extends State<ReviewSubmissionWidget> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rate Your Experience',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Business info
          Text(
            'How was your visit to ${widget.business.name}?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Star rating
          Center(
            child: Column(
              children: [
                Text(
                  'Rating',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = (index + 1).toDouble();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          size: 40,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(_rating),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Comment section
          Text(
            'Tell others about your experience',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Share details about your experience...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Good';
    }
  }

  Future<void> _submitReview() async {
    print('🚀 WIDGET: _submitReview called');
    
    if (_commentController.text.trim().isEmpty) {
      print('❌ WIDGET: Empty comment, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a comment about your experience'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('🔄 WIDGET: Setting isSubmitting to true');
    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🎯 WIDGET: Creating review model...');
      print('📊 WIDGET: Business ID: ${widget.business.id}');
      print('👤 WIDGET: Customer ID: ${widget.customer.id}');
      print('⭐ WIDGET: Rating: $_rating');
      print('💬 WIDGET: Comment: ${_commentController.text.trim()}');
      
      final review = ReviewModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        businessId: widget.business.id,
        customerId: widget.customer.id,
        customerName: widget.customer.name,
        customerEmail: widget.customer.email,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bookingId: widget.bookingId,
      );

      print('📤 WIDGET: About to call onReviewSubmitted callback...');
      print('📋 WIDGET: Review data: ${review.toJson()}');
      
      // Let the callback handle everything (navigation, saving, messages)
      await widget.onReviewSubmitted(review);
      
      print('✅ WIDGET: Callback completed successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// Helper function to show review submission modal
Future<void> showReviewSubmissionDialog({
  required BuildContext context,
  required BusinessModel business,
  required UserModel customer,
  required Future<void> Function(ReviewModel) onReviewSubmitted,
  String? bookingId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReviewSubmissionWidget(
          business: business,
          customer: customer,
          onReviewSubmitted: onReviewSubmitted,
          bookingId: bookingId,
        ),
      );
    },
  );
}