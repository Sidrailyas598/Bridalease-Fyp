// lib/screens/general_screen.dart
import 'package:bridalease_fyp/screens/role_based_screen.dart';
import 'package:bridalease_fyp/widgets/animated_features_list.dart';
import 'package:bridalease_fyp/utils/colors.dart';
import 'package:flutter/material.dart';
import 'signup_screen.dart';

class GeneralScreen extends StatefulWidget {
  const GeneralScreen({super.key});

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _dressAnimationController;
  late Animation<double> _dressScaleAnimation;
  late Animation<double> _dressRotationAnimation;
  late Animation<Offset> _dressFloatAnimation;
  
  late AnimationController _cardAnimationController;
  late List<Animation<Offset>> _cardFloatAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _dressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _dressScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _dressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _dressRotationAnimation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(
        parent: _dressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _dressFloatAnimation = Tween<Offset>(
      begin: const Offset(0, -8),
      end: const Offset(0, 8),
    ).animate(
      CurvedAnimation(
        parent: _dressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Cards ke liye subtle float animations
    _cardFloatAnimations = List.generate(4, (index) {
      final phase = index * 0.25;
      return Tween<Offset>(
        begin: Offset(0, -3 - (index * 1.0)),
        end: Offset(0, 3 + (index * 1.0)),
      ).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            phase * 0.3,
            phase * 0.3 + 0.4,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  void _showAuthOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryMaroon.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryMaroon,
                    AppColors.lightMaroon,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryMaroon.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RoleBasedScreen(role: 'bride')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: BorderSide(
                    color: AppColors.primaryMaroon,
                    width: 2,
                  ),
                ),
                child: Text(
                  "Explore as Guest",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryMaroon,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.extraLightPink,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.lightPink,
                      AppColors.extraLightPink,
                      Colors.white,
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated decorative circles
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50 - (20 * (1 - _animationController.value)),
                    right: -50 - (20 * (1 - _animationController.value)),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryMaroon.withOpacity(0.1 * _animationController.value),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30 - (20 * (1 - _animationController.value)),
                    left: -30 - (20 * (1 - _animationController.value)),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.softPink.withOpacity(0.3 * _animationController.value),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Top spacing
                  const SizedBox(height: 20),
                  
                  // Animated Dress Image - PERFECT SIZE (180)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedBuilder(
                        animation: _dressAnimationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              _dressFloatAnimation.value.dy,
                            ),
                            child: Transform.rotate(
                              angle: _dressRotationAnimation.value,
                              child: Transform.scale(
                                scale: _dressScaleAnimation.value,
                                child: Container(
                                  width: 180, // 👈 PERFECT SIZE - na bara na chota
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryMaroon.withOpacity(0.25),
                                        blurRadius: 25,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/dress.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppColors.primaryMaroon.withOpacity(0.1),
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 60,
                                            color: AppColors.primaryMaroon,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20), // Balanced spacing

                  // Animated Features List - Takes remaining space
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _cardAnimationController,
                      builder: (context, child) {
                        return AnimatedFeaturesList(
                          onGetStarted: () {},
                          cardFloatAnimations: _cardFloatAnimations,
                        );
                      },
                    ),
                  ),

                  // Bottom spacing for button
                  const SizedBox(height: 70), // Space for FAB
                ],
              ),
            ),
          ),

          // Small Get Started Button at Bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryMaroon,
                          AppColors.lightMaroon,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryMaroon.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAuthOptions(context),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Get Started",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dressAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }
}