import 'dart:io';
import 'package:bridalease_fyp/screens/auto_fit_tryon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bridalease_fyp/screens/bookmark_screen.dart';
import 'package:bridalease_fyp/screens/cart_screen.dart';
import 'package:bridalease_fyp/screens/ProfileSetupScreen.dart';
import 'package:bridalease_fyp/utils/avatar_helper.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class DressDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dress;
  final String role;
  final List<Map<String, dynamic>>? allDresses;

  const DressDetailScreen({
    super.key,
    required this.dress,
    required this.role,
    this.allDresses,
  });

  @override
  State<DressDetailScreen> createState() => _DressDetailScreenState();
}

class _DressDetailScreenState extends State<DressDetailScreen> with TickerProviderStateMixin {
  final PageController _imageController = PageController();
  bool _loading = false;
  String? _processingButton;
  bool _showZoomView = false;
  int _currentZoomIndex = 0;
  bool _isBookmarked = false;
  bool _showSimilarDresses = false;
  List<Map<String, dynamic>> _similarDresses = [];
  
  // Dress stats
  int _viewCount = 0;
  int _likeCount = 0;
  double _rating = 0.0;
  int _ratingCount = 0;
  bool _hasLiked = false;
  bool _hasViewed = false;
  int? _userRating;
  
  // Instagram-style heart animation
  bool _showHeartOverlay = false;
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartFadeAnimation;
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _cartFloatController;
  late AnimationController _saveFloatController;
  late AnimationController _tryOnController;

  String? _vendorId;
  String? _vendorName;
  final String baseUrl = 'https://booeleldfprujllrxoik.supabase.co/storage/v1/object/public/dresses/';
  
