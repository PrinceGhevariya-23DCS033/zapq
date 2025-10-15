import 'package:flutter/material.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/offer_model.dart';
import '../../../core/theme/app_colors.dart';

class EnhancedBusinessCard extends StatelessWidget {
  final BusinessModel business;
  final List<OfferModel> offers;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool showOffers;

  const EnhancedBusinessCard({
    Key? key,
    required this.business,
    this.offers = const [],
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.showOffers = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeOffers = offers.where((offer) => 
      offer.isActive && 
      offer.startDate.isBefore(DateTime.now()) && 
      offer.endDate.isAfter(DateTime.now())
    ).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image and basic info
            Container(
              height: 200,
              child: Stack(
                children: [
                  // Business image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildBusinessImage(),
                  ),
                  
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // Business info overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                business.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onFavorite != null)
                              IconButton(
                                onPressed: onFavorite,
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          business.category,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                business.address,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Rating badge
                  if (business.rating > 0)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRatingColor(business.rating),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              business.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    business.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Rating and reviews row
                  if (business.rating > 0 || business.reviewCount > 0)
                    Row(
                      children: [
                        _buildStarRating(business.rating),
                        const SizedBox(width: 8),
                        Text(
                          '${business.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${business.reviewCount} reviews)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  
                  if (business.rating > 0 || business.reviewCount > 0)
                    const SizedBox(height: 12),
                  
                  // Photo gallery preview
                  if (business.galleryUrls.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photos',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: business.galleryUrls.length.clamp(0, 5),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < business.galleryUrls.length - 1 ? 8 : 0,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    business.galleryUrls[index],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, size: 24),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (business.galleryUrls.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${business.galleryUrls.length - 5} more photos',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  
                  // Operating hours
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCurrentOperatingStatus(),
                        style: TextStyle(
                          color: _isCurrentlyOpen() ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Active offers
                  if (showOffers && activeOffers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${activeOffers.length} Special Offer${activeOffers.length > 1 ? 's' : ''} Available',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                if (activeOffers.isNotEmpty)
                                  Text(
                                    activeOffers.first.title,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.red,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessImage() {
    print('🖼️ Business: ${business.name}');
    print('📸 ProfileImageUrl: ${business.profileImageUrl}');
    print('📷 ImageUrls: ${business.imageUrls}');
    print('🖼️ GalleryUrls: ${business.galleryUrls}');
    
    if (business.profileImageUrl != null && business.profileImageUrl!.isNotEmpty) {
      print('✅ Using profileImageUrl: ${business.profileImageUrl}');
      return Image.network(
        business.profileImageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading profileImageUrl: $error');
          return _buildFallbackImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else if (business.imageUrls.isNotEmpty) {
      print('✅ Using imageUrls.first: ${business.imageUrls.first}');
      return Image.network(
        business.imageUrls.first,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading imageUrls.first: $error');
          return _buildFallbackImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      print('⚠️ No images available, using fallback');
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        _getCategoryIcon(),
        size: 64,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _getCategoryIcon() {
    final category = business.category.toLowerCase();
    if (category.contains('restaurant') || category.contains('food')) {
      return Icons.restaurant;
    } else if (category.contains('salon') || category.contains('beauty')) {
      return Icons.content_cut;
    } else if (category.contains('medical') || category.contains('health')) {
      return Icons.medical_services;
    } else if (category.contains('shop') || category.contains('store')) {
      return Icons.store;
    } else {
      return Icons.business;
    }
  }

  String _getCurrentOperatingStatus() {
    if (business.operatingHours.isEmpty) {
      return 'Hours not available';
    }

    final now = DateTime.now();
    final today = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][now.weekday - 1];
    final todayHours = business.operatingHours[today];

    if (todayHours == null || todayHours.isEmpty) {
      return 'Closed today';
    }

    if (todayHours.toLowerCase() == 'closed') {
      return 'Closed today';
    }

    if (_isCurrentlyOpen()) {
      return 'Open now • $todayHours';
    } else {
      return 'Closed • Opens $todayHours';
    }
  }

  bool _isCurrentlyOpen() {
    if (business.operatingHours.isEmpty) return false;

    final now = DateTime.now();
    final today = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][now.weekday - 1];
    final todayHours = business.operatingHours[today];

    if (todayHours == null || todayHours.isEmpty || todayHours.toLowerCase() == 'closed') {
      return false;
    }

    try {
      final parts = todayHours.split('-');
      if (parts.length != 2) return false;

      final openTime = _parseTime(parts[0].trim());
      final closeTime = _parseTime(parts[1].trim());
      final currentTime = TimeOfDay.now();

      return _isTimeBetween(currentTime, openTime, closeTime);
    } catch (e) {
      return false;
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Handles cases where business is open past midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}