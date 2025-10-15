import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/analytics_service.dart';
import '../../../../shared/services/report_service.dart';
import '../../../../shared/models/booking_model.dart';

class BusinessAnalyticsPage extends StatefulWidget {
  const BusinessAnalyticsPage({super.key});

  @override
  State<BusinessAnalyticsPage> createState() => _BusinessAnalyticsPageState();
}

class _BusinessAnalyticsPageState extends State<BusinessAnalyticsPage>
    with TickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  late TabController _tabController;
  
  Map<String, dynamic> _financialData = {};
  Map<String, dynamic> _customerData = {};
  Map<String, dynamic> _serviceData = {};
  List<BookingModel> _recentBookings = [];
  bool _isLoading = true;
  String? _error;
  
  // Date range selection
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = '30 Days';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ownerUid = authProvider.user?.uid;
      
      if (ownerUid == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Find business ID
      final businessId = await _findBusinessIdByOwner(ownerUid);
      if (businessId == null) {
        setState(() {
          _error = 'No business found for this account';
          _isLoading = false;
        });
        return;
      }

      // Load all analytics data
      final financialData = await _analyticsService.getFinancialAnalytics(
        businessId, _startDate, _endDate);
      final customerData = await _analyticsService.getCustomerAnalytics(
        businessId, _startDate, _endDate);
      final serviceData = await _analyticsService.getServiceAnalytics(
        businessId, _startDate, _endDate);
      final recentBookings = await _analyticsService.getRecentBookings(
        businessId, limit: 10);

      // Debug logging to understand data loading
      print('📊 Analytics loaded successfully:');
      print('💰 Financial data: $financialData');
      print('👥 Customer data: $customerData');
      print('🔧 Service data: $serviceData');
      print('📋 Recent bookings count: ${recentBookings.length}');
      print('📈 Daily revenue data: ${financialData['dailyRevenue']}');

      setState(() {
        _financialData = financialData;
        _customerData = customerData;
        _serviceData = serviceData;
        _recentBookings = recentBookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _findBusinessIdByOwner(String ownerUid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerId', isEqualTo: ownerUid)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Business Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _downloadReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_rounded, size: 20)),
            Tab(text: 'Financial', icon: Icon(Icons.currency_rupee_rounded, size: 20)),
            Tab(text: 'Customers', icon: Icon(Icons.people_rounded, size: 20)),
            Tab(text: 'Services', icon: Icon(Icons.business_center_rounded, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildDateRangeSelector(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildFinancialTab(),
                          _buildCustomerTab(),
                          _buildServiceTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Period',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$_selectedPeriod • ${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
            onSelected: _onPeriodSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7 Days', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30 Days', child: Text('Last 30 Days')),
              const PopupMenuItem(value: '90 Days', child: Text('Last 3 Months')),
              const PopupMenuItem(value: '365 Days', child: Text('Last Year')),
              const PopupMenuItem(value: 'Custom', child: Text('Custom Range')),
            ],
          ),
        ],
      ),
    );
  }

  void _onPeriodSelected(String period) {
    DateTime now = DateTime.now();
    DateTime startDate;
    
    switch (period) {
      case '7 Days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30 Days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90 Days':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '365 Days':
        startDate = now.subtract(const Duration(days: 365));
        break;
      case 'Custom':
        _showCustomDatePicker();
        return;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }
    
    setState(() {
      _selectedPeriod = period;
      _startDate = startDate;
      _endDate = now;
    });
    
    _loadAnalytics();
  }

  void _showCustomDatePicker() {
    // TODO: Implement custom date range picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom date picker coming soon!')),
    );
  }

  void _downloadReport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text('Generating report...')),
            ],
          ),
        ),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessName = authProvider.user?.displayName ?? authProvider.user?.email ?? 'Your Business';

      // Generate report
      final reportPath = await ReportService.generateBusinessReport(
        businessName: businessName,
        startDate: _startDate,
        endDate: _endDate,
        financialData: _financialData,
        customerData: _customerData,
        serviceData: _serviceData,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Show report path dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Report Generated'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your business analytics report has been generated and saved to:'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          reportPath,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if it's still open
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStatsGrid(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinancialMetricsGrid(),
          const SizedBox(height: 24),
          _buildRevenueBreakdownChart(),
          const SizedBox(height: 24),
          _buildMonthlyTrendsChart(),
        ],
      ),
    );
  }

  Widget _buildCustomerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerMetricsGrid(),
          const SizedBox(height: 24),
          _buildCustomerGrowthChart(),
          const SizedBox(height: 24),
          _buildTopCustomersCard(),
        ],
      ),
    );
  }

  Widget _buildServiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServiceMetricsGrid(),
          const SizedBox(height: 24),
          _buildPopularServicesChart(),
          const SizedBox(height: 24),
          _buildServicePerformanceCard(),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                '₹${_formatNumber(_financialData['totalRevenue'] ?? 0)}',
                Icons.currency_rupee_rounded,
                Colors.green,
                '+${_financialData['revenueGrowth'] ?? 0}%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Bookings',
                '${_formatNumber(_financialData['totalBookings'] ?? 0)}',
                Icons.calendar_today_rounded,
                Colors.blue,
                '+${_financialData['bookingGrowth'] ?? 0}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'New Customers',
                '${_formatNumber(_customerData['newCustomers'] ?? 0)}',
                Icons.person_add_rounded,
                Colors.purple,
                '+${_customerData['customerGrowth'] ?? 0}%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Avg. Rating',
                '${(_customerData['averageRating'] ?? 0.0).toStringAsFixed(1)}',
                Icons.star_rounded,
                Colors.amber,
                '${_customerData['totalReviews'] ?? 0} reviews',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    if (number is int) return NumberFormat('#,###').format(number);
    if (number is double) return NumberFormat('#,###.##').format(number);
    return number.toString();
  }

  // Revenue chart with actual data visualization
  Widget _buildRevenueChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last ${_selectedPeriod}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildRevenueVisualization(),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueVisualization() {
    final dailyRevenue = _financialData['dailyRevenue'] as Map<String, dynamic>? ?? {};
    
    // Debug: Print the daily revenue data
    print('🏷️ CHART: Daily revenue data: $dailyRevenue');
    print('🏷️ CHART: Financial data keys: ${_financialData.keys.toList()}');
    
    if (dailyRevenue.isEmpty) {
      // Show sample/demo data if no real data is available
      final today = DateTime.now();
      final sampleData = <String, double>{};
      
      // Generate sample data for the last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        sampleData[dayKey] = 0.0; // Show zero values
      }
      
      return Column(
        children: [
          // Show message about no data
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No revenue data yet. Start accepting bookings to see trends here.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Show empty chart
          Expanded(
            child: _buildEmptyChart(sampleData),
          ),
        ],
      );
    }

    return _buildChartWithData(dailyRevenue);
  }

  Widget _buildEmptyChart(Map<String, double> sampleData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sampleData.entries.map((entry) {
          final date = DateTime.parse('${entry.key}T00:00:00');
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Empty bar
                Flexible(
                  child: Container(
                    width: 20,
                    height: 5, // Minimal height for empty state
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Compact date label
                Text(
                  DateFormat('dd').format(date),
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartWithData(Map<String, dynamic> dailyRevenue) {
    // Sort data by date and get the last few days
    final sortedEntries = dailyRevenue.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    // Take the last 7 days or all available data if less
    final recentEntries = sortedEntries.length > 7 
        ? sortedEntries.sublist(sortedEntries.length - 7)
        : sortedEntries;

    if (recentEntries.isEmpty) {
      return const Center(
        child: Text(
          'No recent revenue data',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Find max revenue for scaling
    final maxRevenue = recentEntries
        .map((e) => e.value as double)
        .reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        // Summary info
        if (recentEntries.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Peak: ₹${_formatNumber(maxRevenue.toInt())} • ${recentEntries.length} days',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Chart
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: recentEntries.map((entry) {
          final revenue = entry.value as double;
          final date = DateTime.parse('${entry.key}T00:00:00');
          final height = maxRevenue > 0 ? (revenue / maxRevenue) * 100 : 0.0;
          
          return Tooltip(
            message: '₹${_formatNumber(revenue.toInt())} on ${DateFormat('MMM dd').format(date)}',
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bar (main focus)
                  Flexible(
                    child: Container(
                      width: 20,
                      height: height.clamp(5.0, 60.0), // Reduced max height to fit in available space
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.green,
                            Colors.green.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Compact date label
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recentBookings.take(3).map((booking) => _buildActivityItem(
            booking.customerName ?? 'Unknown Customer',
            'Booked ${booking.serviceName ?? 'Service'}',
            '₹${(booking.servicePrice ?? 0.0).toStringAsFixed(2)}',
            booking.createdAt,
          )),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String name, String action, String amount, DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  action,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormat('MMM dd').format(date),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                '₹${_formatNumber(_financialData['totalRevenue'] ?? 0)}',
                Icons.currency_rupee_rounded,
                Colors.green,
                '+${_financialData['revenueGrowth'] ?? 0}% vs last period',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Avg. Booking Value',
                '₹${_formatNumber(_financialData['averageBookingValue'] ?? 0)}',
                Icons.price_check_rounded,
                Colors.blue,
                '${_financialData['totalBookings'] ?? 0} bookings',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Previous Period',
                '₹${_formatNumber(_financialData['previousRevenue'] ?? 0)}',
                Icons.history_rounded,
                Colors.grey,
                '${_financialData['previousBookings'] ?? 0} bookings',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Growth Rate',
                '${_financialData['revenueGrowth'] ?? 0}%',
                Icons.trending_up_rounded,
                (_financialData['revenueGrowth'] ?? 0) >= 0 ? Colors.green : Colors.red,
                'Revenue growth',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdownChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${_formatNumber(_financialData['totalRevenue'] ?? 0)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRevenueBreakdownItems(),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownItems() {
    final dailyRevenue = _financialData['dailyRevenue'] as Map<String, dynamic>? ?? {};
    final totalRevenue = _financialData['totalRevenue'] as double? ?? 0;
    
    if (dailyRevenue.isEmpty) {
      return const Center(
        child: Text(
          'No revenue data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Get top 5 days by revenue
    final sortedDays = dailyRevenue.entries.toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));
    
    return Column(
      children: sortedDays.take(5).map((entry) {
        final date = entry.key;
        final revenue = entry.value as double;
        final percentage = totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('MMM dd').format(DateTime.parse('${date}T00:00:00')),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '₹${_formatNumber(revenue)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyTrendsChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTrendVisualization(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendVisualization() {
    final dailyRevenue = _financialData['dailyRevenue'] as Map<String, dynamic>? ?? {};
    
    if (dailyRevenue.isEmpty) {
      return const Center(
        child: Text('No trend data available', style: TextStyle(color: Colors.grey)),
      );
    }

    // Create a simple bar chart visualization
    final maxRevenue = dailyRevenue.values.isEmpty ? 1.0 : 
        dailyRevenue.values.map((v) => v as double).reduce((a, b) => a > b ? a : b);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: dailyRevenue.entries.map((entry) {
          final revenue = entry.value as double;
          final height = (revenue / maxRevenue) * 200;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 24,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.green, Colors.green.withValues(alpha: 0.6)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd').format(DateTime.parse('${entry.key}T00:00:00')),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Customers',
                '${_formatNumber(_customerData['totalCustomers'] ?? 0)}',
                Icons.people_rounded,
                Colors.blue,
                '+${_customerData['customerGrowth'] ?? 0}% growth',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Repeat Customers',
                '${_formatNumber(_customerData['repeatCustomers'] ?? 0)}',
                Icons.repeat_rounded,
                Colors.purple,
                '${(_customerData['customerRetentionRate'] ?? 0).toStringAsFixed(1)}% retention',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg. Rating',
                '${(_customerData['averageRating'] ?? 0.0).toStringAsFixed(1)}',
                Icons.star_rounded,
                Colors.amber,
                '${_customerData['totalReviews'] ?? 0} reviews',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Bookings/Customer',
                '${(_customerData['averageBookingsPerCustomer'] ?? 0.0).toStringAsFixed(1)}',
                Icons.calendar_today_rounded,
                Colors.teal,
                'Average frequency',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerGrowthChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Rating Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildRatingDistribution(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final ratingDistribution = _customerData['ratingDistribution'] as Map<int, int>? ?? 
        {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final totalReviews = _customerData['totalReviews'] as int? ?? 0;

    return Column(
      children: List.generate(5, (index) {
        final starCount = 5 - index;
        final count = ratingDistribution[starCount] ?? 0;
        final percentage = totalReviews > 0 ? (count / totalReviews) * 100 : 0.0;
        
        Color barColor;
        switch (starCount) {
          case 5:
            barColor = Colors.green;
            break;
          case 4:
            barColor = Colors.lightGreen;
            break;
          case 3:
            barColor = Colors.amber;
            break;
          case 2:
            barColor = Colors.orange;
            break;
          default:
            barColor = Colors.red;
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(
                '$starCount',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: Text(
                  '$count (${percentage.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTopCustomersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Customers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => _buildTopCustomerItem(
            'Customer ${index + 1}',
            '${5 - index} bookings',
            '₹${(500 - index * 100).toStringAsFixed(2)}',
          )),
        ],
      ),
    );
  }

  Widget _buildTopCustomerItem(String name, String bookings, String spent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            child: Text(
              name[0],
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  bookings,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            spent,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Services',
                '${_formatNumber(_serviceData['totalServices'] ?? 0)}',
                Icons.business_center_rounded,
                Colors.indigo,
                'Available services',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Most Popular',
                _serviceData['mostPopularService'] ?? 'N/A',
                Icons.trending_up_rounded,
                Colors.orange,
                'Top service',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Most Profitable',
                _serviceData['mostProfitableService'] ?? 'N/A',
                Icons.currency_rupee_rounded,
                Colors.green,
                'Highest revenue',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Service Efficiency',
                '85%',
                Icons.speed_rounded,
                Colors.purple,
                'Performance score',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPopularServicesChart() {
    final serviceBookingCount = _serviceData['serviceBookingCount'] as Map<String, int>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (serviceBookingCount.isEmpty)
            const Center(child: Text('No service data available'))
          else
            ...serviceBookingCount.entries.take(5).map((entry) {
              final maxBookings = serviceBookingCount.values.isEmpty ? 1 : 
                  serviceBookingCount.values.reduce((a, b) => a > b ? a : b);
              final percentage = (entry.value / maxBookings) * 100;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value} bookings',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildServicePerformanceCard() {
    final serviceRevenue = _serviceData['serviceRevenue'] as Map<String, double>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Revenue Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (serviceRevenue.isEmpty)
            const Center(child: Text('No revenue data available'))
          else
            ...serviceRevenue.entries.take(5).map((entry) => 
              _buildServiceRevenueItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildServiceRevenueItem(String serviceName, double revenue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              serviceName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₹${_formatNumber(revenue)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }


}