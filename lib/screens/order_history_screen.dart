import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_tracking_screen.dart';
import 'return_request_screen.dart';

final supabase = Supabase.instance.client;

class OrderHistoryScreen extends StatefulWidget {
  final User user;

  const OrderHistoryScreen({super.key, required this.user});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _processingOrderId;
  String? _errorMessage;

  // Support contact info
  final String supportPhone = '+923125178619';
  final String supportEmail = 'support@bridalease.com';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // ✅ Launch phone dialer with fallback
  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showContactDialog('Call Support', supportPhone, Icons.phone);
    }
  }

  // ✅ Launch email with fallback
  Future<void> _emailSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Return%20Request%20Support&body=Hello%20Support%20Team,%0D%0A%0D%0AI%20need%20help%20with%20my%20return%20request.%0D%0A%0D%0AOrder%20ID:%20%0D%0A%0D%0ARegards,',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showContactDialog('Email Support', supportEmail, Icons.email);
    }
  }

  // ✅ Show dialog with contact info to copy
  void _showContactDialog(String title, String contactInfo, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: const Color(0xFF660033), size: 24),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to open default app. Please contact us at:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                contactInfo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: contactInfo));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied to clipboard: $contactInfo'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 Loading orders for user: ${widget.user.id}');
      
      final response = await supabase
          .from('orders')
          .select()
          .eq('user_id', widget.user.id)
          .order('created_at', ascending: false);

      debugPrint('📦 Found ${response.length} orders');

      if (response.isEmpty) {
        setState(() {
          _orders = [];
          _loading = false;
        });
        return;
      }

      // ✅ Get return requests in bulk
      final orderIds = response.map((o) => o['id']).toList();
      final returnRequestsResponse = await supabase
          .from('return_requests')
          .select('order_id, return_status, requested_at')
          .inFilter('order_id', orderIds);
      
      final returnRequestsMap = <String, Map<String, dynamic>>{};
      for (var req in returnRequestsResponse) {
        returnRequestsMap[req['order_id']] = req;
      }

      final List<Map<String, dynamic>> ordersWithDetails = [];
      
      for (var order in response) {
        try {
          // ✅ Fetch delivery details
          final deliveryResponse = await supabase
              .from('deliveries')
              .select()
              .eq('order_id', order['id'])
              .limit(1)
              .maybeSingle();
          
          if (deliveryResponse != null) {
            order['delivery_status'] = deliveryResponse['status'];
            order['delivery'] = deliveryResponse;
          }
          
          // ✅ Fetch order items
          final itemsResponse = await supabase
              .from('order_items')
              .select()
              .eq('order_id', order['id']);
          
          order['order_items'] = itemsResponse;
          
          // ✅ Add return request info
          final returnReq = returnRequestsMap[order['id']];
          if (returnReq != null) {
            order['has_return_request'] = true;
            order['return_status'] = returnReq['return_status'];
          } else {
            order['has_return_request'] = false;
          }
          
          debugPrint('✅ Processed order ${order['id']} - Status: ${order['status']}');
          
        } catch (e) {
          debugPrint('⚠️ Error fetching details for order ${order['id']}: $e');
        }
        
        ordersWithDetails.add(order);
      }
      
      // ✅ Update state with fresh data
      if (mounted) {
        setState(() {
          _orders = ordersWithDetails;
          _loading = false;
          _processingOrderId = null;
        });
        
        debugPrint('📊 Final orders count: ${_orders.length}');
      }

    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
          _processingOrderId = null;
        });
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final order = _orders.firstWhere((o) => o['id'] == orderId);
    final delivery = order['delivery'];
    
    if (delivery != null && 
        (delivery['status'] == 'assigned' || delivery['status'] == 'picked')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot cancel order. Rider has already been assigned.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Changed mind, Found better option, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() {
      _processingOrderId = orderId;
    });

    try {
      final now = DateTime.now().toIso8601String();
      
      // ✅ Update order status
      await supabase
          .from('orders')
          .update({
            'status': 'cancelled',
            'cancelled_at': now,
            'cancellation_reason': reason,
          })
          .eq('id', orderId);

      debugPrint('✅ Order $orderId updated to cancelled');

      // ✅ Update delivery if exists
      if (delivery != null) {
        await supabase
            .from('deliveries')
            .update({'status': 'cancelled'})
            .eq('order_id', orderId);
        debugPrint('✅ Delivery for order $orderId cancelled');
      }

      // ✅ Update dress status back to available
      if (order['order_items'] != null) {
        for (var item in order['order_items']) {
          if (item['dress_id'] != null) {
            await supabase
                .from('dresses')
                .update({'status': 'available'})
                .eq('id', item['dress_id']);
            debugPrint('✅ Dress ${item['dress_id']} status updated to available');
          }
        }
      }

      // ✅ Send notification to vendor
      if (order['vendor_id'] != null) {
        await supabase.from('notifications').insert({
          'user_id': order['vendor_id'],
          'user_type': 'vendor',
          'type': 'order_cancelled',
          'title': 'Order Cancelled',
          'message': 'Order #${orderId.substring(0, 8)} has been cancelled. Reason: $reason',
          'data': {'order_id': orderId, 'cancelled_by': 'bride'},
          'created_at': now,
        });
        debugPrint('✅ Notification sent to vendor');
      }

      // ✅ IMPORTANT: Force refresh orders list from database
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully!'), backgroundColor: Colors.green),
        );
        
        // ✅ Clear processing state and reload
        setState(() {
          _processingOrderId = null;
        });
        
        // ✅ Reload orders with fresh data
        await _loadOrders();
      }

    } catch (e) {
      debugPrint('❌ Error cancelling order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _processingOrderId = null;
        });
      }
    }
  }

  bool _canCancel(String status, Map<String, dynamic>? delivery) {
    if (!['pending', 'awaiting_verification', 'confirmed'].contains(status.toLowerCase())) {
      return false;
    }
    if (delivery != null && 
        (delivery['status'] == 'assigned' || delivery['status'] == 'picked')) {
      return false;
    }
    return true;
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  // ✅ Return status widget
  Widget _getReturnStatusWidget(Map<String, dynamic> order) {
    final returnStatus = order['return_status'];
    
    if (returnStatus == 'completed') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(height: 8),
            const Text(
              'Return Completed',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              'Your security deposit has been refunded to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    if (returnStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 24),
            const SizedBox(height: 8),
            const Text(
              'Return Rejected',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              'Your return request has been rejected. Please contact support for assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _callSupport,
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _emailSupport,
                    icon: const Icon(Icons.email, size: 16),
                    label: const Text('Email Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Support: $supportPhone | $supportEmail',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (returnStatus == 'pending_inspection' || returnStatus == 'pending_approval' || returnStatus == 'approved') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.access_time, color: Colors.orange, size: 24),
            const SizedBox(height: 8),
            const Text(
              'Return Request Submitted',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
            ),
            const SizedBox(height: 4),
            Text(
              'Your request has been submitted. Vendor will inspect the dress and process your refund.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.support_agent, color: Color(0xFF660033)),
            onSelected: (value) {
              if (value == 'call') _callSupport();
              if (value == 'email') _emailSupport();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'call',
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 18),
                    SizedBox(width: 8),
                    Text('Call Support'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'email',
                child: Row(
                  children: [
                    Icon(Icons.email, size: 18),
                    SizedBox(width: 8),
                    Text('Email Support'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/flowers_bg.png"),
                fit: BoxFit.cover,
                opacity: 0.05,
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF660033)))
                : _errorMessage != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.error_outline, size: 60, color: Colors.red.shade400)),
                        const SizedBox(height: 20),
                        Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _loadOrders, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF660033)),
                          child: const Text('Try Again')),
                      ]))
                    : _orders.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: const Color(0xFF660033).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))]),
                              child: Icon(Icons.shopping_bag_outlined, size: 70, color: const Color(0xFF660033).withOpacity(0.4))),
                            const SizedBox(height: 24),
                            const Text('No Orders Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
                            const SizedBox(height: 10),
                            Text('Your orders will appear here', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                          ]))
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            color: const Color(0xFF660033),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                return TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 300 + (index * 50)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, double value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 30 * (1 - value)), child: child)),
                                  child: _buildOrderCard(order),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final isDelivered = status.toLowerCase() == 'delivered';
    final isCancelled = status.toLowerCase() == 'cancelled';
    final isProcessingThisOrder = _processingOrderId == order['id'];
    final isRental = order['order_type'] == 'rent';
    final hasReturnRequest = order['has_return_request'] ?? false;
    final returnStatus = order['return_status'];
    final delivery = order['delivery'];
    final canCancel = _canCancel(status, delivery);
    
    int daysLeft = 0;
    if (isRental && order['rental_end_date'] != null) {
      final endDate = DateTime.parse(order['rental_end_date']);
      daysLeft = endDate.difference(DateTime.now()).inDays;
    }
    
    final hasReturn = hasReturnRequest;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isRental ? [const Color(0xFF660033), const Color(0xFF883366)] : [const Color(0xFF660033), const Color(0xFF99004C)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('#${order['id'].toString().substring(0, 8).toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          if (isRental) 
                            Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                              child: const Text('RENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(_formatDate(order['created_at']), style: const TextStyle(fontSize: 9, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min,
                    children: [Icon(_getStatusIcon(status), size: 10, color: Colors.white), const SizedBox(width: 3),
                      Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))]),
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
                    Expanded(child: _buildDetailChip(icon: Icons.shopping_bag_outlined, label: order['order_type']?.toUpperCase() ?? 'PURCHASE', color: const Color(0xFF660033))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDetailChip(icon: Icons.payment_outlined, label: order['payment_method']?.toUpperCase() ?? 'COD', color: const Color(0xFF660033))),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (order['order_items'] != null)
                  Container(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(color: const Color(0xFF660033).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [Icon(Icons.shopping_bag, size: 14, color: const Color(0xFF660033)), const SizedBox(width: 6),
                      Text('${(order['order_items'] as List).length} item(s)', style: TextStyle(fontSize: 12, color: const Color(0xFF660033), fontWeight: FontWeight.w500))])),
                
                if (isRental && !isDelivered && !isCancelled && daysLeft > 0 && !hasReturn)
                  Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.purple.shade700),
                      const SizedBox(width: 6),
                      Expanded(child: Text('$daysLeft days remaining', style: TextStyle(fontSize: 10, color: Colors.purple.shade700))),
                    ])),
                
                const Divider(height: 20),
                
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF660033).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('Rs ${NumberFormat('#,##0').format(order['total_amount'] ?? 0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF660033))),
                    ),
                  ]),
                
                const SizedBox(height: 16),
                
                // ✅ Show cancellation reason if order is cancelled
                if (isCancelled && order['cancellation_reason'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.red.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Cancellation Reason',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['cancellation_reason'],
                          style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                        ),
                        if (order['cancelled_at'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Cancelled on: ${_formatDate(order['cancelled_at'])}',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (hasReturn) ...[
                  _getReturnStatusWidget(order),
                ]
                else if (isDelivered && isRental && daysLeft >= -3) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReturnRequestScreen(order: order, user: widget.user),
                        ),
                      ).then((_) => _loadOrders()),
                      icon: const Icon(Icons.assignment_return, size: 16),
                      label: const Text('Request Return'),
                    ),
                  ),
                ]
                else if (isDelivered && !isRental) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Order Delivered Successfully',
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
                else if (isCancelled) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Order Cancelled',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
                else if (!isDelivered && !isCancelled) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF660033),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderTrackingScreen(orderId: order['id'], user: widget.user),
                            ),
                          ),
                          icon: const Icon(Icons.location_on, size: 16),
                          label: const Text('Track Order'),
                        ),
                      ),
                      if (canCancel) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: isProcessingThisOrder ? null : () => _cancelOrder(order['id']),
                            icon: isProcessingThisOrder
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                                : const Icon(Icons.cancel_outlined, size: 16),
                            label: Text(
                              isProcessingThisOrder ? 'Cancelling...' : 'Cancel Order',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color))]),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.hourglass_empty;
      case 'confirmed': return Icons.check_circle_outline;
      case 'assigned': return Icons.person_outline;
      case 'picked': return Icons.delivery_dining;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.shopping_bag;
    }
  }
}