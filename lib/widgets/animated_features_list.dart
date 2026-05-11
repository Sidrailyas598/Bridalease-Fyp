// lib/widgets/animated_features_list.dart
import 'package:flutter/material.dart';
import 'package:bridalease_fyp/utils/colors.dart';

class AnimatedFeaturesList extends StatefulWidget {
  final VoidCallback onGetStarted;
  final List<Animation<Offset>>? cardFloatAnimations;
  
  const AnimatedFeaturesList({
    super.key,
    required this.onGetStarted,
    this.cardFloatAnimations,
  });

  @override
  State<AnimatedFeaturesList> createState() => _AnimatedFeaturesListState();
}

class _AnimatedFeaturesListState extends State<AnimatedFeaturesList> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  final List<Map<String, dynamic>> features = const [
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'Virtual Try-On',
      'description': 'Experience your dream dress with our AI-powered virtual trial',
      'color': Color(0xFF660033),
    },
    {
      'icon': Icons.shopping_bag_outlined,
      'title': 'Browse Collection',
      'description': 'Explore handpicked bridal wear from top designers',
      'color': Color(0xFF99004C),
    },
    {
      'icon': Icons.local_offer_outlined,
      'title': 'Rent or Purchase',
      'description': 'Flexible options that suit your special occasion',
      'color': Color(0xFFCC0066),
    },
    {
      'icon': Icons.delivery_dining_outlined,
      'title': 'Free Delivery',
      'description': 'Complimentary shipping and hassle-free returns',
      'color': Color(0xFF660033),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimations = List.generate(
      features.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.6 + (index * 0.1),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _slideAnimations = List.generate(
      features.length,
      (index) => Tween<Offset>(
        begin: const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.6 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: AnimatedBuilder(
              animation: widget.cardFloatAnimations?[index] ?? AlwaysStoppedAnimation(Offset.zero),
              builder: (context, child) {
                return Transform.translate(
                  offset: widget.cardFloatAnimations != null 
                      ? widget.cardFloatAnimations![index].value 
                      : Offset.zero,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16), // 👈 BARA PADDING
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20), // 👈 ZYADA ROUNDED CORNERS
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryMaroon.withOpacity(0.12),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primaryMaroon.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon Container - BARA AUR BETTER
                        Container(
                          padding: const EdgeInsets.all(14), // 👈 BARA ICON CONTAINER
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                features[index]['color'].withOpacity(0.15),
                                features[index]['color'].withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16), // 👈 MATCHING CORNERS
                          ),
                          child: Icon(
                            features[index]['icon'],
                            color: features[index]['color'],
                            size: 28, // 👈 BARA ICON
                          ),
                        ),
                        const SizedBox(width: 16), // 👈 ZYADA SPACE
                        
                        // Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                features[index]['title'],
                                style: const TextStyle(
                                  fontSize: 16, // 👈 BARA FONT
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF660033),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6), // 👈 ZYADA SPACE
                              Text(
                                features[index]['description'],
                                style: TextStyle(
                                  fontSize: 13, // 👈 BARA FONT
                                  color: Colors.grey[700],
                                  height: 1.4, // 👈 BETTER LINE HEIGHT
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Subtle Arrow Indicator (optional)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: features[index]['color'].withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}