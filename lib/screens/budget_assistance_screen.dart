import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dress_detail_screen.dart';

class BudgetAssistanceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> dresses;
  final VoidCallback onBack;

  const BudgetAssistanceScreen({
    super.key,
    required this.dresses,
    required this.onBack,
  });

  @override
  State<BudgetAssistanceScreen> createState() => _BudgetAssistanceScreenState();
}

class _BudgetAssistanceScreenState extends State<BudgetAssistanceScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _budgetController = TextEditingController();
  bool _preferRental = true;
  String? _selectedSeason = 'All Seasons';
  String? _selectedEventType = 'All Events';
  double _userBudget = 0;
  bool _showResults = false;
  List<Map<String, dynamic>> _recommendedDresses = [];
  bool _isLoading = false;
  
  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _floatingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;

  final String baseUrl = 'https://booeleldfprujllrxoik.supabase.co/storage/v1/object/public/dresses/';
  final List<String> _seasons = ['Spring', 'Summer', 'Autumn', 'Winter', 'All Seasons'];
  final List<String> _eventTypes = ['Mehndi', 'Barat', 'Nikkah', 'Walima', 'Wedding', 'Engagement', 'Reception', 'All Events'];
  final NumberFormat _currencyFormat = NumberFormat("#,##0");

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _floatingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController, 
      curve: Curves.elasticOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _animationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _calculateBudgetRecommendations() async {
    if (_budgetController.text.isEmpty) {
      _showSnackBar('Please enter your budget', Colors.red);
      return;
    }

    final budget = double.tryParse(_budgetController.text) ?? 0;
    if (budget <= 0) {
      _showSnackBar('Please enter a valid amount', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    List<Map<String, dynamic>> filtered = widget.dresses.where((dress) {
      final dSeason = (dress['season'] ?? '').toString().toLowerCase();
      final dEvent = (dress['event_type'] ?? '').toString().toLowerCase();
      
      bool sMatch = _selectedSeason == 'All Seasons' || dSeason.contains(_selectedSeason!.toLowerCase());
      bool eMatch = _selectedEventType == 'All Events' || dEvent.contains(_selectedEventType!.toLowerCase());
      return sMatch && eMatch;
    }).toList();

    _recommendedDresses = filtered.where((d) {
      double price = _preferRental 
          ? (d['rental_price']?.toDouble() ?? double.infinity) 
          : (d['price']?.toDouble() ?? double.infinity);
      return price <= budget;
    }).toList();

    _recommendedDresses.sort((a, b) {
      final aScore = (a['rating'] ?? 0) * (1 - ((_preferRental ? a['rental_price'] : a['price']) ?? 0) / budget);
      final bScore = (b['rating'] ?? 0) * (1 - ((_preferRental ? b['rental_price'] : b['price']) ?? 0) / budget);
      return bScore.compareTo(aScore);
    });

    setState(() {
      _userBudget = budget;
      _showResults = true;
      _isLoading = false;
    });

    _animationController.reset();
    _animationController.forward();
  }

  Widget _buildDressImage(dynamic imageData) {
    String path = '';
    if (imageData is List && imageData.isNotEmpty) path = imageData[0].toString();
    else if (imageData is String) path = imageData;

    if (path.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
      );
    }

    return Image.network(
      path.startsWith('http') ? path : '$baseUrl$path',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text(
          'Budget Assistant',
          style: TextStyle(
            color: Color(0xFF660033),
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
          onPressed: _showResults 
              ? () {
                  setState(() {
                    _showResults = false;
                    _animationController.reset();
                    _animationController.forward();
                  });
                }
              : widget.onBack,
        ),
        actions: [
          if (_showResults)
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF660033), Color(0xFF883366)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_recommendedDresses.length} Matches',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading 
        ? _buildLoadingScreen()
        : _showResults 
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildResultsUI(),
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildInputUI(),
                ),
              ),
      floatingActionButton: _showResults && _recommendedDresses.isNotEmpty
          ? TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      setState(() {
                        _showResults = false;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                    backgroundColor: const Color(0xFF660033),
                    elevation: 4,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Adjust Budget',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF660033), Color(0xFF883366)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF660033).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Column(
                  children: [
                    Text(
                      'Finding Best Deals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF660033),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Searching through ${widget.dresses.length}+ dresses...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 2000),
            builder: (context, value, child) {
              return Container(
                width: 200 * value,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF660033).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF660033), Color(0xFF883366)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsUI() {
    return Column(
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildSummaryCard(),
        ),
        Expanded(
          child: _recommendedDresses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _recommendedDresses.length,
                  itemBuilder: (context, index) {
                    return TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + (index * 80)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 40 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildResultCard(_recommendedDresses[index], index),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF660033).withOpacity(0.1), const Color(0xFF883366).withOpacity(0.05)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sentiment_dissatisfied,
                      size: 50,
                      color: const Color(0xFF660033).withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Dresses Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF660033),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try increasing your budget or changing filters',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showResults = false;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Adjust Filters', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF660033),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF660033), Color(0xFF883366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF660033).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Budget',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Rs ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_currencyFormat.format(_userBudget)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _preferRental ? Icons.calendar_today : Icons.shopping_bag,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryChip(
                icon: Icons.style,
                label: _selectedEventType ?? 'All',
              ),
              _buildSummaryChip(
                icon: Icons.wb_sunny,
                label: _selectedSeason ?? 'All',
              ),
              _buildSummaryChip(
                icon: Icons.check_circle,
                label: '${_recommendedDresses.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> dress, int index) {
    final rentalPrice = (dress['rental_price'] ?? 0).toDouble();
    final purchasePrice = (dress['price'] ?? 0).toDouble();
    final isInBudget = _preferRental 
        ? rentalPrice <= _userBudget 
        : purchasePrice <= _userBudget;
    
    return Hero(
      tag: 'dress_${dress['id']}_$index',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DressDetailScreen(dress: dress, role: 'bride'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: _buildDressImage(dress['images']),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + (index * 50)),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isInBudget ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isInBudget ? Icons.check_circle : Icons.trending_up,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isInBudget ? 'In Budget' : 'Near',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (dress['rating'] != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 400 + (index * 50)),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, size: 10, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      dress['rating'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dress['name'] ?? dress['dress_name'] ?? 'Dress',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF660033).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RENT',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Text(
                                        'Rs ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF660033),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_currencyFormat.format(rentalPrice)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF660033),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BUY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Text(
                                        'Rs ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_currencyFormat.format(purchasePrice)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event_available, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            dress['event_type'] ?? 'Wedding',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.wb_sunny, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            dress['season'] ?? 'All',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: (_preferRental ? rentalPrice : purchasePrice) / _userBudget,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isInBudget 
                                    ? [Colors.green, Colors.lightGreen]
                                    : [Colors.orange, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((_preferRental ? rentalPrice : purchasePrice) / _userBudget * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 9,
                          color: isInBudget ? Colors.green[600] : Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputUI() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Card with Rs Prefix
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF660033), Color(0xFF883366)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF660033).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedBuilder(
                                animation: _floatingAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatingAnimation.value),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Enter your budget to find matching dresses',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ✅ UPDATED: TextField with Rs prefix
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Rs',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            hintText: '0',
                            hintStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white, width: 1),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.15),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Preference Card
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPreferenceCard(
                              title: 'Rent',
                              icon: Icons.calendar_today,
                              isSelected: _preferRental,
                              onTap: () => setState(() => _preferRental = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPreferenceCard(
                              title: 'Buy',
                              icon: Icons.shopping_bag,
                              isSelected: !_preferRental,
                              onTap: () => setState(() => _preferRental = false),
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
          const SizedBox(height: 16),
          
          // Filters Card
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection('Season', _seasons, _selectedSeason, (val) {
                            setState(() => _selectedSeason = val);
                          }),
                          const SizedBox(height: 16),
                          _buildFilterSection('Event', _eventTypes, _selectedEventType, (val) {
                            setState(() => _selectedEventType = val);
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          
          // Find Button
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF660033),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _calculateBudgetRecommendations,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Find Best Deals',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF660033), Color(0xFF883366)],
                )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? current,
    Function(String) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF660033),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = current == option;
            return FilterChip(
              label: Text(option, style: TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              backgroundColor: Colors.grey.shade50,
              selectedColor: const Color(0xFF660033).withOpacity(0.1),
              checkmarkColor: const Color(0xFF660033),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF660033) : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? const Color(0xFF660033) : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            );
          }).toList(),
        ),
      ],
    );
  }
}