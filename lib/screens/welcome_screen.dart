import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'general_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _textFloatController;
  late AnimationController _arrowFloatController;
  late AnimationController _scaleController;
  
  late Animation<Offset> _textFloatAnimation;
  late Animation<Offset> _arrowFloatAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Text float controller - slow movement
    _textFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    // Arrow float controller - faster movement
    _arrowFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // Scale controller for subtle pulse
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Text float animation - larger movement
    _textFloatAnimation = Tween<Offset>(
      begin: const Offset(0, -15),
      end: const Offset(0, 15),
    ).animate(
      CurvedAnimation(
        parent: _textFloatController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Arrow float animation - smaller, faster movement
    _arrowFloatAnimation = Tween<Offset>(
      begin: const Offset(8, -8),
      end: const Offset(-8, 8),
    ).animate(
      CurvedAnimation(
        parent: _arrowFloatController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Scale animation for arrow
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image fully fit
          SizedBox.expand(
            child: Image.asset(
              'assets/images/welcome_bg1.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Overlay for contrast
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.25),
          ),
          
          // App name left-aligned, slightly above center - WITH FLOAT
          Align(
            alignment: const Alignment(-1.0, -0.2),
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: AnimatedBuilder(
                animation: _textFloatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _textFloatAnimation.value,
                    child: Text(
                      "BridalEase",
                      style: GoogleFonts.pacifico(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 144, 75, 96),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: const Offset(2, 2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Arrow button bottom-right - WITH FLOAT AND SCALE
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const GeneralScreen()),
                  );
                },
                child: AnimatedBuilder(
                  animation: Listenable.merge([_arrowFloatController, _scaleController]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _arrowFloatAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.6),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                              // Additional glow shadow
                              BoxShadow(
                                color: const Color(0xFF660033).withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF660033),
                            size: 34,
                          ),
                        ),
                      ),
                    );
                  },
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
    _textFloatController.dispose();
    _arrowFloatController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}