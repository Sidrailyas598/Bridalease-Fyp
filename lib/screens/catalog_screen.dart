// lib/screens/catalog_screen.dart - WITHOUT APPBAR

import 'package:bridalease_fyp/screens/dress_detail_screen.dart';
import 'package:bridalease_fyp/screens/budget_assistance_screen.dart';
import 'package:bridalease_fyp/screens/recommender_screen.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:bridalease_fyp/screens/order_history_screen.dart';
import 'package:bridalease_fyp/screens/notification_screen.dart';
import 'package:bridalease_fyp/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CatalogScreen extends StatefulWidget {
  final String? role;

  const CatalogScreen({
    super.key, 
    this.role,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  final String baseUrl =
      'https://booeleldfprujllrxoik.supabase.co/storage/v1/object/public/dresses/';

  int _selectedIndex = 0;
  List<Map<String, dynamic>> _allDresses = [];
  List<Map<String, dynamic>> _filteredDresses = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  
  RangeValues _priceRange = const RangeValues(0, 500000);
  double _maxPrice = 500000;
  bool _showFilters = false;
  
  String _selectedColor = 'All';
  final List<String> _colors = ['All', 'Red', 'Gold', 'Blue', 'Green', 'Pink', 'White', 'Black'];

  // Notification variables
  int _unreadCount = 0;
  late final NotificationService _notificationService;

  User? get _currentUser => supabase.auth.currentUser;

  String _formatImageUrl(dynamic imagePath) {
    if (imagePath == null) return '';
    String path = imagePath.toString();
    if (path.startsWith('http')) {
      return path;
    }
    path = path.replaceAll(RegExp(r'^/+'), '');
    return '$baseUrl$path';
  }

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _loadDresses();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final user = _currentUser;
    if (user != null) {
      final count = await _notificationService.getUnreadCount(user.id);
      setState(() {
        _unreadCount = count;
      });
    }
  }

  Future<void> _loadDresses() async {
    try {
      setState(() => _loading = true);

      final response = await supabase
          .from('dresses')
          .select('''
            *,
            users:vendor_id (
              full_name,
              business_name,
              business_phone,
              business_address,
              business_description
            )
          ''')
          .eq('is_approved', true)
          .eq('status', 'available')
          .order('created_at', ascending: false);

      debugPrint('📦 Loaded ${response.length} dresses');

      setState(() {
        _allDresses = List<Map<String, dynamic>>.from(response);
        
        Set<String> uniqueEventTypes = {};
        for (var dress in _allDresses) {
          if (dress['event_type'] != null && dress['event_type'].toString().isNotEmpty) {
            uniqueEventTypes.add(dress['event_type'].toString());
          }
        }
        
        _categories = ['All', ...uniqueEventTypes.toList()..sort()];
        
        if (_allDresses.isNotEmpty) {
          _maxPrice = _allDresses
              .map((d) => (d['price'] ?? 0).toDouble())
              .reduce((a, b) => a > b ? a : b);
          _priceRange = RangeValues(0, _maxPrice);
        }
        
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading dresses: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDresses = _allDresses.where((dress) {
        if (_selectedCategory != 'All') {
          final dressEventType = dress['event_type']?.toString() ?? '';
          if (dressEventType.isEmpty) return false;
          if (dressEventType.toLowerCase() != _selectedCategory.toLowerCase()) {
            return false;
          }
        }
        
        double price = (dress['price'] ?? 0).toDouble();
        if (price < _priceRange.start || price > _priceRange.end) {
          return false;
        }
        
        if (_selectedColor != 'All') {
          final dressColor = dress['color']?.toString() ?? '';
          if (dressColor.toLowerCase() != _selectedColor.toLowerCase()) {
            return false;
          }
        }
        
        if (_searchController.text.isNotEmpty) {
          final name = (dress['name'] ?? '').toLowerCase();
          final color = (dress['color'] ?? '').toLowerCase();
          final style = (dress['style'] ?? '').toLowerCase();
          final eventType = (dress['event_type'] ?? '').toLowerCase();
          final searchLower = _searchController.text.toLowerCase();
          
          if (!name.contains(searchLower) &&
              !color.contains(searchLower) &&
              !style.contains(searchLower) &&
              !eventType.contains(searchLower)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedColor = 'All';
      _priceRange = RangeValues(0, _maxPrice);
      _searchController.clear();
      _applyFilters();
    });
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search dresses...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF660033), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  if (_currentUser != null)
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, size: 20),
                          color: _showFilters ? Colors.white : const Color(0xFF660033),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationScreen(user: _currentUser!),
                              ),
                            ).then((_) => _loadUnreadCount());
                          },
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: _showFilters ? const Color(0xFF660033) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: _showFilters ? Colors.white : const Color(0xFF660033),
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() => _showFilters = !_showFilters);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (!_showFilters) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 35,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _applyFilters();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF660033) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          if (_showFilters) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF660033),
                        ),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                        child: const Text(
                          'Reset All',
                          style: TextStyle(color: Color(0xFF660033), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  const Text(
                    'Price Range (Rs)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: _maxPrice,
                    divisions: 10,
                    activeColor: const Color(0xFF660033),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                        _applyFilters();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rs ${_priceRange.start.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                      Text('Rs ${_priceRange.end.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  const Text(
                    'Color',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _colors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                            _applyFilters();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF660033) : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            color,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDressCard(Map<String, dynamic> dress) {
    final List images = dress['images'] ?? [];
    final validImages = images.where((img) => img != null).toList();
    final PageController pageController = PageController();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DressDetailScreen(
                dress: dress,
                role: widget.role ?? 'bride',
                allDresses: _allDresses,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (validImages.isNotEmpty)
                      PageView.builder(
                        controller: pageController,
                        itemCount: validImages.length,
                        itemBuilder: (context, imgIndex) {
                          String imgPath = _formatImageUrl(validImages[imgIndex].toString());
                          return Image.network(
                            imgPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                              );
                            },
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 30, color: Colors.grey),
                      ),
                    
                    if (validImages.length > 1)
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SmoothPageIndicator(
                              controller: pageController,
                              count: validImages.length,
                              effect: const ExpandingDotsEffect(
                                activeDotColor: Colors.white,
                                dotHeight: 3,
                                dotWidth: 3,
                                expansionFactor: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF660033),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dress['event_type']?.toString().toUpperCase() ?? 'DRESS',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dress['name'] ?? 'Unnamed Dress',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF660033),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF660033).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Rs ${_formatNumber(dress['price']?.toStringAsFixed(0) ?? '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF660033),
                      ),
                    ),
                  ),
                  if (dress['color'] != null && dress['color'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF660033).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dress['color'],
                          style: const TextStyle(fontSize: 9, color: Color(0xFF660033), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(String number) {
    try {
      final num value = num.parse(number);
      if (value >= 1000) {
        return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      }
      return number;
    } catch (e) {
      return number;
    }
  }

  Widget _buildCatalogGrid() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF660033)));
    }

    if (_filteredDresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Dresses Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF660033),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text('Clear Filters', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemCount: _filteredDresses.length,
            itemBuilder: (context, index) {
              return _buildDressCard(_filteredDresses[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetOptimizer() {
    return BudgetAssistanceScreen(
      dresses: _allDresses,
      onBack: () => setState(() => _selectedIndex = 0),
    );
  }

  Widget _buildPopularDresses() {
    final popularDresses = List.from(_allDresses)
      ..sort((a, b) => (b['view_count'] ?? 0).compareTo(a['view_count'] ?? 0));
    
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemCount: popularDresses.length,
            itemBuilder: (context, index) => _buildDressCard(popularDresses[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommenderScreen() {
    return RecommenderScreen(
      role: widget.role ?? 'bride',
      onBack: () => setState(() => _selectedIndex = 0),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildCatalogGrid();
      case 1:
        return _buildPopularDresses();
      case 2:
        return _buildRecommenderScreen();
      case 3:
        return _buildBudgetOptimizer();
      case 4:
        if (_currentUser != null) {
          return OrderHistoryScreen(user: _currentUser!);
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Please login to view orders'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF660033),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
      default:
        return _buildCatalogGrid();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      // ✅ NO APPBAR - Completely removed
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_bg2.png',
              fit: BoxFit.cover,
              color: Colors.white.withOpacity(0.8),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          SafeArea(child: _getBody()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF660033),
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Catalog'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up_outlined), label: 'Popular'),
          BottomNavigationBarItem(icon: Icon(Icons.star_border_outlined),activeIcon: Icon(Icons.star),label: 'Picks'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money_outlined), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        ],
      ),
    );
  }
}