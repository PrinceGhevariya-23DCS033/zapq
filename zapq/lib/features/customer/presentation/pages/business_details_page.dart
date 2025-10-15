import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/business_model.dart';
import '../../../../shared/providers/booking_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/widgets/review_submission_widget.dart';
import '../../../../shared/widgets/customer_offers_widget.dart';
import '../../../../shared/services/review_service.dart';
import '../../../../shared/models/review_model.dart';
import '../../../../shared/providers/offer_provider.dart';

class BusinessDetailsPage extends StatefulWidget {
  final BusinessModel business;

  const BusinessDetailsPage({
    super.key,
    required this.business,
  });

  @override
  State<BusinessDetailsPage> createState() => _BusinessDetailsPageState();
}

class _BusinessDetailsPageState extends State<BusinessDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReviewService _reviewService = ReviewService();
  List<ReviewModel> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReviews();
    _loadUserBookings();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      print('🎯 BusinessDetailsPage: Loading active offers for business: ${widget.business.id}');
      final offerProvider = context.read<OfferProvider>();
      
      // Load ACTIVE offers specifically for this business (for customers)
      await offerProvider.loadActiveBusinessOffers(widget.business.id);
      
      // Also get the filtered offers for debugging
      final businessOffers = offerProvider.getOffersForBusiness(widget.business.id);
      print('✅ BusinessDetailsPage: Loaded ${businessOffers.length} active offers for business ${widget.business.id}');
      
      // Debug: Print offer details
      for (var offer in businessOffers) {
        print('📋 Offer: ${offer.title} - Active: ${offer.isActive} - Business: ${offer.businessId}');
        print('📅 Start: ${offer.startDate} - End: ${offer.endDate} - Now: ${DateTime.now()}');
      }
    } catch (e) {
      print('❌ BusinessDetailsPage: Error loading offers: $e');
    }
  }

  Future<void> _loadUserBookings() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    
    if (user != null) {
      final bookingProvider = context.read<BookingProvider>();
      await bookingProvider.getUserBookings(user.id);
    }
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _loadingReviews = true;
      });
      
      final reviews = await _reviewService.getBusinessReviews(widget.business.id);
      
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _loadingReviews = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with business image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.business.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Business thumbnail image or fallback
                  _buildBusinessHeaderImage(),
                  // Gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // TODO: Add to favorites
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites!')),
                  );
                },
                icon: const Icon(Icons.favorite_border, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Share business
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),

          // Business Quick Info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Status and rating row
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.business.isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.business.isActive ? Icons.check_circle : Icons.cancel,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.business.isActive ? 'Open' : 'Closed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Rating
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.business.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              ' (${widget.business.totalRatings})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick action buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showBookingDialog(context);
                            },
                            icon: const Icon(Icons.calendar_today, color: Colors.white),
                            label: const Text(
                              'Book Now',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Call business
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${widget.business.phoneNumber}...')),
                            );
                          },
                          icon: Icon(Icons.phone, color: AppColors.primary),
                          label: Text(
                            'Call',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Services', icon: Icon(Icons.room_service, size: 20)),
                  Tab(text: 'Photos', icon: Icon(Icons.photo_library, size: 20)),
                  Tab(text: 'About', icon: Icon(Icons.info_outline, size: 20)),
                  Tab(text: 'Reviews', icon: Icon(Icons.star_outline, size: 20)),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildPhotosTab(),
                _buildAboutTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 3 // Only show on Reviews tab
          ? FloatingActionButton.extended(
              onPressed: _showReviewDialog,
              icon: const Icon(Icons.rate_review),
              label: const Text('Write Review'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildServicesTab() {
    return Container(
      color: AppColors.background,
      child: widget.business.services.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No services available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.business.services.length,
              itemBuilder: (context, index) {
                final service = widget.business.services[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.content_cut,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    service.description.isNotEmpty 
                                        ? service.description 
                                        : 'Professional ${service.name.toLowerCase()} service',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${service.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${service.durationMinutes} min',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (service.maxCapacity > 1) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Group booking: Up to ${service.maxCapacity} people',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPhotosTab() {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Gallery Section
            _buildPhotoGallerySection(),
            
            // Special Offers Section
            const SizedBox(height: 24),
            Consumer<OfferProvider>(
              builder: (context, offerProvider, child) {
                if (offerProvider.isLoading) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Loading offers...', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                  );
                }
                
                final businessOffers = offerProvider.getOffersForBusiness(widget.business.id);
                print('🎯 Consumer: Found ${businessOffers.length} offers for business ${widget.business.id}');
                print('🎯 Consumer: Total active offers in provider: ${offerProvider.activeOffers.length}');
                print('🎯 Consumer: Loading state: ${offerProvider.isLoading}');
                print('🎯 Consumer: Error: ${offerProvider.errorMessage}');
                
                return CustomerOffersWidget(
                  offers: businessOffers,
                  onOfferTapped: (offer) {
                    // Show offer details
                    _showOfferDialog(offer);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  color: Colors.black54,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showOfferDialog(offer) {
    // TODO: Implement offer details dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Offer: ${offer.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAboutTab() {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.business, 'Business Name', widget.business.name),
                    _buildInfoRow(Icons.category, 'Category', widget.business.category),
                    _buildInfoRow(Icons.location_on, 'Address', widget.business.address),
                    _buildInfoRow(Icons.phone, 'Phone', widget.business.phoneNumber),
                    if (widget.business.email?.isNotEmpty == true)
                      _buildInfoRow(Icons.email, 'Email', widget.business.email!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Operating Hours Card (placeholder)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operating Hours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHoursRow('Monday - Friday', '9:00 AM - 8:00 PM'),
                    _buildHoursRow('Saturday', '9:00 AM - 6:00 PM'),
                    _buildHoursRow('Sunday', '10:00 AM - 4:00 PM'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Overall Rating
                        Column(
                          children: [
                            Text(
                              _getAverageRating().toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                final avgRating = _getAverageRating();
                                return Icon(
                                  index < avgRating.floor()
                                      ? Icons.star
                                      : index < avgRating
                                          ? Icons.star_half
                                          : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_getTotalReviewCount()} reviews',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        
                        // Rating Breakdown
                        Expanded(
                          child: Column(
                            children: List.generate(5, (index) {
                              final star = 5 - index;
                              final percentage = _calculateRatingPercentage(star);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Text(
                                      '$star',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${percentage.toInt()}%',
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
                    const SizedBox(height: 20),
                    
                    // Write Review Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showReviewDialog();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Write a Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Reviews List
            Text(
              'Customer Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Real Reviews from Firestore
            if (_loadingReviews) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_reviews.isNotEmpty) ...[
              ..._reviews.map((review) => _buildReviewItem(
                review.customerName,
                review.rating,
                review.comment,
                review.createdAt,
              )),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(32),
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
                    const SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to review this business!',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String name, double rating, String comment, DateTime date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    name[0],
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
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating.floor()
                                    ? Icons.star
                                    : index < rating
                                        ? Icons.star_half
                                        : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateRatingPercentage(int star) {
    if (_reviews.isEmpty) {
      return 0.0;
    }
    
    // Calculate actual percentage based on real reviews
    final starCount = _reviews.where((review) => review.rating.round() == star).length;
    final percentage = (starCount / _reviews.length) * 100;
    
    return percentage;
  }

  double _getAverageRating() {
    if (_reviews.isEmpty) {
      return 0.0;
    }
    
    final totalRating = _reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return totalRating / _reviews.length;
  }

  int _getTotalReviewCount() {
    return _reviews.length;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 30) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showReviewDialog() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to write a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For now, allow any logged-in user to write reviews
    // TODO: Later implement proper booking validation when booking system is fully working
    print('👤 User ${user.name} wants to write a review for business ${widget.business.name}');

    // Check if user has already reviewed this business
    final hasReviewed = await _reviewService.hasCustomerReviewedBooking(
      user.id, 
      widget.business.id, 
      null // Check for any review, not specific to booking
    );

    if (hasReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already reviewed this business ✓'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ReviewSubmissionWidget(
          business: widget.business,
          customer: user,
          onReviewSubmitted: (review) async {
            print('🚀 BUSINESS_DETAILS: Review submission started');
            
            // Close review dialog first
            Navigator.of(context).pop();
            
            // Store the main context before showing loading dialog
            final mainContext = context;
            
            // Show loading dialog and store its context
            BuildContext? loadingContext;
            showDialog(
              context: mainContext,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                loadingContext = dialogContext; // Store the loading dialog context
                return WillPopScope(
                  onWillPop: () async => false,
                  child: const Dialog(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text('Submitting review...'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );

            try {
              print('💾 BUSINESS_DETAILS: Calling ReviewService.submitReview...');
              
              // Save review to Firestore
              final success = await _reviewService.submitReview(review);
              
              print('📤 BUSINESS_DETAILS: ReviewService returned: $success');
              
              // Close loading dialog using its specific context
              if (loadingContext != null && mounted) {
                Navigator.of(loadingContext!).pop();
              }
              
              if (success) {
                print('✅ BUSINESS_DETAILS: Review submitted successfully, reloading reviews...');
                
                // Reload reviews to show the new one
                await _loadReviews();
                
                // Force a rebuild to show new reviews
                if (mounted) {
                  setState(() {});
                }
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your review! ⭐'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } else {
                print('❌ BUSINESS_DETAILS: Review submission failed');
                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to submit review. Please try again.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            } catch (e) {
              print('💥 BUSINESS_DETAILS: Exception in review submission: $e');
              
              // Ensure loading dialog is closed using its specific context
              if (loadingContext != null && mounted) {
                Navigator.of(loadingContext!).pop();
              }
              
              if (mounted) {
                ScaffoldMessenger.of(mainContext).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHeaderImage() {
    // Use profileImageUrl first, fallback to imageUrls, then default gradient
    String? imageUrl = widget.business.profileImageUrl;
    if ((imageUrl == null || imageUrl.isEmpty) && widget.business.imageUrls.isNotEmpty) {
      imageUrl = widget.business.imageUrls.first;
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Show business thumbnail image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading business header image: $error');
          return _buildFallbackHeaderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.primary,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      // Show fallback gradient with icon
      return _buildFallbackHeaderImage();
    }
  }

  Widget _buildFallbackHeaderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary,
          ],
        ),
      ),
      child: Icon(
        _getCategoryIcon(widget.business.category),
        size: 80,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildPhotoGallerySection() {
    // Combine profileImageUrl and imageUrls into one list
    List<String> allImages = [];
    
    // Add profile image first if available
    if (widget.business.profileImageUrl != null && widget.business.profileImageUrl!.isNotEmpty) {
      allImages.add(widget.business.profileImageUrl!);
    }
    
    // Add gallery images
    allImages.addAll(widget.business.imageUrls);
    
    if (allImages.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Gallery',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageDialog(allImages[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    allImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else {
      // Empty state
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No photos available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This business hasn\'t uploaded any photos yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salon':
        return Icons.content_cut;
      case 'spa':
        return Icons.spa;
      case 'restaurant':
        return Icons.restaurant;
      case 'clinic':
        return Icons.local_hospital;
      case 'gym':
        return Icons.fitness_center;
      case 'automotive':
        return Icons.directions_car;
      default:
        return Icons.business;
    }
  }

  void _showBookingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String? selectedTimeSlot;
    String? selectedService;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Book Appointment'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.business.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.business.category.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.business.address,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date Selection
                const Text(
                  'Select Date:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                        selectedTimeSlot = null; // Reset time slot when date changes
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Service Selection (moved to be first)
                if (widget.business.services.isNotEmpty) ...[
                  const Text(
                    'Select Service:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedService,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Choose a service'),
                    items: widget.business.services.map((service) {
                      return DropdownMenuItem<String>(
                        value: service.name,
                        child: Text('${service.name} - ₹${service.price}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedService = value;
                        selectedTimeSlot = null; // Reset time slot when service changes
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Time Slot Selection
                const Text(
                  'Select Time Slot:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey('${selectedDate.toIso8601String()}_${selectedService ?? 'no_service'}'),
                  future: selectedService != null ? _getAvailableTimeSlotsWithCapacity(widget.business, selectedDate, selectedService) : Future.value(<Map<String, dynamic>>[]),
                  builder: (context, snapshot) {
                    // Show message if no service selected
                    if (selectedService == null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please select a service first to see available time slots.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Loading available slots...', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }

                    final availableSlotsWithCapacity = snapshot.data ?? [];
                    
                    if (availableSlotsWithCapacity.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No available slots for this service and date. Please select another date.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableSlotsWithCapacity.map((slotData) {
                        final timeSlot = slotData['timeSlot'] as String;
                        final currentBookings = slotData['currentBookings'] as int;
                        final maxCapacity = slotData['maxCapacity'] as int;
                        final isSelected = selectedTimeSlot == timeSlot;
                        final isNearlyFull = currentBookings >= (maxCapacity * 0.8);
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedTimeSlot = timeSlot;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : 
                                     isNearlyFull ? Colors.orange.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : 
                                       isNearlyFull ? Colors.orange.shade300 : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeSlot,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (maxCapacity > 1) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '$currentBookings/$maxCapacity',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white70 : 
                                             isNearlyFull ? Colors.orange.shade700 : Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Booking info with automatic confirmation details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Instant Booking Confirmation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your appointment will be automatically confirmed once booked. The time slot will be reserved exclusively for you.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedTimeSlot != null && (widget.business.services.isEmpty || selectedService != null))
                  ? () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      _makeBooking(context, widget.business, selectedDate, selectedTimeSlot!, selectedService);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Book Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get available time slots for the selected date and service with capacity info using new slot system
  Future<List<Map<String, dynamic>>> _getAvailableTimeSlotsWithCapacity(BusinessModel business, DateTime date, String? selectedService) async {
    try {
      // Get the service ID for availability checking
      String serviceId = '';
      ServiceModel? serviceModel;
      if (selectedService != null && business.services.isNotEmpty) {
        serviceModel = business.services.firstWhere(
          (s) => s.name == selectedService,
          orElse: () => business.services.first,
        );
        serviceId = serviceModel.id;
      } else if (business.services.isNotEmpty) {
        serviceModel = business.services.first;
        serviceId = serviceModel.id;
      }

      if (serviceId.isEmpty) {
        return [];
      }

      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final dateStr = date.toIso8601String().split('T')[0];

      // Initialize slots for this service and date if they don't exist
      await bookingProvider.initializeSlotsForService(
        business.id,
        serviceId,
        dateStr,
        serviceModel?.maxCapacity ?? 1,
      );

      // Get available slots from the slot provider
      final availableSlots = await bookingProvider.getAvailableSlots(serviceId, dateStr);

      // Convert TimeSlotModel to the expected format
      return availableSlots.map((slot) => {
        'timeSlot': slot.time,
        'currentBookings': slot.currentBookings,
        'maxCapacity': slot.maxCapacity,
      }).toList();
    } catch (e) {
      print('❌ Error getting available time slots with capacity: $e');
      return [];
    }
  }

  void _makeBooking(BuildContext context, BusinessModel business, DateTime selectedDate, String timeSlot, String? selectedService) {
    final queueNumber = DateTime.now().millisecondsSinceEpoch % 1000;
    
    // Show booking confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Your booking at ${business.name} has been confirmed!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Queue Number:'),
                      Text(
                        '#$queueNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date:'),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Time Slot:'),
                      Text(
                        timeSlot,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (selectedService != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service:'),
                        Expanded(
                          child: Text(
                            selectedService,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Estimated wait time: 5-10 minutes before your slot',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              // Create booking using Firebase
              _createBooking(business, selectedDate, timeSlot, selectedService, queueNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'View in My Queue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBooking(BusinessModel business, DateTime date, String timeSlot, String? service, int queueNumber) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final bookingProvider = context.read<BookingProvider>();
      final user = authProvider.userModel;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ User not logged in. Please sign in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // CONSOLIDATED: Get service model and ID using single logic
      ServiceModel? selectedServiceModel;
      String serviceId = '';
      
      if (service != null && business.services.isNotEmpty) {
        try {
          selectedServiceModel = business.services.firstWhere(
            (s) => s.name == service,
            orElse: () => business.services.first,
          );
          serviceId = selectedServiceModel.id;
        } catch (e) {
          selectedServiceModel = business.services.isNotEmpty ? business.services.first : null;
          serviceId = selectedServiceModel?.id ?? 'default-service';
        }
      } else if (business.services.isNotEmpty) {
        selectedServiceModel = business.services.first;
        serviceId = selectedServiceModel.id;
      } else {
        serviceId = 'default-service';
      }

      final isStillAvailable = await bookingProvider.isSlotAvailable(
        business.id,
        serviceId,
        date,
        timeSlot,
      );

      if (!isStillAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Sorry, this time slot is no longer available. Please select another slot.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Find the selected service details (using same logic as availability check)
      final servicePrice = selectedServiceModel?.price ?? 500.0;
      final serviceName = selectedServiceModel?.name ?? service ?? 'General Service';
      final estimatedDuration = selectedServiceModel?.durationMinutes ?? 30;

      // Create booking model with automatic confirmation
      final booking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        businessId: business.id,
        customerId: user.id,
        customerName: user.name,
        customerPhone: user.phoneNumber,
        businessName: business.name,
        businessAddress: business.address,
        serviceId: serviceId, // Using the SAME service ID as availability check
        serviceName: serviceName,
        servicePrice: servicePrice,
        totalPrice: servicePrice, // Total price same as service price for single service
        appointmentDate: date,
        timeSlot: timeSlot,
        queueNumber: queueNumber,
        status: BookingStatus.pending, // Will be automatically confirmed by the provider
        estimatedDuration: estimatedDuration,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Show loading indicator with better messaging
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating your booking...'),
            ],
          ),
        ),
      );

      try {
        // Attempt to create booking with slot reservation
        final bookingResult = await bookingProvider.createBooking(booking);
        
        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        if (bookingResult) {
          // Booking successful
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✅ Booking confirmed! Queue #$queueNumber at ${business.name}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Booking failed - slot might have been taken
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Booking failed. The selected time slot may no longer be available.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        print('❌ Booking creation error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Booking failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Create booking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error creating booking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
