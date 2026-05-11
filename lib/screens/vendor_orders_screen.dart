import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dress_inspection_screen.dart';  // ✅ Add this import

final supabase = Supabase.instance.client;

class VendorOrdersScreen extends StatefulWidget {
  final User user;
  const VendorOrdersScreen({super.key, required this.user});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _returnRequests = [];
  bool _loading = true;
  bool _loadingReturns = true;
  Map<String, dynamic>? _earnings;
  String? _processingOrderId;
  String? _processingReturnId;
  int _selectedTab = 0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadOrders();
    _loadEarnings();
    _loadReturnRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _loading = true);

      debugPrint('========== LOADING VENDOR ORDERS ==========');
      debugPrint('🔍 Vendor ID: ${widget.user.id}');

      final ordersResponse = await supabase
          .from('orders')
          .select('*, users!orders_user_id_fkey(full_name, phone, email)')
          .eq('vendor_id', widget.user.id)
          .order('created_at', ascending: false);

      debugPrint('📦 Orders found: ${ordersResponse.length}');

      if (ordersResponse.isEmpty) {
        setState(() {
          _orders = [];
          _loading = false;
        });
        return;
      }

      final allItemsResponse = await supabase.from('order_items').select('*');
      
      final Set<String> orderIdSet = ordersResponse.map((o) => o['id'].toString()).toSet();
      final List<Map<String, dynamic>> filteredItems = [];
      
      for (var item in allItemsResponse) {
        if (orderIdSet.contains(item['order_id'].toString())) {
          filteredItems.add(item);
        }
      }

      final Map<String, List<Map<String, dynamic>>> itemsByOrder = {};
      for (var item in filteredItems) {
        final orderId = item['order_id'].toString();
        final cleanItem = {
          'id': item['id'],
          'dress_id': item['dress_id'],
          'dress_name': item['dress_name'] ?? 'Dress',
          'quantity': item['quantity'] ?? 1,
          'price': (item['price'] as num?)?.toDouble() ?? 0,
          'item_total': (item['item_total'] as num?)?.toDouble() ?? 0,
          'image_url': item['image_url'],
          'vendor_id': item['vendor_id'],
        };
        
        if (!itemsByOrder.containsKey(orderId)) {
          itemsByOrder[orderId] = [];
        }
        itemsByOrder[orderId]!.add(cleanItem);
      }

      final List<Map<String, dynamic>> ordersWithItems = [];
      for (var order in ordersResponse) {
        final orderId = order['id'].toString();
        final items = itemsByOrder[orderId] ?? [];
        order['order_items'] = items;
        ordersWithItems.add(order);
      }

      setState(() {
        _orders = ordersWithItems;
        _loading = false;
      });

    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadReturnRequests() async {
    try {
      setState(() => _loadingReturns = true);
      
      final response = await supabase
          .from('return_requests')
          .select('*, orders!inner(*)')
          .eq('vendor_id', widget.user.id)
          .order('requested_at', ascending: false);
      
      setState(() {
        _returnRequests = List<Map<String, dynamic>>.from(response);
        _loadingReturns = false;
      });
      
      debugPrint('📦 Return requests found: ${_returnRequests.length}');
      
    } catch (e) {
      debugPrint('❌ Error loading return requests: $e');
      setState(() => _loadingReturns = false);
    }
  }

  Future<void> _loadEarnings() async {
    try {
      final response = await supabase
          .from('vendor_earnings')
          .select()
          .eq('vendor_id', widget.user.id);

      double total = 0, pending = 0, paid = 0;
      for (var earning in response) {
        total += (earning['vendor_payout'] as num?)?.toDouble() ?? 0;
        if (earning['status'] == 'pending') {
          pending += (earning['vendor_payout'] as num?)?.toDouble() ?? 0;
        } else if (earning['status'] == 'paid') {
          paid += (earning['vendor_payout'] as num?)?.toDouble() ?? 0;
        }
      }
      setState(() {
        _earnings = {'total': total, 'pending': pending, 'paid': paid};
      });
    } catch (e) {
      debugPrint('❌ Error loading earnings: $e');
    }
  }

  Future<void> _confirmOrder(String orderId) async {
    setState(() => _processingOrderId = orderId);
    try {
      final now = DateTime.now().toIso8601String();
      await supabase
          .from('orders')
          .update({'status': 'confirmed', 'vendor_confirmed_at': now})
          .eq('id', orderId);

      final order = _orders.firstWhere((o) => o['id'] == orderId);
      
      if (order['user_id'] != null) {
        await supabase.from('notifications').insert({
          'user_id': order['user_id'],
          'type': 'order_confirmed',
          'title': '✅ Order Confirmed',
          'message': 'Your order #${orderId.substring(0, 8)} has been confirmed',
          'data': {'order_id': orderId},
          'created_at': now,
        });
      }

      _loadOrders();
      _loadEarnings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order confirmed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error confirming order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _processingOrderId = null);
    }
  }

  // ✅ Open Inspection Screen
  Future<void> _openInspection(Map<String, dynamic> request) async {
    final order = request['orders'] as Map<String, dynamic>;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DressInspectionScreen(
          order: order,
          returnRequest: request,
        ),
      ),
    );
    
    if (result == true) {
      _loadReturnRequests();
      _loadOrders();
    }
  }

  String _getShortOrderId(String orderId) {
    return orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
  }

  Widget _buildOrderImage(String? imageUrl, String dressName) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade100, Colors.purple.shade100],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            dressName.isNotEmpty ? dressName[0].toUpperCase() : 'D',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF660033),
            ),
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.pink.shade100, Colors.purple.shade100],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                dressName.isNotEmpty ? dressName[0].toUpperCase() : 'D',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 50,
            height: 50,
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _orders.where((o) => o['status'] == 'pending').length;
    final confirmedCount = _orders.where((o) => o['status'] == 'confirmed').length;
    final deliveredCount = _orders.where((o) => o['status'] == 'delivered').length;
    final pendingReturns = _returnRequests.where((r) => r['return_status'] == 'pending').length;
    final pendingInspection = _returnRequests.where((r) => r['return_status'] == 'pending_inspection').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        title: const Text('Vendor Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF660033),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Orders (${_orders.length})'),
            Tab(text: 'Returns (${pendingReturns + pendingInspection})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Orders Tab
          RefreshIndicator(
            onRefresh: _loadOrders,
            color: const Color(0xFF660033),
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF660033)))
                : _orders.isEmpty
                    ? _buildEmptyOrders()
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _buildStatCard('Pending', pendingCount, Colors.orange),
                                const SizedBox(width: 12),
                                _buildStatCard('Confirmed', confirmedCount, Colors.blue),
                                const SizedBox(width: 12),
                                _buildStatCard('Delivered', deliveredCount, Colors.green),
                              ],
                            ),
                          ),
                          if (_earnings != null)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF660033), Color(0xFF99004C)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total Earnings', style: TextStyle(color: Colors.white70)),
                                        Text(
                                          'Rs ${(_earnings!['total'] as double).toStringAsFixed(0)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Pending: Rs ${(_earnings!['pending'] as double).toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                return _buildOrderCard(order);
                              },
                            ),
                          ),
                        ],
                      ),
          ),
          // Return Requests Tab
          RefreshIndicator(
            onRefresh: _loadReturnRequests,
            color: const Color(0xFF660033),
            child: _loadingReturns
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF660033)))
                : _returnRequests.isEmpty
                    ? _buildEmptyReturns()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _returnRequests.length,
                        itemBuilder: (context, index) {
                          final request = _returnRequests[index];
                          return _buildReturnRequestCard(request);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ✅ Updated Return Request Card with Inspection Button
  Widget _buildReturnRequestCard(Map<String, dynamic> request) {
    final order = request['orders'] as Map<String, dynamic>;
    final status = request['return_status'];
    final isProcessing = _processingReturnId == request['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status == 'pending_inspection' 
                  ? Colors.purple.withOpacity(0.05)
                  : Colors.orange.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${_getShortOrderId(order['id'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF660033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getReturnStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getReturnStatusText(status),
                        style: TextStyle(
                          color: _getReturnStatusColor(status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.parse(request['requested_at'])),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF660033).withOpacity(0.1),
                      child: Text(
                        order['customer_name']?[0]?.toUpperCase() ?? 'C',
                        style: const TextStyle(
                          color: Color(0xFF660033),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['customer_name'] ?? 'Customer',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            order['contact_number'] ?? 'No phone',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Return Reason: ${request['return_reason']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // ✅ INSPECTION BUTTON - for pending_inspection status
                if (status == 'pending_inspection')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : () => _openInspection(request),
                      icon: const Icon(Icons.preview, size: 18),
                      label: const Text('Start Inspection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                
                // Approve/Reject buttons for pending status
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : () => _approveReturn(request['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isProcessing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing ? null : () => _rejectReturn(request['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  
                if (status == 'approved')
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Return Approved - Waiting for pickup',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  
                if (status == 'completed')
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Return Completed',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  
                if (status == 'rejected')
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel, color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Return Rejected',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Helper method for return status text
  String _getReturnStatusText(String status) {
    switch (status) {
      case 'pending_inspection': return 'PENDING INSPECTION';
      case 'pending': return 'PENDING';
      case 'approved': return 'APPROVED';
      case 'completed': return 'COMPLETED';
      case 'rejected': return 'REJECTED';
      default: return status.toUpperCase();
    }
  }

  // ✅ Approve Return Request
  Future<void> _approveReturn(String requestId) async {
    setState(() => _processingReturnId = requestId);
    
    try {
      final now = DateTime.now().toIso8601String();
      
      final request = _returnRequests.firstWhere((r) => r['id'] == requestId);
      final orderId = request['order_id'];
      
      await supabase
          .from('return_requests')
          .update({
            'return_status': 'approved',
            'approved_at': now,
          })
          .eq('id', requestId);
      
      await supabase
          .from('orders')
          .update({
            'return_status': 'approved',
          })
          .eq('id', orderId);
      
      await supabase.from('deliveries').insert({
        'order_id': orderId,
        'rider_id': null,
        'status': 'return_assigned',
        'type': 'return',
        'assigned_at': now,
        'created_at': now,
      });
      
      await supabase.from('notifications').insert({
        'user_id': request['user_id'],
        'user_type': 'bride',
        'type': 'return_approved',
        'title': '✅ Return Request Approved',
        'message': 'Your return request has been approved. A rider will be assigned for pickup.',
        'data': {'order_id': orderId, 'return_id': requestId},
        'created_at': now,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return request approved!'), backgroundColor: Colors.green),
      );
      
      _loadReturnRequests();
      _loadOrders();
      
    } catch (e) {
      debugPrint('Error approving return: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _processingReturnId = null);
    }
  }

  // ✅ Reject Return Request
  Future<void> _rejectReturn(String requestId) async {
    setState(() => _processingReturnId = requestId);
    
    try {
      final request = _returnRequests.firstWhere((r) => r['id'] == requestId);
      final orderId = request['order_id'];
      
      await supabase
          .from('return_requests')
          .update({
            'return_status': 'rejected',
          })
          .eq('id', requestId);
      
      await supabase
          .from('orders')
          .update({
            'return_status': 'rejected',
          })
          .eq('id', orderId);
      
      await supabase.from('notifications').insert({
        'user_id': request['user_id'],
        'user_type': 'bride',
        'type': 'return_rejected',
        'title': '❌ Return Request Rejected',
        'message': 'Your return request has been rejected. Please contact support for assistance.',
        'data': {'order_id': orderId, 'return_id': requestId},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return request rejected!'), backgroundColor: Colors.orange),
      );
      
      _loadReturnRequests();
      _loadOrders();
      
    } catch (e) {
      debugPrint('Error rejecting return: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _processingReturnId = null);
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final items = order['order_items'] as List? ?? [];
    final bride = order['users'] ?? {};
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final statusColor = _getStatusColor(status);
    final vendorEarning = totalAmount * 0.8;
    final isRental = order['order_type'] == 'rent';
    final returnStatus = order['return_status'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${_getShortOrderId(order['id'])}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF660033),
                            ),
                          ),
                          if (isRental)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'RENTAL',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(order['created_at'])),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(DateTime.parse(order['created_at'])),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF660033).withOpacity(0.1),
                      child: Text(
                        (bride['full_name']?[0] ?? 'C').toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF660033),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bride['full_name'] ?? order['customer_name'] ?? 'Customer',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            bride['phone'] ?? order['contact_number'] ?? 'No phone',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRental 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isRental ? 'RENTAL' : 'PURCHASE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isRental ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (order['delivery_address'] != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order['delivery_address'],
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (isRental && status == 'delivered')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: returnStatus == 'completed' 
                          ? Colors.green.shade50 
                          : returnStatus == 'approved'
                              ? Colors.blue.shade50
                              : returnStatus == 'requested'
                                  ? Colors.orange.shade50
                                  : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          returnStatus == 'completed' 
                              ? Icons.check_circle
                              : returnStatus == 'approved'
                                  ? Icons.delivery_dining
                                  : returnStatus == 'requested'
                                      ? Icons.access_time
                                      : Icons.info_outline,
                          size: 14,
                          color: returnStatus == 'completed' 
                              ? Colors.green.shade700
                              : returnStatus == 'approved'
                                  ? Colors.blue.shade700
                                  : returnStatus == 'requested'
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            returnStatus == 'completed' 
                                ? 'Return completed successfully'
                                : returnStatus == 'approved'
                                    ? 'Return approved - Pickup arranged'
                                    : returnStatus == 'requested'
                                        ? 'Return requested by customer'
                                        : 'No return request yet',
                            style: TextStyle(
                              fontSize: 11,
                              color: returnStatus == 'completed' 
                                  ? Colors.green.shade700
                                  : returnStatus == 'approved'
                                      ? Colors.blue.shade700
                                      : returnStatus == 'requested'
                                          ? Colors.orange.shade700
                                          : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (isRental && order['rental_start_date'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.purple.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Rental: ${DateFormat('dd MMM').format(DateTime.parse(order['rental_start_date']))} - ${DateFormat('dd MMM').format(DateTime.parse(order['rental_end_date']))}',
                          style: TextStyle(fontSize: 10, color: Colors.purple.shade700),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                const Text(
                  'Order Items',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF660033)),
                ),
                const SizedBox(height: 8),
                
                if (items.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final itemPrice = (item['price'] as num?)?.toDouble() ?? 0;
                      final quantity = item['quantity'] ?? 1;
                      final totalItemPrice = itemPrice * quantity;
                      
                      return Row(
                        children: [
                          _buildOrderImage(item['image_url'], item['dress_name'] ?? 'Dress'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['dress_name'] ?? 'Dress',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Rs ${itemPrice.toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'x $quantity',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rs ${totalItemPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF660033)),
                          ),
                        ],
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No items found in this order',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text('Rs ${totalAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Delivery Charges', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text(
                            order['delivery_charges'] != null 
                                ? 'Rs ${(order['delivery_charges'] as num).toStringAsFixed(0)}'
                                : 'Free',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            'Rs ${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF660033)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your Earnings (80%)', style: TextStyle(fontSize: 11, color: Colors.green[700])),
                          Text(
                            'Rs ${vendorEarning.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processingOrderId == order['id'] ? null : () => _confirmOrder(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _processingOrderId == order['id']
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Confirm Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                
                if (status == 'confirmed')
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text('Order Confirmed - Ready for Delivery', style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  
                if (status == 'delivered')
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text('Order Delivered', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getReturnStatusColor(String status) {
    switch (status) {
      case 'pending_inspection': return Colors.purple;
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF660033).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
            ),
            child: Icon(Icons.inbox, size: 60, color: const Color(0xFF660033).withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text('No Orders Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
          const SizedBox(height: 8),
          Text('When customers place orders, they will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyReturns() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF660033).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
            ),
            child: Icon(Icons.assignment_return, size: 60, color: const Color(0xFF660033).withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text('No Return Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
          const SizedBox(height: 8),
          Text('Return requests from customers will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}