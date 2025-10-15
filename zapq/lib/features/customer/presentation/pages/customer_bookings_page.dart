import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/booking_provider.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/widgets/review_submission_widget.dart';
import '../../../../shared/models/business_model.dart';
import '../../../../shared/services/review_service.dart';

class CustomerBookingsPage extends StatefulWidget {
  const CustomerBookingsPage({super.key});

  @override
  State<CustomerBookingsPage> createState() => _CustomerBookingsPageState();
}

class _CustomerBookingsPageState extends State<CustomerBookingsPage> {
  String _selectedFilter = 'all';
  final ReviewService _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  void _loadBookings() async {
    final bookingProvider = context.read<BookingProvider>();
    final authProvider = context.read<AuthProvider>();
    
    final currentUser = authProvider.userModel;
    if (currentUser != null) {
      await bookingProvider.getUserBookings(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer-home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip('all', 'All'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('upcoming', 'Upcoming'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('completed', 'Completed'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('cancelled', 'Cancelled'),
                ),
              ],
            ),
          ),
          
          // Bookings list
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                if (bookingProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (bookingProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Bookings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bookingProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBookings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredBookings = _getFilteredBookings(bookingProvider.userBookings);

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all' 
                            ? 'No bookings yet'
                            : 'No ${_selectedFilter} bookings',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your bookings will appear here when you make appointments',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/customer-home'),
                          child: const Text('Book a Service'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadBookings(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: AppColors.primary),
    );
  }

  List<BookingModel> _getFilteredBookings(List<BookingModel> bookings) {
    if (_selectedFilter == 'all') return bookings;
    
    final now = DateTime.now();
    return bookings.where((booking) {
      switch (_selectedFilter) {
        case 'upcoming':
          return (booking.status == BookingStatus.confirmed || 
                  booking.status == BookingStatus.pending ||
                  booking.status == BookingStatus.inProgress) &&
                 booking.appointmentDate.isAfter(now.subtract(const Duration(days: 1)));
        case 'completed':
          return booking.status == BookingStatus.completed;
        case 'cancelled':
          return booking.status == BookingStatus.cancelled || 
                 booking.status == BookingStatus.noShow;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with business name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.businessName ?? 'Unknown Business',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Date and Time Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.appointmentDate.day}/${booking.appointmentDate.month}/${booking.appointmentDate.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.appointmentSlot ?? booking.timeSlot,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Service and price info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.content_cut, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        booking.serviceName ?? 'Unknown Service',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '₹${booking.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (booking.queueNumber != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.queue, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Queue Number',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${booking.queueNumber}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (booking.businessAddress?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.businessAddress!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (booking.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.notes!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Action buttons
            const SizedBox(height: 16),
            if (booking.status == BookingStatus.confirmed || 
                booking.status == BookingStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(booking),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBookingDetails(booking),
                      icon: const Icon(Icons.info, size: 18),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == BookingStatus.completed) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showBookingDetails(booking),
                      icon: const Icon(Icons.info, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(booking),
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Write Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // For cancelled or other status bookings, only show details
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showBookingDetails(booking),
                  icon: const Icon(Icons.info, size: 18),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.confirmed:
        color = Colors.orange;
        text = 'Confirmed';
        break;
      case BookingStatus.inProgress:
        color = Colors.blue;
        text = 'In Progress';
        break;
      case BookingStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case BookingStatus.noShow:
        color = Colors.grey;
        text = 'No Show';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _cancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel your booking at ${booking.businessName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final bookingProvider = context.read<BookingProvider>();
      final success = await bookingProvider.updateBookingStatus(booking.id, BookingStatus.cancelled);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings(); // Refresh the list
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.errorMessage ?? 'Failed to cancel booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBookingDetails(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.businessName ?? 'Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Service', booking.serviceName ?? 'Unknown'),
              _buildDetailRow('Date', '${booking.appointmentDate.day}/${booking.appointmentDate.month}/${booking.appointmentDate.year}'),
              _buildDetailRow('Time', booking.appointmentSlot ?? booking.timeSlot),
              _buildDetailRow('Price', '₹${booking.totalPrice.toStringAsFixed(0)}'),
              if (booking.queueNumber != null)
                _buildDetailRow('Queue Number', '#${booking.queueNumber}'),
              if (booking.businessAddress?.isNotEmpty == true)
                _buildDetailRow('Address', booking.businessAddress!),
              if (booking.notes?.isNotEmpty == true)
                _buildDetailRow('Notes', booking.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BookingModel booking) async {
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

        // Check if user has already reviewed this booking
    final hasReviewed = await _reviewService.hasCustomerReviewedBooking(
      user.id, 
      booking.businessId, 
      booking.id
    );

    if (hasReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted a review for this booking ✓'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create a business model from booking data
    final business = BusinessModel(
      id: booking.businessId,
      ownerId: '',
      name: booking.businessName ?? 'Unknown Business',
      description: '',
      category: '',
      address: booking.businessAddress ?? '',
      phoneNumber: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ReviewSubmissionWidget(
          business: business,
          customer: user,
          bookingId: booking.id,
          onReviewSubmitted: (review) async {
            print('🚀 CALLBACK: Review submission started');
            print('📋 CALLBACK: Review data: ${review.toJson()}');
            
            // Show loading indicator
            Navigator.of(context).pop(); // Close dialog first
            
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            print('💾 CALLBACK: Calling ReviewService.submitReview...');
            // Save review to Firestore
            final success = await _reviewService.submitReview(review);
            
            print('📤 CALLBACK: ReviewService returned: $success');
            
            // Close loading dialog
            if (mounted) Navigator.of(context).pop();
            
            if (success) {
              print('✅ CALLBACK: Review submitted successfully');
              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your review! ⭐'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } else {
              print('❌ CALLBACK: Review submission failed');
              // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to submit review. Please try again.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
            
            print('🏁 CALLBACK: Review submission completed');
          },
        ),
      ),
    );
  }
}
