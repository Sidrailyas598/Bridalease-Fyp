import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dress_detail_screen.dart';

final supabase = Supabase.instance.client;

class RecommenderScreen extends StatefulWidget {
  final String role;
  final VoidCallback onBack;

  const RecommenderScreen({
    super.key,
    required this.role,
    required this.onBack,
  });

  @override
  State<RecommenderScreen> createState() => _RecommenderScreenState();
}

class _RecommenderScreenState extends State<RecommenderScreen> {
  List<Map<String, dynamic>> _personalizedRecs = [];
  List<Map<String, dynamic>> _trendingDresses = [];
  List<Map<String, dynamic>> _recentlyViewed = [];
  bool _isLoading = true;
  
  final String baseUrl = 'https://booeleldfprujllrxoik.supabase.co/storage/v1/object/public/dresses/';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = supabase.auth.currentUser?.id;
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Future.wait([
        _fetchPersonalizedRecs(),
        _fetchTrendingDresses(),
        _fetchRecentlyViewed(),
      ]);
      
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ========== 1. PERSONALIZED: Based on Event Type + Color from Liked/Saved Dresses ==========
  Future<void> _fetchPersonalizedRecs() async {
    final userId = _userId;
    if (userId == null) return;
    
    try {
      // Get user's liked and saved dresses
      final userLikes = await supabase
          .from('user_activity')
          .select('dress_id, activity_type')
          .eq('user_id', userId)
          .inFilter('activity_type', ['like', 'save']);
      
      final likedIds = userLikes.map((a) => a['dress_id'] as String).toList();
      final uniqueLikedIds = likedIds.toSet().toList();
      
      if (uniqueLikedIds.isEmpty) {
        return;
      }
      
      // Get details of liked dresses (only Event Type and Color)
      final likedDressesDetails = await supabase
          .from('dresses')
          .select('id, name, event_type, color, price')
          .inFilter('id', uniqueLikedIds);
      
      // Collect ONLY Event Types and Colors
      Set<String> eventTypes = {};
      Set<String> colors = {};
      List<double> prices = [];
      
      for (var dress in likedDressesDetails) {
        if (dress['event_type'] != null && dress['event_type'].toString().isNotEmpty) {
          eventTypes.add(dress['event_type'].toString());
        }
        if (dress['color'] != null && dress['color'].toString().isNotEmpty) {
          colors.add(dress['color'].toString());
        }
        if (dress['price'] != null) {
          prices.add((dress['price'] as num).toDouble());
        }
      }
      
      // Calculate price range (50% range)
      double avgPrice = prices.isNotEmpty ? prices.reduce((a, b) => a + b) / prices.length : 80000;
      double minPrice = avgPrice * 0.5;
      double maxPrice = avgPrice * 1.5;
      
      // Build filter: Event Type OR Color match
      List<String> filters = [];
      
      if (eventTypes.isNotEmpty) {
        final eventStr = eventTypes.map((e) => '"$e"').join(',');
        filters.add('event_type.in.($eventStr)');
      }
      
      if (colors.isNotEmpty) {
        final colorStr = colors.map((c) => '"$c"').join(',');
        filters.add('color.in.($colorStr)');
      }
      
      if (filters.isEmpty) return;
      
      final orFilter = filters.join(',');
      
      // Query for similar dresses
      var query = supabase
          .from('dresses')
          .select('*, users!vendor_id(business_name)')
          .eq('is_approved', true)
          .or(orFilter)
          .gte('price', minPrice.toInt())
          .lte('price', maxPrice.toInt());
      
      // Exclude already liked dresses
      if (uniqueLikedIds.isNotEmpty) {
        query = query.not('id', 'in', uniqueLikedIds);
      }
      
      final result = await query.limit(20);
      
      if (mounted) {
        setState(() {
          _personalizedRecs = List<Map<String, dynamic>>.from(result);
        });
      }
      
    } catch (e) {
      debugPrint('Personalized error: $e');
    }
  }

