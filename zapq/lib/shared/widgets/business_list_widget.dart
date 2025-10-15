import 'package:flutter/material.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/offer_model.dart';
import '../../../shared/services/business_sorting_service.dart';
import '../../../shared/widgets/enhanced_business_card.dart';
import '../../../core/theme/app_colors.dart';

class BusinessListWidget extends StatefulWidget {
  final List<BusinessModel> businesses;
  final List<OfferModel> offers;
  final String searchQuery;
  final Function(BusinessModel)? onBusinessTap;
  final Function(BusinessModel)? onFavoriteToggle;
  final List<String> favoriteBusinessIds;

  const BusinessListWidget({
    Key? key,
    required this.businesses,
    this.offers = const [],
    this.searchQuery = '',
    this.onBusinessTap,
    this.onFavoriteToggle,
    this.favoriteBusinessIds = const [],
  }) : super(key: key);

  @override
  State<BusinessListWidget> createState() => _BusinessListWidgetState();
}

class _BusinessListWidgetState extends State<BusinessListWidget> {
  SortOption _sortOption = SortOption.relevance;
  double? _minimumRating;
  bool _showFilterOptions = false;

  @override
  Widget build(BuildContext context) {
    final filteredBusinesses = _getFilteredAndSortedBusinesses();

    return Column(
      children: [
        // Sort and filter controls
        _buildFilterControls(),
        
        // Business count and sort info
        if (filteredBusinesses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredBusinesses.length} business${filteredBusinesses.length != 1 ? 'es' : ''} found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _getSortDescription(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        
        // Business list
        Expanded(
          child: filteredBusinesses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: filteredBusinesses.length,
                  itemBuilder: (context, index) {
                    final business = filteredBusinesses[index];
                    final businessOffers = widget.offers
                        .where((offer) => offer.businessId == business.id)
                        .toList();
                    
                    return EnhancedBusinessCard(
                      business: business,
                      offers: businessOffers,
                      onTap: () => widget.onBusinessTap?.call(business),
                      onFavorite: () => widget.onFavoriteToggle?.call(business),
                      isFavorite: widget.favoriteBusinessIds.contains(business.id),
                      showOffers: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Sort dropdown
              Expanded(
                child: DropdownButtonFormField<SortOption>(
                  value: _sortOption,
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: SortOption.values.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(_getSortOptionName(option)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOption = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Filter button
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilterOptions = !_showFilterOptions;
                  });
                },
                icon: Icon(
                  _showFilterOptions ? Icons.filter_list : Icons.filter_list_outlined,
                  color: _minimumRating != null ? AppColors.primary : Colors.grey[600],
                ),
              ),
            ],
          ),
          
          // Filter options
          if (_showFilterOptions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum Rating',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildRatingChip('Any', null),
                          _buildRatingChip('3.0+', 3.0),
                          _buildRatingChip('3.5+', 3.5),
                          _buildRatingChip('4.0+', 4.0),
                          _buildRatingChip('4.5+', 4.5),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingChip(String label, double? rating) {
    final isSelected = _minimumRating == rating;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _minimumRating = selected ? rating : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.searchQuery.isNotEmpty
                  ? 'No businesses found for "${widget.searchQuery}"'
                  : 'No businesses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _minimumRating != null
                  ? 'Try adjusting your rating filter or search terms'
                  : 'Try searching for something else',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (_minimumRating != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _minimumRating = null;
                  });
                },
                child: const Text('Clear Rating Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<BusinessModel> _getFilteredAndSortedBusinesses() {
    List<BusinessModel> filtered = List.from(widget.businesses);
    
    // Apply search filter
    if (widget.searchQuery.isNotEmpty) {
      filtered = BusinessSortingService.searchAndSort(
        filtered,
        widget.searchQuery,
        sortBy: _sortOption,
        minimumRating: _minimumRating,
      );
    } else {
      // Apply minimum rating filter
      if (_minimumRating != null) {
        filtered = BusinessSortingService.filterByMinimumRating(
          filtered,
          _minimumRating!,
        );
      }
      
      // Apply sorting
      switch (_sortOption) {
        case SortOption.rating:
          filtered = BusinessSortingService.sortByRating(filtered);
          break;
        case SortOption.reviewCount:
          filtered = BusinessSortingService.sortByReviewCount(filtered);
          break;
        case SortOption.relevance:
          filtered = BusinessSortingService.sortByRelevance(filtered);
          break;
        case SortOption.name:
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    }
    
    return filtered;
  }

  String _getSortOptionName(SortOption option) {
    switch (option) {
      case SortOption.relevance:
        return 'Best Match';
      case SortOption.rating:
        return 'Highest Rated';
      case SortOption.reviewCount:
        return 'Most Reviewed';
      case SortOption.name:
        return 'Name (A-Z)';
    }
  }

  String _getSortDescription() {
    switch (_sortOption) {
      case SortOption.relevance:
        return 'Sorted by relevance';
      case SortOption.rating:
        return 'Sorted by rating';
      case SortOption.reviewCount:
        return 'Sorted by review count';
      case SortOption.name:
        return 'Sorted alphabetically';
    }
  }
}

// Specialized widgets for different contexts
class TopRatedBusinessesWidget extends StatelessWidget {
  final List<BusinessModel> businesses;
  final List<OfferModel> offers;
  final Function(BusinessModel)? onBusinessTap;

  const TopRatedBusinessesWidget({
    Key? key,
    required this.businesses,
    this.offers = const [],
    this.onBusinessTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topRated = BusinessSortingService.getTopRatedBusinesses(
      businesses,
      minimumRating: 4.0,
      limit: 5,
    );

    if (topRated.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Rated Businesses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topRated.length,
            itemBuilder: (context, index) {
              final business = topRated[index];
              final businessOffers = offers
                  .where((offer) => offer.businessId == business.id)
                  .toList();
              
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  right: index < topRated.length - 1 ? 12 : 0,
                ),
                child: EnhancedBusinessCard(
                  business: business,
                  offers: businessOffers,
                  onTap: () => onBusinessTap?.call(business),
                  showOffers: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}