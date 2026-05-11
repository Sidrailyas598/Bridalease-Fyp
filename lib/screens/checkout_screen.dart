import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_confirmation_screen.dart';

final supabase = Supabase.instance.client;

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final User user;
  final bool isMultiItem;

  const CheckoutScreen({super.key, required this.items, required this.user, this.isMultiItem = false});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _processing = false;
  String _selectedPaymentMethod = 'cod';
  String _orderType = 'purchase';
  File? _paymentProof;
  int _rentalDays = 3;
  
  final double _deliveryCharges = 500;
  final double _securityDeposit = 10000;
  final String _easypaisaNumber = '03125178619';
  final String _jazzcashNumber = '03015004990';

  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _contactController = TextEditingController();

  // ✅ Updated excluded dress names with multiple variations
  final Set<String> _excludedDressNames = {
    'Bottle green elegance',
    'bottle green elegance',
    'BOTTLE GREEN ELEGANCE',
    'Bottle Green Elegance',
    'bottle green',
    'Bottle Green',
    'bottleGreen',
    'BottleGreen',
  };

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.user.userMetadata?['full_name'] ?? '';
    _contactController.text = widget.user.phone ?? '';
    _validateAndCleanItems();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _validateAndCleanItems() {
    debugPrint('📦 Validating ${widget.items.length} items...');
    for (var item in widget.items) {
      final dress = item['dresses'];
      final dressName = dress['dress_name'] ?? '';
      final price = (dress['price'] as num?)?.toDouble() ?? 0;
      
      debugPrint('🔍 Dress in cart: "$dressName" - Price: $price');
      
      final isExcluded = _excludedDressNames.any(
        (excluded) => dressName.toLowerCase().contains(excluded.toLowerCase())
      );
      
      if (isExcluded) {
        debugPrint('⚠️ EXCLUDED: $dressName will be removed');
      }
    }
  }

  List<Map<String, dynamic>> _getCleanedItems() {
    final List<Map<String, dynamic>> cleanedItems = [];
    
    debugPrint('📦 STARTING _getCleanedItems');
    debugPrint('📦 widget.items.length: ${widget.items.length}');
    
    for (var item in widget.items) {
      final dress = item['dresses'];
      final dressName = dress['dress_name'] ?? '';
      final price = (dress['price'] as num?)?.toDouble() ?? 0;
      
      debugPrint('🔍 Processing item: "$dressName" - Price: $price');
      
      // ✅ Case-insensitive check for excluded dresses
      final isExcluded = _excludedDressNames.any(
        (excluded) => dressName.toLowerCase().contains(excluded.toLowerCase())
      );
      
      if (isExcluded) {
        debugPrint('🚫 BLOCKED: $dressName cannot be ordered');
        continue;
      }
      
      if (price <= 0) {
        debugPrint('⚠️ Zero price dress: $dressName');
        continue;
      }
      
      cleanedItems.add(item);
      debugPrint('✅ KEPT: $dressName');
    }
    
    debugPrint('📦 FINAL cleanedItems.length: ${cleanedItems.length} (removed ${widget.items.length - cleanedItems.length})');
    return cleanedItems;
  }

  double get _subtotal {
    final cleanedItems = _getCleanedItems();
    return cleanedItems.fold(0.0, (sum, item) {
      final dress = item['dresses'];
      double price;
      if (_orderType == 'rent') {
        price = (dress['rental_price'] ?? dress['price'] as num?)?.toDouble() ?? 0;
      } else {
        price = (dress['price'] as num?)?.toDouble() ?? 0;
      }
      final quantity = (item['quantity'] as int?) ?? 1;
      return sum + (price * quantity);
    });
  }

  double get _totalPayable {
    if (_orderType == 'rent') {
      return _subtotal + _securityDeposit + _deliveryCharges;
    } else {
      return _subtotal + _deliveryCharges;
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _paymentProof = File(image.path));
    }
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final cleanedItems = _getCleanedItems();
    if (cleanedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid items in cart'), backgroundColor: Colors.orange),
      );
      return;
    }

    if ((_selectedPaymentMethod == 'easypaisa' || _selectedPaymentMethod == 'jazzcash') && _paymentProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload payment receipt'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final user = widget.user;
      String? proofUrl;
      String paymentStatus = 'pending';

      if (_selectedPaymentMethod == 'easypaisa' || _selectedPaymentMethod == 'jazzcash') {
        final fileName = 'proofs/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('payment-proofs').upload(fileName, _paymentProof!);
        proofUrl = supabase.storage.from('payment-proofs').getPublicUrl(fileName);
        paymentStatus = 'awaiting_verification';
      }

      // ✅ FIX: REMOVED uniqueItemsMap - Directly use cleanedItems
      // No need for deduplication as cart items are already unique
      final orderItems = cleanedItems; // Use cleanedItems directly
      
      debugPrint('📦 ORIGINAL CART ITEMS: ${cleanedItems.length}');
      for (var item in cleanedItems) {
        final dress = item['dresses'];
        debugPrint('   - ${dress['dress_name']} (ID: ${dress['id']}) x ${item['quantity'] ?? 1}');
      }

      final Set<String> vendorIds = {};
      for (var item in orderItems) {
        final dress = item['dresses'];
        if (dress['vendor_id'] != null) {
          vendorIds.add(dress['vendor_id'].toString());
        }
      }

      final double calculatedSubtotal = orderItems.fold(0.0, (sum, item) {
        final dress = item['dresses'];
        double price;
        if (_orderType == 'rent') {
          price = (dress['rental_price'] ?? dress['price'] as num?)?.toDouble() ?? 0;
        } else {
          price = (dress['price'] as num?)?.toDouble() ?? 0;
        }
        final quantity = (item['quantity'] as int?) ?? 1;
        return sum + (price * quantity);
      });
      
      final double calculatedTotal = _orderType == 'rent' 
          ? calculatedSubtotal + _securityDeposit + _deliveryCharges
          : calculatedSubtotal + _deliveryCharges;

      // ========== ORDER DATA ==========
      final orderData = {
        'user_id': user.id,
        'customer_name': _fullNameController.text,
        'delivery_address': "${_addressController.text}, ${_cityController.text}",
        'contact_number': _contactController.text,
        'payment_method': _selectedPaymentMethod,
        'payment_status': paymentStatus,
        'order_type': _orderType,
        'subtotal': calculatedSubtotal,
        'delivery_charges': _deliveryCharges,
        'total_amount': calculatedTotal,
        'status': 'pending',
        'vendor_id': vendorIds.isNotEmpty ? vendorIds.first : null,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (proofUrl != null) orderData['payment_proof_url'] = proofUrl;
      
      // ========== RENTAL SPECIFIC DATA (NO DATES YET) ==========
      if (_orderType == 'rent') {
        orderData['security_deposit'] = _securityDeposit;
        orderData['rental_days'] = _rentalDays;
        orderData['return_status'] = 'pending';
        orderData['reminder_sent'] = false;
      }

      final orderResponse = await supabase.from('orders').insert(orderData).select();
      final orderId = orderResponse[0]['id'];

      // ========== ORDER ITEMS ==========
      debugPrint('📦 Inserting ${orderItems.length} order items...');
      
      for (var i = 0; i < orderItems.length; i++) {
        final item = orderItems[i];
        final dress = item['dresses'];
        final quantity = (item['quantity'] as int?) ?? 1;
        double price;
        if (_orderType == 'rent') {
          price = (dress['rental_price'] ?? dress['price'] as num?)?.toDouble() ?? 0;
        } else {
          price = (dress['price'] as num?)?.toDouble() ?? 0;
        }
        final itemTotal = price * quantity;
        
        String? vendorId = dress['vendor_id']?.toString();
        if (vendorId == null || vendorId.isEmpty) {
          vendorId = user.id;
        }

        final orderItemData = {
          'order_id': orderId,
          'dress_id': dress['id'],
          'dress_name': dress['dress_name'],
          'price': price,
          'quantity': quantity,
          'item_total': itemTotal,
          'vendor_id': vendorId,
          'is_rental': _orderType == 'rent',
          'image_url': dress['image_url'],
          'created_at': DateTime.now().toIso8601String(),
        };

        if (_orderType == 'rent') {
          orderItemData['rental_days'] = _rentalDays;
        }

        debugPrint('   ✅ Inserting: ${dress['dress_name']} x $quantity = Rs $itemTotal');
        await supabase.from('order_items').insert(orderItemData);
      }

      // ========== VERIFICATION: Check what was actually inserted ==========
      final verifyItems = await supabase
          .from('order_items')
          .select('dress_name, quantity')
          .eq('order_id', orderId);
      
      debugPrint('📦 VERIFICATION: ${verifyItems.length} items in order:');
      for (var item in verifyItems) {
        debugPrint('   - ${item['dress_name']} x ${item['quantity']}');
      }

      // Clear cart only after successful order creation
      await supabase.from('cart').delete().eq('user_id', user.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: orderId,
              user: user,
              totalAmount: calculatedTotal,
              paymentMethod: _selectedPaymentMethod,
              paymentStatus: paymentStatus,
              orderType: _orderType,
              itemsCount: orderItems.length,
              items: orderItems,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Checkout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanedItems = _getCleanedItems();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: Text(
          'Checkout ${widget.isMultiItem ? '(${cleanedItems.length} items)' : ''}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF660033),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF660033).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cleanedItems.isEmpty
          ? _buildEmptyState()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildOrderTypeCard(),
                    const SizedBox(height: 16),
                    _buildOrderSummaryCard(cleanedItems),
                    const SizedBox(height: 16),
                    _buildDeliveryDetailsCard(),
                    const SizedBox(height: 16),
                    _buildPaymentMethodCard(),
                    const SizedBox(height: 16),
                    _buildPriceDetailsCard(),
                    const SizedBox(height: 24),
                    _buildPlaceOrderButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF660033).withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(Icons.shopping_bag_outlined, size: 60, color: const Color(0xFF660033).withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Valid Items',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF660033)),
          ),
          const SizedBox(height: 8),
          Text('Please add items to continue', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF660033)),
                SizedBox(width: 8),
                Text('Order Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF660033))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactTypeOption(
                    title: 'Purchase',
                    icon: Icons.shopping_bag_outlined,
                    isSelected: _orderType == 'purchase',
                    onTap: () => setState(() => _orderType = 'purchase'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactTypeOption(
                    title: 'Rent',
                    icon: Icons.calendar_today_outlined,
                    isSelected: _orderType == 'rent',
                    onTap: () => setState(() => _orderType = 'rent'),
                  ),
                ),
              ],
            ),
            if (_orderType == 'rent') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Security deposit: Rs $_securityDeposit (refundable)',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _rentalDays,
                        underline: const SizedBox(),
                        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.orange.shade700),
                        items: [3, 5, 7, 10, 14].map((days) {
                          return DropdownMenuItem(value: days, child: Text('$days days', style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (value) => setState(() => _rentalDays = value!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rental period will start when the dress is delivered to you',
                        style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTypeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF660033), Color(0xFF883366)])
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, size: 18, color: Color(0xFF660033)),
                SizedBox(width: 8),
                Text('Order Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF660033))),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final dress = item['dresses'];
              final quantity = (item['quantity'] as int?) ?? 1;
              double price = (_orderType == 'rent' 
                  ? (dress['rental_price'] ?? dress['price'] as num?)?.toDouble() 
                  : (dress['price'] as num?)?.toDouble()) ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: dress['image_url'] != null 
                          ? Image.network(dress['image_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey.shade400))
                          : Icon(Icons.image, color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dress['dress_name'] ?? 'Dress', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1),
                          Text('Rs ${price.toStringAsFixed(0)} x $quantity', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF660033).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Rs ${(price * quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping, size: 18, color: Color(0xFF660033)),
                SizedBox(width: 8),
                Text('Delivery Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF660033))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline, size: 18, color: Colors.grey.shade500),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      hintText: 'Contact',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18, color: Colors.grey.shade500),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Delivery Address',
                prefixIcon: Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade500),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'City',
                prefixIcon: Icon(Icons.location_city_outlined, size: 18, color: Colors.grey.shade500),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, size: 18, color: Color(0xFF660033)),
                SizedBox(width: 8),
                Text('Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF660033))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOptionCompact(
                    value: 'cod',
                    title: 'Cash on Delivery',
                    icon: Icons.money_off_csred,
                    isSelected: _selectedPaymentMethod == 'cod',
                    onTap: () => setState(() => _selectedPaymentMethod = 'cod'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOptionCompact(
                    value: 'easypaisa',
                    title: 'EasyPaisa',
                    subtitle: _easypaisaNumber,
                    icon: Icons.phone_android,
                    isSelected: _selectedPaymentMethod == 'easypaisa',
                    onTap: () => setState(() => _selectedPaymentMethod = 'easypaisa'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPaymentOptionCompact(
                    value: 'jazzcash',
                    title: 'JazzCash',
                    subtitle: _jazzcashNumber,
                    icon: Icons.phone_iphone,
                    isSelected: _selectedPaymentMethod == 'jazzcash',
                    onTap: () => setState(() => _selectedPaymentMethod = 'jazzcash'),
                  ),
                ),
              ],
            ),
            if (_selectedPaymentMethod == 'easypaisa' || _selectedPaymentMethod == 'jazzcash')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _paymentProof != null ? Colors.green.shade300 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: _paymentProof != null ? Colors.green.shade50 : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(_paymentProof == null ? Icons.upload_file : Icons.check_circle, 
                            color: _paymentProof == null ? Colors.grey : Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Text(_paymentProof == null ? 'Upload Payment Receipt' : 'Receipt Uploaded',
                            style: TextStyle(color: _paymentProof == null ? Colors.grey : Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionCompact({
    required String value,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF660033).withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF660033) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? const Color(0xFF660033) : Colors.grey.shade600),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF660033) : Colors.grey.shade800)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', _subtotal),
            const SizedBox(height: 8),
            _buildPriceRow('Delivery', _deliveryCharges),
            if (_orderType == 'rent') ...[
              const SizedBox(height: 8),
              _buildPriceRow('Security Deposit', _securityDeposit),
            ],
            const Divider(height: 20),
            _buildPriceRow('Total', _totalPayable, true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String title, double value, [bool bold = false]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: bold ? const Color(0xFF660033) : Colors.grey.shade700)),
        Text('Rs ${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: bold ? const Color(0xFF660033) : Colors.grey.shade800)),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processing ? null : _processCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF660033),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _processing
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(_selectedPaymentMethod == 'cod' ? 'Place Order' : 'Submit for Approval',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}