  // ========== 2. TRENDING DRESSES ==========
  Future<void> _fetchTrendingDresses() async {
    try {
      final result = await supabase
          .from('dresses')
          .select('*, users!vendor_id(business_name)')
          .eq('is_approved', true)
          .order('view_count', ascending: false)
          .limit(12);
      
      if (mounted) {
        setState(() {
          _trendingDresses = List<Map<String, dynamic>>.from(result);
        });
      }
      
    } catch (e) {
      debugPrint('Trending error: $e');
    }
  }

  // ========== 3. RECENTLY VIEWED ==========
  Future<void> _fetchRecentlyViewed() async {
    if (_userId == null) return;
    
    try {
      final recent = await supabase
          .from('user_activity')
          .select('dress_id')
          .eq('user_id', _userId!)
          .eq('activity_type', 'view')
          .order('created_at', ascending: false)
          .limit(10);
      
      final dressIds = recent.map((r) => r['dress_id'] as String).toList();
      
      if (dressIds.isNotEmpty && mounted) {
        final dresses = await supabase
            .from('dresses')
            .select('*, users!vendor_id(business_name)')
            .inFilter('id', dressIds);
        
        setState(() {
          _recentlyViewed = List<Map<String, dynamic>>.from(dresses);
        });
      }
      
    } catch (e) {
      debugPrint('Recent error: $e');
    }
  }

  // ========== UI HELPERS ==========
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'yellow': return Colors.yellow;
      case 'pink': return Colors.pink;
      case 'maroon': return Colors.brown.shade700;
      case 'gold': return Colors.amber;
      case 'purple': return Colors.purple;
      case 'orange': return Colors.orange;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      default: return Colors.grey;
    }
  }

  Widget _buildProductImage(dynamic imageData) {
    String imagePath = '';
    if (imageData is List && imageData.isNotEmpty) {
      imagePath = imageData[0].toString();
    } else if (imageData is String) {
      imagePath = imageData;
    }
    
    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }
    
    String fullUrl = imagePath.startsWith('http') ? imagePath : '$baseUrl$imagePath';
    
    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
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
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _buildDressCard(Map<String, dynamic> dress) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DressDetailScreen(
                  dress: dress,
                  role: widget.role,
                  allDresses: null,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: _buildProductImage(dress['images']),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dress['name'] ?? 'Bridal Wear',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${NumberFormat("#,##0").format(dress['price'] ?? 0)}',
                      style: const TextStyle(
                        color: Color(0xFF660033),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (dress['event_type'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF660033).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dress['event_type'],
                              style: TextStyle(
                                fontSize: 9,
                                color: const Color(0xFF660033),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        if (dress['rating'] != null)
                          Row(
                            children: [
                              Icon(Icons.star, size: 10, color: Colors.amber.shade600),
                              const SizedBox(width: 2),
                              Text(
                                dress['rating'].toStringAsFixed(1),
                                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                              ),
                            ],
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

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF660033),
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length > 10 ? 10 : items.length,
            itemBuilder: (context, index) => _buildDressCard(items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadRecommendations,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyRecommendations = _personalizedRecs.isNotEmpty || 
                                   _recentlyViewed.isNotEmpty || 
                                   _trendingDresses.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome_bg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF660033)),
                    SizedBox(height: 16),
                    Text(
                      'Finding best recommendations for you...',
                      style: TextStyle(color: Color(0xFF660033)),
                    ),
                  ],
                ),
              )
            : !hasAnyRecommendations
                ? _buildEmptyState('No recommendations yet.\nLike or save some dresses first!')
                : RefreshIndicator(
                    onRefresh: _loadRecommendations,
                    color: const Color(0xFF660033),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personalized Recommendations
                          if (_personalizedRecs.isNotEmpty)
                            _buildSection('✨ Just For You', _personalizedRecs),
                          
                          // Recently Viewed
                          if (_recentlyViewed.isNotEmpty)
                            _buildSection('⌛ Recently Viewed', _recentlyViewed),
                          
                          // Trending Now
                          if (_trendingDresses.isNotEmpty)
                            _buildSection('⚡ Trending Now', _trendingDresses),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}