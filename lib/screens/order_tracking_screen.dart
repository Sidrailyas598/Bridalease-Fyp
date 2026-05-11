import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final User user;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.user,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _delivery;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _loadTrackingDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrackingDetails() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final orderResponse = await supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .maybeSingle();

      if (orderResponse == null) {
        setState(() {
          _errorMessage = 'Order not found';
          _loading = false;
        });
        return;
      }

      _order = orderResponse;

      final deliveryResponse = await supabase
          .from('deliveries')
          .select()
          .eq('order_id', widget.orderId)
          .maybeSingle();

      if (deliveryResponse != null) {
        _delivery = deliveryResponse;
      }

      final itemsResponse = await supabase
          .from('order_items')
          .select()
          .eq('order_id', widget.orderId);

      _items = List<Map<String, dynamic>>.from(itemsResponse);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading tracking: $e');
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  String _getOrderStatusText(String? status) {
    if (status == null) return 'Order Placed';
    switch (status.toLowerCase()) {
      case 'pending': return 'Order Placed';
      case 'confirmed': return 'Order Confirmed';
      case 'assigned': return 'Rider Assigned';
      case 'picked': return 'Picked Up';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  int _getCurrentStep() {
    final orderStatus = _order?['status']?.toLowerCase() ?? '';
    final deliveryStatus = _delivery?['status']?.toLowerCase() ?? '';

    if (orderStatus == 'cancelled') return -1;
    if (orderStatus == 'delivered') return 4;
    if (deliveryStatus == 'delivered') return 4;
    if (deliveryStatus == 'picked') return 3;
    if (deliveryStatus == 'assigned') return 2;
    if (orderStatus == 'confirmed') return 1;
    return 0;
  }

  String _getEstimatedDelivery() {
    final orderStatus = _order?['status']?.toLowerCase() ?? '';
    final createdAt = _order?['created_at'];
    
    if (orderStatus == 'delivered') return 'Delivered';
    
    if (createdAt != null && createdAt is String) {
      try {
        final orderDate = DateTime.parse(createdAt);
        final estimatedDate = orderDate.add(const Duration(days: 3));
        return DateFormat('dd MMM yyyy').format(estimatedDate);
      } catch (e) {
        return '3-5 business days';
      }
    }
    return '3-5 business days';
  }

  String _getRiderInfo() {
    if (_delivery != null && _delivery!['rider_id'] != null) {
      return 'Rider assigned for delivery';
    }
    return 'Waiting for rider assignment';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Pending';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateStr));
    } catch (e) {
      return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getCurrentStep();
    final isCancelled = _order?['status']?.toLowerCase() == 'cancelled';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF660033)),
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
      ),
      body: _loading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildOrderHeader(),
                            const SizedBox(height: 20),
                            if (!isCancelled) _buildTimeline(currentStep),
                            if (!isCancelled) const SizedBox(height: 20),
                            _buildDeliveryInfo(),
                            const SizedBox(height: 16),
                            if (!isCancelled) _buildRiderInfo(),
                            const SizedBox(height: 16),
                            if (_items.isNotEmpty) _buildOrderItems(),
                            if (isCancelled) _buildCancelledInfo(),
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
                  offset: const Offset(0, 3),
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
            'Loading tracking details...',
            style: TextStyle(color: Color(0xFF660033), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTrackingDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    final status = _order!['status']?.toLowerCase() ?? 'pending';
    final isDelivered = status == 'delivered';
    final isCancelled = status == 'cancelled';
    final totalAmount = _order!['total_amount'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCancelled
            ? const LinearGradient(
                colors: [Colors.grey, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF660033), Color(0xFF883366)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isCancelled ? Colors.grey : const Color(0xFF660033)).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${widget.orderId.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isDelivered ? Icons.check_circle : (isCancelled ? Icons.cancel : Icons.shopping_bag),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getOrderStatusText(_order!['status']),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDelivered ? 'DELIVERED' : (isCancelled ? 'CANCELLED' : 'ACTIVE'),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                _formatDate(_order!['created_at']),
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Rs.', style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(width: 2),
              Text(
                NumberFormat('#,##0').format(totalAmount),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(int currentStep) {
    final List<Map<String, dynamic>> steps = [
      {'title': 'Order Placed', 'icon': Icons.shopping_bag_outlined, 'subtitle': 'Your order has been received', 'step': 0},
      {'title': 'Order Confirmed', 'icon': Icons.check_circle_outline, 'subtitle': 'Vendor has confirmed your order', 'step': 1},
      {'title': 'Rider Assigned', 'icon': Icons.delivery_dining, 'subtitle': 'Rider is on the way to pickup', 'step': 2},
      {'title': 'Picked Up', 'icon': Icons.local_shipping, 'subtitle': 'Your order is on the way', 'step': 3},
      {'title': 'Delivered', 'icon': Icons.home, 'subtitle': 'Order delivered successfully', 'step': 4},
    ];

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
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, size: 16, color: Color(0xFF660033)),
              SizedBox(width: 6),
              Text(
                'Order Timeline',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Icon Column
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: currentStep > steps[i]['step']
                              ? const LinearGradient(
                                  colors: [Color(0xFF660033), Color(0xFF883366)],
                                )
                              : (currentStep == steps[i]['step']
                                  ? const LinearGradient(
                                      colors: [Color(0xFF660033), Color(0xFF883366)],
                                    )
                                  : null),
                          color: currentStep > steps[i]['step'] || currentStep == steps[i]['step']
                              ? null
                              : Colors.grey.shade200,
                        ),
                        child: Icon(
                          currentStep > steps[i]['step'] ? Icons.check : steps[i]['icon'] as IconData,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 2,
                          height: 50,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: currentStep > steps[i]['step'] ? const Color(0xFF660033) : Colors.grey.shade200,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right side - Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            steps[i]['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: currentStep >= steps[i]['step'] ? FontWeight.bold : FontWeight.normal,
                              color: currentStep >= steps[i]['step'] ? const Color(0xFF660033) : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (currentStep == steps[i]['step'])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF660033).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF660033)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[i]['subtitle'] as String,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      if (_getStepDate(steps[i]['step'] as int) != 'Pending')
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 10, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              _getStepDate(steps[i]['step'] as int),
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getStepDate(int step) {
    switch (step) {
      case 0:
        return _formatDate(_order!['created_at']);
      case 1:
        return _formatDate(_order!['confirmed_at']);
      case 2:
        return _formatDate(_delivery?['assigned_at']);
      case 3:
        return _formatDate(_delivery?['picked_at']);
      case 4:
        return _formatDate(_delivery?['delivered_at']);
      default:
        return '';
    }
  }

  Widget _buildDeliveryInfo() {
    final isDelivered = _order?['status']?.toLowerCase() == 'delivered';
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDelivered ? Colors.green.shade50 : Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered ? Icons.check_circle : Icons.local_shipping,
              size: 20,
              color: isDelivered ? Colors.green.shade700 : Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDelivered ? 'Delivered On' : 'Estimated Delivery',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  isDelivered ? _formatDate(_delivery?['delivered_at']) : _getEstimatedDelivery(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF660033),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderInfo() {
    final isAssigned = _delivery != null && _delivery!['rider_id'] != null;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF660033).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAssigned ? Icons.motorcycle : Icons.person_outline,
              size: 20,
              color: const Color(0xFF660033),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rider Status',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  _getRiderInfo(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                if (isAssigned && _delivery!['rider_name'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Rider: ${_delivery!['rider_name']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final totalAmount = _order!['total_amount'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              Icon(Icons.shopping_bag, size: 16, color: Color(0xFF660033)),
              SizedBox(width: 6),
              Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item['image_url'] != null
                        ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 25))
                        : const Icon(Icons.image, size: 25, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['dress_name'] ?? 'Dress',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qty: ${item['quantity'] ?? 1}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF660033).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Rs.', style: TextStyle(fontSize: 10, color: Color(0xFF660033))),
                      const SizedBox(width: 2),
                      Text(
                        '${(item['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF660033),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF660033).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('Rs.', style: TextStyle(fontSize: 12, color: Color(0xFF660033), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Text(
                      NumberFormat('#,##0').format(totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF660033),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.cancel, size: 40, color: Colors.red.shade400),
          const SizedBox(height: 10),
          const Text(
            'Order Cancelled',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _order!['cancellation_reason'] ?? 'No reason provided',
            style: TextStyle(fontSize: 13, color: Colors.red.shade600),
            textAlign: TextAlign.center,
          ),
          if (_order!['cancelled_at'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Cancelled on: ${_formatDate(_order!['cancelled_at'])}',
              style: TextStyle(fontSize: 11, color: Colors.red.shade400),
            ),
          ],
        ],
      ),
    );
  }
}