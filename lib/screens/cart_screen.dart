import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'checkout_screen.dart';

final supabase = Supabase.instance.client;

class CartScreen extends StatefulWidget {
  final User user;
  const CartScreen({super.key, required this.user});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _cartItems = [];
  bool _loading = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    
    _loadCart();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    try {
      setState(() => _loading = true);
      
      debugPrint('🛒 Loading cart for user: ${widget.user.id}');
      
      final response = await supabase
          .from('cart')
          .select('''
            *,
            dresses!inner (
              id,
              name,
              price,
              rental_price,
              images,
              vendor_id
            )
          ''')
          .eq('user_id', widget.user.id);
      
      debugPrint('🛒 Cart response: ${response.length} items');
      
      final transformedItems = response.map((item) {
        final dress = item['dresses'];
        final imageUrl = dress['images'] != null && dress['images'].isNotEmpty
            ? dress['images'][0].toString()
            : null;
        
        return {
          'id': item['id'],
          'quantity': item['quantity'] ?? 1,
          'is_rental': item['is_rental'] ?? false,
          'created_at': item['created_at'],
          'dresses': {
            'id': dress['id'],
            'dress_name': dress['name'],
            'price': dress['price'],
            'rental_price': dress['rental_price'],
            'image_url': imageUrl,
            'vendor_id': dress['vendor_id'],
          }
        };
      }).toList();
      
      setState(() {
        _cartItems = transformedItems;
        _loading = false;
      });
      
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFromCart(String cartId) async {
    try {
      await supabase.from('cart').delete().eq('id', cartId);
      _loadCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item removed from cart'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  double get _subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      final dress = item['dresses'];
      final price = (dress['price'] as num?)?.toDouble() ?? 0;
      final quantity = (item['quantity'] as int?) ?? 1;
      return sum + (price * quantity);
    });
  }

  int get _totalItems {
    return _cartItems.fold(0, (sum, item) {
      return sum + ((item['quantity'] as int?) ?? 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF660033),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_totalItems items',
                    style: const TextStyle(color: Color(0xFF660033), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF660033)))
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadCart,
                            color: const Color(0xFF660033),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _cartItems.length,
                              itemBuilder: (context, index) {
                                final item = _cartItems[index];
                                final dress = item['dresses'];
                                return _buildCartItem(item, dress);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Professional Floating Checkout Button - Only Icon
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        builder: (context, double scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(28),
                              shadowColor: const Color(0xFF660033).withOpacity(0.4),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutScreen(
                                        items: _cartItems,
                                        user: widget.user,
                                        isMultiItem: true,
                                      ),
                                    ),
                                  ).then((_) => _loadCart());
                                },
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF660033), Color(0xFF99004C)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF660033).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      const Center(
                                        child: Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                      // Small badge for item count
                                      if (_totalItems > 0)
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.15),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$_totalItems',
                                                style: const TextStyle(
                                                  color: Color(0xFF660033),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, Map<String, dynamic> dress) {
    final quantity = (item['quantity'] as int?) ?? 1;
    final price = (dress['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = dress['image_url'];
    final dressName = dress['dress_name'] ?? 'Dress';
    final itemTotal = price * quantity;

    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) => _removeFromCart(item['id'].toString()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dressName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF660033).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Rs ${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF660033),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.production_quantity_limits, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Qty: $quantity',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Item Total:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Rs ${itemTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF660033),
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
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF660033).withOpacity(0.1), blurRadius: 30)],
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: const Color(0xFF660033).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Cart is Empty',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF660033)),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
}