import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class AppAnimations {
  // Animation durations
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 800);
  
  // Animation curves
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve easeOutBack = Curves.easeOutBack;
  
  // Lottie file paths
  static const String welcome = 'assets/lottie/welcome.json';
  static const String success = 'assets/lottie/success.json';
  static const String loading = 'assets/lottie/loading.json';
  static const String dress = 'assets/lottie/dress.json';
  static const String camera = 'assets/lottie/camera.json';
  static const String empty = 'assets/lottie/empty.json';
  static const String profile = 'assets/lottie/profile.json';
  static const String login = 'assets/lottie/login.json';
  static const String upload = 'assets/lottie/upload.json';
}

// Helper for page transitions
class AppPageTransitions {
  static PageRouteBuilder slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 600),
    );
  }
}