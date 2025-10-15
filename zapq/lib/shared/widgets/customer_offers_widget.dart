import 'package:flutter/material.dart';
import '../../../shared/models/offer_model.dart';
import '../../../core/theme/app_colors.dart';

class CustomerOffersWidget extends StatelessWidget {
  final List<OfferModel> offers;
  final Function(OfferModel)? onOfferTapped;

  const CustomerOffersWidget({
    Key? key,
    required this.offers,
    this.onOfferTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The offers should already be filtered for active ones by the OfferProvider
    final activeOffers = offers;

    print('🎯 CustomerOffersWidget: Received ${offers.length} offers');
    
    // Debug: Print each offer details
    for (var offer in offers) {
      print('📋 CustomerOffersWidget - Offer: ${offer.title}');
      print('   📅 Active: ${offer.isActive}, Start: ${offer.startDate}, End: ${offer.endDate}');
      print('   🏢 Business ID: ${offer.businessId}');
      print('   🕐 Current time: ${DateTime.now()}');
      print('   ✅ Valid: ${offer.isActive && offer.startDate.isBefore(DateTime.now()) && offer.endDate.isAfter(DateTime.now())}');
    }
    
    if (activeOffers.isEmpty) {
      // Show debug info instead of hiding completely
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Special Offers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      offers.isEmpty 
                        ? 'No offers available at the moment' 
                        : 'No active offers available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.local_offer,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Special Offers',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (activeOffers.length > 1)
                Text(
                  '${activeOffers.length} offers',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: activeOffers.length,
            itemBuilder: (context, index) {
              final offer = activeOffers[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < activeOffers.length - 1 ? 12 : 0,
                ),
                child: OfferCard(
                  offer: offer,
                  onTap: () => onOfferTapped?.call(offer),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback? onTap;

  const OfferCard({
    Key? key,
    required this.offer,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  if (offer.posterUrl != null)
                    Image.network(
                      offer.posterUrl!,
                      width: 280,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 280,
                          height: 120,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      width: 280,
                      height: 120,
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
                      child: const Icon(
                        Icons.local_offer,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  
                  // Discount badge
                  if (offer.discountPercentage != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${offer.discountPercentage!.toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Description
                    Text(
                      offer.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Price info
                    if (offer.originalPrice != null && offer.discountedPrice != null)
                      Row(
                        children: [
                          Text(
                            '\$${offer.discountedPrice!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${offer.originalPrice!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Valid until
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Valid until ${_formatDate(offer.endDate)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Full-screen offer details dialog
class OfferDetailsDialog extends StatelessWidget {
  final OfferModel offer;

  const OfferDetailsDialog({
    Key? key,
    required this.offer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Offer Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster image
              if (offer.posterUrl != null)
                Container(
                  width: double.infinity,
                  height: 250,
                  child: Image.network(
                    offer.posterUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      offer.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Discount info
                    if (offer.discountPercentage != null ||
                        (offer.originalPrice != null && offer.discountedPrice != null))
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_offer,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (offer.discountPercentage != null)
                                    Text(
                                      '${offer.discountPercentage!.toInt()}% OFF',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (offer.originalPrice != null && offer.discountedPrice != null)
                                    Row(
                                      children: [
                                        Text(
                                          '\$${offer.discountedPrice!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '\$${offer.originalPrice!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 18,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Description
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Validity period
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Valid Period',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatDate(offer.startDate)} - ${_formatDate(offer.endDate)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Terms and conditions
                    if (offer.terms.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Terms & Conditions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: offer.terms.map((term) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  term,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Show offer details
void showOfferDetails(BuildContext context, OfferModel offer) {
  showDialog(
    context: context,
    builder: (context) => OfferDetailsDialog(offer: offer),
  );
}