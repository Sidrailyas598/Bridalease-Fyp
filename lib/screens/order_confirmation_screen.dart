import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'catalog_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final User user;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderType;
  final int itemsCount;
  final List<Map<String, dynamic>>? items;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.user,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderType,
    required this.itemsCount,
    this.items,
  });

  String _getPaymentMethodText() {
    switch (paymentMethod) {
      case 'cod': return 'Cash on Delivery';
      case 'easypaisa': return 'EasyPaisa';
      case 'jazzcash': return 'JazzCash';
      default: return paymentMethod;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_circle, size: 60, color: Colors.green),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Placed Successfully!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF660033),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #${orderId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                
                const SizedBox(height: 24),
                
                // Order Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Order ID', '#${orderId.substring(0, 8).toUpperCase()}'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Order Type', orderType.toUpperCase()),
                      const SizedBox(height: 8),
                      _buildDetailRow('Items', '$itemsCount item(s)'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Payment Method', _getPaymentMethodText()),
                      const SizedBox(height: 8),
                      _buildDetailRow('Payment Status', paymentStatus),
                      const Divider(height: 24),
                      _buildDetailRow('Total Amount', 'Rs ${totalAmount.toStringAsFixed(0)}', isTotal: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Items List Card
                if (items != null && items!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF660033)),
                            SizedBox(width: 8),
                            Text(
                              'Order Items',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF660033),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...items!.map((item) {
                          final dress = item['dresses'];
                          final quantity = (item['quantity'] as int?) ?? 1;
                          final price = (dress['price'] as num?)?.toDouble() ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[100],
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: dress['image_url'] != null
                                        ? Image.network(
                                            dress['image_url'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 30),
                                          )
                                        : const Icon(Icons.image, size: 30, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dress['dress_name'] ?? 'Dress',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rs ${price.toStringAsFixed(0)} x $quantity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF660033).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Rs ${(price * quantity).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF660033),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Helpful Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can track your order status in "Orders" section. Go to bottom navigation bar → Orders',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // ✅ Fixed OK Button - No more route error
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Go back to catalog screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CatalogScreen(
                            role: user.userMetadata?['role'] ?? 'bride',
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF660033),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? const Color(0xFF660033) : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? const Color(0xFF660033) : Colors.black87,
          ),
        ),
      ],
    );
  }
}