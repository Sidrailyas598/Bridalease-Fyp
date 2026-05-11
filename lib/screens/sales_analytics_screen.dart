// lib/screens/sales_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

final supabase = Supabase.instance.client;

class SalesAnalyticsScreen extends StatefulWidget {
  final User user;

  const SalesAnalyticsScreen({
    super.key,
    required this.user,
  });

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> with TickerProviderStateMixin {
  String _selectedPeriod = 'weekly'; // weekly, monthly, yearly
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _topDresses = [];
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _averageOrderValue = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final NumberFormat _currencyFormat = NumberFormat("#,##0");
  final List<String> _periods = ['weekly', 'monthly', 'yearly'];
  final Map<String, String> _periodLabels = {
    'weekly': 'This Week',
    'monthly': 'This Month',
    'yearly': 'This Year',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vendorId = widget.user.id;
      
      // Get all orders for this vendor
      final ordersResponse = await supabase
          .from('orders')
          .select('''
            *,
            order_items!inner(*)
          ''')
          .eq('order_items.vendor_id', vendorId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = List.from(ordersResponse);
      
      // Calculate analytics based on selected period
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case 'weekly':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'yearly':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }
      
      final filteredOrders = orders.where((order) {
        final orderDate = DateTime.parse(order['created_at']);
        return orderDate.isAfter(startDate);
      }).toList();
      
      // Calculate totals
      _totalOrders = filteredOrders.length;
      _totalRevenue = filteredOrders.fold(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble());
      _averageOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;
      
      // Prepare sales data for chart
      _salesData = _prepareSalesData(filteredOrders, startDate, now);
      
      // Get top selling dresses
      final dressSales = <String, Map<String, dynamic>>{};
      for (var order in filteredOrders) {
        final items = order['order_items'] as List;
        for (var item in items) {
          final dressId = item['dress_id'].toString();
          final dressName = item['dress_name'] ?? 'Unknown';
          final quantity = (item['quantity'] as num).toInt();
          final price = (item['price'] as num).toDouble();
          
          if (!dressSales.containsKey(dressId)) {
            dressSales[dressId] = {
              'name': dressName,
              'quantity': 0,
              'revenue': 0.0,
              'image_url': item['image_url'],
            };
          }
          dressSales[dressId]!['quantity'] = dressSales[dressId]!['quantity'] + quantity;
          dressSales[dressId]!['revenue'] = dressSales[dressId]!['revenue'] + (price * quantity);
        }
      }
      
      _topDresses = dressSales.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
      
      _topDresses = _topDresses.take(5).toList();
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _prepareSalesData(List<Map<String, dynamic>> orders, DateTime startDate, DateTime endDate) {
    final Map<String, double> dailySales = {};
    
    if (_selectedPeriod == 'weekly') {
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final key = DateFormat('EEE').format(date);
        dailySales[key] = 0;
      }
      
      for (var order in orders) {
        final orderDate = DateTime.parse(order['created_at']);
        final key = DateFormat('EEE').format(orderDate);
        dailySales[key] = (dailySales[key] ?? 0) + (order['total_amount'] as num).toDouble();
      }
      
      return dailySales.entries.map((e) => {
        'label': e.key,
        'amount': e.value,
      }).toList();
      
    } else if (_selectedPeriod == 'monthly') {
      final daysInMonth = DateTime(endDate.year, endDate.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final key = i.toString();
        dailySales[key] = 0;
      }
      
      for (var order in orders) {
        final orderDate = DateTime.parse(order['created_at']);
        final key = orderDate.day.toString();
        dailySales[key] = (dailySales[key] ?? 0) + (order['total_amount'] as num).toDouble();
      }
      
      // Take every 3rd day for cleaner chart
      final entries = dailySales.entries.toList();
      final filtered = <Map<String, dynamic>>[];
      for (int i = 0; i < entries.length; i++) {
        if (i % 3 == 0 || i == entries.length - 1) {
          filtered.add({
            'label': entries[i].key,
            'amount': entries[i].value,
          });
        }
      }
      return filtered;
      
    } else {
      for (int i = 0; i < 12; i++) {
        final date = DateTime(startDate.year, i + 1, 1);
        final key = DateFormat('MMM').format(date);
        dailySales[key] = 0;
      }
      
      for (var order in orders) {
        final orderDate = DateTime.parse(order['created_at']);
        final key = DateFormat('MMM').format(orderDate);
        dailySales[key] = (dailySales[key] ?? 0) + (order['total_amount'] as num).toDouble();
      }
      
      return dailySales.entries.map((e) => {
        'label': e.key,
        'amount': e.value,
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text(
          'Sales Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF660033),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF660033).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF660033)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF660033)),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'weekly', child: Text('Weekly')),
              const PopupMenuItem(value: 'monthly', child: Text('Monthly')),
              const PopupMenuItem(value: 'yearly', child: Text('Yearly')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildStatsCards(),
                    const SizedBox(height: 16),
                    _buildSalesChart(),
                    const SizedBox(height: 16),
                    _buildTopDresses(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF660033), Color(0xFF883366)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF660033).withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading analytics...',
            style: TextStyle(color: Color(0xFF660033), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadAnalytics();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF660033), Color(0xFF883366)],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _periodLabels[period]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF660033).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.currency_rupee, size: 18, color: Color(0xFF660033)),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Total Revenue',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Rs.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 2),
                    Text(
                      _currencyFormat.format(_totalRevenue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF660033),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag, size: 18, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Total Orders',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$_totalOrders',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    if (_salesData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No sales data available',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final maxAmount = _salesData.map((e) => e['amount'] as double).reduce((a, b) => a > b ? a : b);
    final maxY = maxAmount > 0 ? maxAmount * 1.1 : 1000.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, size: 18, color: Color(0xFF660033)),
              SizedBox(width: 8),
              Text(
                'Sales Trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _salesData.length) {
                          return Text(
                            _salesData[index]['label'],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _salesData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data['amount'] as double,
                        color: const Color(0xFF660033),
                        width: 30,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDresses() {
    if (_topDresses.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, size: 18, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Top Selling Dresses',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._topDresses.asMap().entries.map((entry) {
            final index = entry.key;
            final dress = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF660033), Color(0xFF883366)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: dress['image_url'] != null
                          ? Image.network(
                              dress['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 25),
                            )
                          : const Icon(Icons.image, size: 25, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dress['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dress['quantity']} sold • Rs. ${_currencyFormat.format(dress['revenue'])}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${((dress['revenue'] / _totalRevenue) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}