  // Track if tracking already done for this session
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    
    // Instagram heart animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartScaleAnimation = Tween<double>(begin: 0.2, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
    _heartFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOut),
    );
    
    // Float animations
    _cartFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _saveFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);
    
    _tryOnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    
    _loadDressStats();
    _checkIfBookmarked();
    _loadSimilarDresses();
    _loadVendorInfo();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _heartController.dispose();
    _cartFloatController.dispose();
    _saveFloatController.dispose();
    _tryOnController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  // ============================================================
  // ✅ TRACKING FUNCTION FOR RECOMMENDATIONS
  // ============================================================
  Future<void> _trackActivity(String type) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      // Weight based on activity type
      int weight = 1;
      switch (type) {
        case 'view': weight = 5; break;
        case 'like': weight = 30; break;
        case 'unlike': weight = 5; break;
        case 'save': weight = 25; break;
        case 'unsave': weight = 5; break;
        case 'cart': weight = 50; break;
        case 'purchase': weight = 100; break;
        case 'rating': weight = 15; break;
      }
      
      // Check if already exists to avoid duplicates
      final existing = await supabase
          .from('user_activity')
          .select()
          .eq('user_id', user.id)
          .eq('dress_id', widget.dress['id'])
          .eq('activity_type', type)
          .maybeSingle();
      
      if (existing == null) {
        await supabase.from('user_activity').insert({
          'user_id': user.id,
          'dress_id': widget.dress['id'],
          'activity_type': type,
          'activity_weight': weight,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('📊 Tracked: $type for ${widget.dress['name']}');
      }
    } catch (e) {
      debugPrint('Track error: $e');
    }
  }

  // --- Load vendor info ---
  Future<void> _loadVendorInfo() async {
    try {
      final vendorId = widget.dress['vendor_id'];
      if (vendorId != null) {
        final response = await supabase
            .from('users')
            .select('full_name, business_name')
            .eq('id', vendorId)
            .single();
        
        setState(() {
          _vendorId = vendorId;
          _vendorName = response['business_name'] ?? response['full_name'] ?? 'Vendor';
        });
      }
    } catch (e) {
      debugPrint('Error loading vendor info: $e');
    }
  }

  // --- Load dress stats from database ---
  Future<void> _loadDressStats() async {
    try {
      final response = await supabase
          .from('dresses')
          .select('view_count, like_count, rating')
          .eq('id', widget.dress['id'])
          .single();

      setState(() {
        _viewCount = response['view_count'] ?? 0;
        _likeCount = response['like_count'] ?? 0;
        _rating = (response['rating'] ?? 4.5).toDouble();
      });

      try {
        final countResponse = await supabase
            .from('dresses')
            .select('rating_count')
            .eq('id', widget.dress['id'])
            .single();
        _ratingCount = countResponse['rating_count'] ?? 0;
      } catch (e) {
        _ratingCount = 0;
      }

      await _checkIfLiked();
      await _incrementViewCountOnce();
    } catch (e) {
      debugPrint('Error loading dress stats: $e');
    }
  }

  // --- Check if user liked this dress ---
  Future<void> _checkIfLiked() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      final response = await supabase
          .from('dress_likes')
          .select()
          .eq('user_id', user.id)
          .eq('dress_id', widget.dress['id'])
          .maybeSingle();
      
      setState(() => _hasLiked = response != null);
    } catch (e) {
      debugPrint('Error checking like: $e');
    }
  }

  // --- Increment view count only once per session ---
  Future<void> _incrementViewCountOnce() async {
    if (_hasViewed) return;
    
    try {
      await supabase.from('dresses').update({
        'view_count': _viewCount + 1
      }).eq('id', widget.dress['id']);
      
      setState(() {
        _viewCount += 1;
        _hasViewed = true;
      });
      
      // ✅ TRACK VIEW ACTIVITY
      await _trackActivity('view');
      
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  // --- Instagram-style like with double tap ---
  void _onImageDoubleTap() {
    if (!_hasLiked) {
      _toggleLike();
    }
    
    setState(() => _showHeartOverlay = true);
    _heartController.forward().then((_) {
      _heartController.reverse().then((_) {
        setState(() => _showHeartOverlay = false);
      });
    });
  }

  // --- Toggle like ---
  Future<void> _toggleLike() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showLoginSnackbar();
      return;
    }

    _scaleController.forward().then((_) => _scaleController.reverse());
    setState(() => _processingButton = 'like');

    try {
      if (_hasLiked) {
        // Removing like
        await supabase
            .from('dress_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('dress_id', widget.dress['id']);
        
        await supabase
            .from('dresses')
            .update({'like_count': _likeCount - 1})
            .eq('id', widget.dress['id']);
        
        setState(() {
          _likeCount -= 1;
          _hasLiked = false;
        });
        
        // ✅ TRACK UNLIKE ACTIVITY
        await _trackActivity('unlike');
        _showSnackbar('Removed like', Colors.orange);
        
      } else {
        // Adding like
        await supabase
            .from('dress_likes')
            .insert({
              'user_id': user.id,
              'dress_id': widget.dress['id'],
              'created_at': DateTime.now().toIso8601String(),
            });
        
        await supabase
            .from('dresses')
            .update({'like_count': _likeCount + 1})
            .eq('id', widget.dress['id']);
        
        setState(() {
          _likeCount += 1;
          _hasLiked = true;
        });
        
        // ✅ TRACK LIKE ACTIVITY
        await _trackActivity('like');
        _showSnackbar('Liked!', Colors.green);
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _processingButton = null);
    }
  }

  // --- Check if bookmarked ---
  Future<void> _checkIfBookmarked() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      final response = await supabase
          .from('wishlist')
          .select()
          .eq('user_id', user.id)
          .eq('dress_id', widget.dress['id'])
          .maybeSingle();
          
      setState(() => _isBookmarked = response != null);
    } catch (e) {
      debugPrint('Error checking bookmark: $e');
    }
  }

  // --- Toggle bookmark (save) ---
  Future<void> _toggleBookmark() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showLoginSnackbar();
      return;
    }

    setState(() => _processingButton = 'bookmark');

    try {
      if (_isBookmarked) {
        // Removing save
        await supabase
            .from('wishlist')
            .delete()
            .eq('user_id', user.id)
            .eq('dress_id', widget.dress['id']);
        
        // ✅ TRACK UNSAVE ACTIVITY
        await _trackActivity('unsave');
        _showSnackbar('Removed from saved', Colors.orange);
        
      } else {
        // Adding save
        await supabase
            .from('wishlist')
            .insert({
              'user_id': user.id,
              'dress_id': widget.dress['id'],
              'created_at': DateTime.now().toIso8601String(),
            });
        
        // ✅ TRACK SAVE ACTIVITY
        await _trackActivity('save');
        _showSnackbar('Saved!', Colors.green);
      }
      setState(() => _isBookmarked = !_isBookmarked);
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _processingButton = null);
    }
  }

  // --- Load similar dresses ---
  void _loadSimilarDresses() {
    if (widget.allDresses == null || widget.allDresses!.isEmpty) {
      setState(() => _showSimilarDresses = false);
      return;
    }
    
    final currentDress = widget.dress;
    
    _similarDresses = widget.allDresses!.where((dress) {
      if (dress['id'] == currentDress['id']) return false;
      
      int score = 0;
      if (dress['event_type'] == currentDress['event_type']) score += 3;
      if (dress['style'] == currentDress['style']) score += 1;
      
      return score >= 1;
    }).toList();

    if (_similarDresses.length > 10) {
      _similarDresses = _similarDresses.sublist(0, 10);
    }

    setState(() => _showSimilarDresses = _similarDresses.isNotEmpty);
  }

  // ============================================================
  // ✅ ADD TO CART FUNCTION WITH TRACKING
  // ============================================================
  Future<void> addToCart() async {
    setState(() => _processingButton = 'cart');
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showLoginSnackbar();
        return;
      }

      debugPrint('🛒 Adding to cart - User: ${user.id}, Dress: ${widget.dress['id']}');

      // Check if item already exists in cart
      final existingItem = await supabase
          .from('cart')
          .select()
          .eq('user_id', user.id)
          .eq('dress_id', widget.dress['id'])
          .maybeSingle();

      if (existingItem == null) {
        // Insert new item with quantity
        final response = await supabase.from('cart').insert({
          'user_id': user.id,
          'dress_id': widget.dress['id'],
          'quantity': 1,
          'is_rental': false,
          'created_at': DateTime.now().toIso8601String(),
        }).select();
        
        debugPrint('✅ Item added to cart: ${response}');
        
        // ✅ TRACK CART ACTIVITY
        await _trackActivity('cart');
        
        _showSnackbar('✅ Added to cart!', Colors.green);
        _showAddedToCartAnimation();
        
      } else {
        // Update existing item quantity
        final newQuantity = (existingItem['quantity'] ?? 0) + 1;
        await supabase
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('id', existingItem['id']);
        
        debugPrint('✅ Cart quantity updated to: $newQuantity');
        
        // ✅ TRACK CART ACTIVITY (still counts as cart action)
        await _trackActivity('cart');
        
        _showSnackbar('✅ Quantity updated!', Colors.green);
      }
    } catch (e) {
      debugPrint('❌ Error adding to cart: $e');
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _processingButton = null);
    }
  }

  // --- Show added to cart animation ---
  void _showAddedToCartAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 15),
              const Text('Added to Cart!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
              const SizedBox(height: 8),
              Text(widget.dress['name'] ?? 'Dress', style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () { 
                        Navigator.pop(context); 
                        _navigateToCartScreen(); 
                      }, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF660033),
                      ), 
                      child: const Text('View Cart'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Rating section ---
  Widget _buildRatingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_rating.toStringAsFixed(1)} ($_ratingCount)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (_userRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '$_userRating',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              final isSelected = _userRating != null && starNumber <= _userRating!;
              
              return GestureDetector(
                onTap: () => _rateDress(starNumber),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: isSelected ? Colors.amber : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          
          if (_userRating == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Tap to rate',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  // --- Rate dress function with tracking ---
  Future<void> _rateDress(int newRating) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showLoginSnackbar();
      return;
    }

    setState(() => _processingButton = 'rate');

    try {
      final newRatingCount = _ratingCount + (_userRating == null ? 1 : 0);
      final totalRating = (_rating * _ratingCount) + newRating - (_userRating ?? 0);
      final newAverageRating = totalRating / newRatingCount;

      final updateData = {
        'rating': newAverageRating,
      };
      
      try {
        updateData['rating_count'] = newRatingCount as double;
      } catch (e) {}

      await supabase.from('dresses').update(updateData).eq('id', widget.dress['id']);

      setState(() {
        _rating = newAverageRating;
        _ratingCount = newRatingCount;
        _userRating = newRating;
      });

      // ✅ TRACK RATING ACTIVITY
      await _trackActivity('rating');

      _showSnackbar('Thanks for rating! ⭐', Colors.amber);
    } catch (e) {
      debugPrint('Error saving rating: $e');
      _showSnackbar('Error saving rating', Colors.red);
    } finally {
      setState(() => _processingButton = null);
    }
  }

  // --- Helper functions ---
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLoginSnackbar() {
    _showSnackbar('Please login first', Colors.red);
  }

  void _navigateToBookmarkScreen() {
    final user = supabase.auth.currentUser;
    if (user == null) { _showLoginSnackbar(); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookmarkScreen(user: user)));
  }

  void _navigateToCartScreen() {
    final user = supabase.auth.currentUser;
    if (user == null) { _showLoginSnackbar(); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(user: user)));
  }

  Future<void> _navigateToAutoFitTryOn() async {
    final user = supabase.auth.currentUser;
    if (user == null) { _showLoginSnackbar(); return; }

    try {
      setState(() => _processingButton = 'tryon');
      final response = await supabase
          .from('users')
          .select('body_measurements, skin_tone, full_name')
          .eq('id', user.id)
          .single();
      setState(() => _processingButton = null);

      if (response['body_measurements'] == null) {
        _showMeasurementPrompt();
        return;
      }

      String avatarPath = AvatarHelper.getAvatarPath(
        measurements: response['body_measurements'],
        skinTone: response['skin_tone'] ?? 'wheatish',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AutoFitTryOn(
            dressData: widget.dress,
            userMeasurements: {
              'body_measurements': response['body_measurements'],
              'skin_tone': response['skin_tone'] ?? 'wheatish',
              'full_name': response['full_name'] ?? 'User',
            },
            avatarPath: avatarPath, 
            userId: '${user.id}',
          ),
        ),
      );
    } catch (e) {
      setState(() => _processingButton = null);
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showMeasurementPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Measurements Required'),
        content: const Text('Please complete your profile with body measurements first to use Virtual Try-On.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSetupScreen(isFromLogin: false, existingUserData: null)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF660033)),
            child: const Text('Go to Profile'),
          ),
        ],
      ),
    );
  }

  // --- SHARE FUNCTIONS ---
  Future<void> _shareDress() async {
    setState(() => _processingButton = 'share');
    
    try {
      final dress = widget.dress;
      final images = List.from(dress['images'] ?? []);
      final currentImageIndex = _imageController.hasClients ? _imageController.page?.round() ?? 0 : _currentZoomIndex;
      final currentImageUrl = images.isNotEmpty ? _formatImageUrl(images[currentImageIndex]) : null;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share Dress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF660033)),
                title: const Text('Share with Image'),
                onTap: () async { Navigator.pop(context); await _shareWithImage(dress, currentImageUrl); },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Color(0xFF660033)),
                title: const Text('Share Text Only'),
                onTap: () async { Navigator.pop(context); await _shareTextOnly(dress); },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error in share menu: $e');
    } finally {
      setState(() => _processingButton = null);
    }
  }

  Future<void> _shareWithImage(Map<String, dynamic> dress, String? imageUrl) async {
    try {
      setState(() => _processingButton = 'share');
      final text = '🌟 ${dress['name'] ?? 'Dress'} 🌟\n💰 Price: Rs. ${dress['price'] ?? 0}\n⭐ Rating: $_rating/5.0\n❤️ Likes: $_likeCount\n👁️ Views: $_viewCount';

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/dress_share_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await tempFile.writeAsBytes(response.bodyBytes);
            await Share.shareXFiles([XFile(tempFile.path)], text: text);
            await tempFile.delete();
          } else {
            await Share.share(text);
          }
        } catch (e) {
          await Share.share(text);
        }
      } else {
        await Share.share(text);
      }
    } catch (e) {
      await _shareTextOnly(dress);
    } finally {
      setState(() => _processingButton = null);
    }
  }

  Future<void> _shareTextOnly(Map<String, dynamic> dress) async {
    final text = ' 🌟 ${dress['name'] ?? 'Dress'} 🌟\n💰 Price: Rs. ${dress['price'] ?? 0}\n⭐ Rating: $_rating/5.0\n❤️ Likes: $_likeCount\n👁️ Views: $_viewCount';
    await Share.share(text);
  }

  String _formatImageUrl(dynamic imagePath) {
    String path = imagePath.toString();
    if (path.startsWith('http')) return path;
    return '$baseUrl${path.replaceAll(RegExp(r'^/+'), '')}';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF660033).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: const Color(0xFF660033)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== VERTICAL SIMILAR DRESSES SECTION ==========
  Widget _buildSimilarDressesSection() {
    if (!_showSimilarDresses || _similarDresses.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Icon(Icons.copy, size: 18, color: Color(0xFF660033)),
              SizedBox(width: 8),
              Text(
                'You May Also Like',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _similarDresses.length,
          itemBuilder: (context, index) {
            final sDress = _similarDresses[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DressDetailScreen(
                          dress: sDress,
                          role: widget.role,
                          allDresses: widget.allDresses,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _formatImageUrl(sDress['images']?[0] ?? ''),
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 90,
                              width: 90,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 35),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sDress['name'] ?? 'Dress',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rs. ${NumberFormat("#,##0").format(sDress['price'] ?? 0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF660033),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (sDress['event_type'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF660033).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        sDress['event_type'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF660033),
                                        ),
                                      ),
                                    ),
                                  if (sDress['rating'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, size: 10, color: Colors.amber.shade600),
                                          const SizedBox(width: 2),
                                          Text(
                                            sDress['rating'].toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF660033),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showZoomView) return _buildZoomView();

    final dress = widget.dress;
    final images = List.from(dress['images'] ?? []);
    
    final isProcessingCart = _processingButton == 'cart';
    final isProcessingLike = _processingButton == 'like';
    final isProcessingBookmark = _processingButton == 'bookmark';
    final isProcessingTryOn = _processingButton == 'tryon';
    final isProcessingShare = _processingButton == 'share';
    final isProcessingRate = _processingButton == 'rate';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 450,
                pinned: true,
                floating: true,
                backgroundColor: Colors.black.withOpacity(0.3),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      GestureDetector(
                        onDoubleTap: _onImageDoubleTap,
                        child: PageView.builder(
                          controller: _imageController,
                          itemCount: images.length,
                          onPageChanged: (index) => setState(() => _currentZoomIndex = index),
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => setState(() { _showZoomView = true; _currentZoomIndex = index; }),
                            child: Image.network(
                              _formatImageUrl(images[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200], 
                                child: const Center(child: Icon(Icons.broken_image, size: 50)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      if (_showHeartOverlay)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _heartController,
                            builder: (context, child) {
                              return Center(
                                child: Opacity(
                                  opacity: _heartFadeAnimation.value,
                                  child: Transform.scale(
                                    scale: _heartScaleAnimation.value,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      
                      if (images.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _imageController,
                              count: images.length,
                              effect: const ExpandingDotsEffect(
                                activeDotColor: Colors.white,
                                dotColor: Colors.white54,
                                dotHeight: 6,
                                dotWidth: 6,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  isProcessingShare
                      ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                      : IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _shareDress),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              dress['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF660033),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'Rs. ${dress['price']}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isProcessingLike ? null : _toggleLike,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _hasLiked ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    isProcessingLike
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                                        : Icon(
                                            _hasLiked ? Icons.favorite : Icons.favorite_border,
                                            color: _hasLiked ? Colors.red : Colors.grey.shade600,
                                            size: 16,
                                          ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_likeCount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _hasLiked ? Colors.red : Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.remove_red_eye, color: Colors.blue.shade600, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_viewCount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      isProcessingRate
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF660033)))
                          : _buildRatingSection(),
                      
                      if (dress['rental_price'] != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_offer, color: Colors.green.shade700, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Rent: Rs. ${dress['rental_price']}/day',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const Divider(height: 24),
                      
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF660033),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (dress['description'] != null) _buildInfoRow(Icons.description, 'Description', dress['description']),
                      if (dress['event_type'] != null) _buildInfoRow(Icons.event, 'Event', dress['event_type']),
                      if (dress['style'] != null) _buildInfoRow(Icons.style, 'Style', dress['style']),
                      if (dress['fabric'] != null) _buildInfoRow(Icons.texture, 'Fabric', dress['fabric']),
                      if (dress['season'] != null) _buildInfoRow(Icons.wb_sunny, 'Season', dress['season']),
                      if (_vendorName != null) _buildInfoRow(Icons.store, 'From', _vendorName!),
                      
                      const SizedBox(height: 20),
                      
                      if (widget.role == 'bride') ...[
                        AnimatedBuilder(
                          animation: _tryOnController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _tryOnController.value * 2),
                              child: SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: isProcessingTryOn ? null : _navigateToAutoFitTryOn,
                                  icon: isProcessingTryOn
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.camera_alt, size: 16),
                                  label: Text(isProcessingTryOn ? 'Loading...' : 'Virtual Try-On', style: const TextStyle(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // ✅ VERTICAL SIMILAR DRESSES SECTION
                      _buildSimilarDressesSection(),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          if (_showHeartOverlay)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
      
      // Bottom navigation bar
      bottomNavigationBar: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCompactNavItem(
              icon: isProcessingBookmark
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF660033)))
                  : Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? const Color(0xFF660033) : Colors.grey.shade600,
                      size: 18,
                    ),
              label: 'Save',
              onTap: isProcessingBookmark ? null : _toggleBookmark,
            ),
            
            _buildCompactNavItem(
              icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF660033), size: 18),
              label: 'Cart',
              onTap: _navigateToCartScreen,
            ),
            
            _buildCompactNavItem(
              icon: const Icon(Icons.collections_bookmark, color: Color(0xFF660033), size: 18),
              label: 'Saved',
              onTap: _navigateToBookmarkScreen,
            ),
            
            // ADD TO CART BUTTON
            Container(
              width: 100,
              height: 38,
              child: ElevatedButton(
                onPressed: isProcessingCart ? null : addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF660033),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: isProcessingCart
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart, size: 14),
                          SizedBox(width: 4),
                          Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactNavItem({
    required Widget icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF660033).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: icon is SizedBox ? icon : icon,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomView() {
    final images = List.from(widget.dress['images'] ?? []);
    final isProcessingShare = _processingButton == 'share';
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: images.length,
            builder: (_, index) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(_formatImageUrl(images[index])),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
            pageController: PageController(initialPage: _currentZoomIndex),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _showZoomView = false),
                  ),
                  isProcessingShare
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: _shareDress,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}