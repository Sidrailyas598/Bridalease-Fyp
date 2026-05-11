import 'package:bridalease_fyp/screens/ProfileSetupScreen.dart';
import 'package:bridalease_fyp/supabase.dart';
import 'package:flutter/material.dart';
import 'signup_screen.dart' hide supabase;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  
  // Animation Controllers
  AnimationController? _fadeController;
  AnimationController? _slideController;
  AnimationController? _scaleController;
  AnimationController? _pulseController;
  AnimationController? _floatController;
  AnimationController? _buttonFloatController;
  
  // Animations
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _pulseAnimation;
  Animation<Offset>? _floatAnimation;
  Animation<Offset>? _buttonFloatAnimation;
  Animation<Offset>? _signupFloatAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize all controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    _buttonFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController!,
        curve: Curves.easeIn,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController!,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController!,
        curve: Curves.easeOutBack,
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      ),
    );
    
    _floatAnimation = Tween<Offset>(
      begin: const Offset(0, -8),
      end: const Offset(0, 8),
    ).animate(
      CurvedAnimation(
        parent: _floatController!,
        curve: Curves.easeInOut,
      ),
    );
    
    _buttonFloatAnimation = Tween<Offset>(
      begin: const Offset(0, -4),
      end: const Offset(0, 4),
    ).animate(
      CurvedAnimation(
        parent: _buttonFloatController!,
        curve: Curves.easeInOut,
      ),
    );
    
    _signupFloatAnimation = Tween<Offset>(
      begin: const Offset(0, -2),
      end: const Offset(0, 2),
    ).animate(
      CurvedAnimation(
        parent: _buttonFloatController!,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations
    _fadeController?.forward();
    _slideController?.forward();
    _scaleController?.forward();
    _pulseController?.repeat(reverse: true);
    _floatController?.repeat(reverse: true);
    _buttonFloatController?.repeat(reverse: true);
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      setState(() => loading = false);

      if (response.user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          );
        }
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Safety check
    if (_fadeController == null || 
        _slideController == null || 
        _scaleController == null || 
        _pulseController == null || 
        _floatController == null ||
        _buttonFloatController == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF660033)),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/flowers_bg.png"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.9),
                  BlendMode.softLight,
                ),
              ),
            ),
          ),

          // Center login card
          Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation!,
                child: SlideTransition(
                  position: _slideAnimation!,
                  child: ScaleTransition(
                    scale: _scaleAnimation!,
                    child: AnimatedBuilder(
                      animation: _floatController!,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: _floatAnimation?.value ?? Offset.zero,
                          child: Container(
                            width: size.width * 0.8,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.98),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF660033).withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF660033).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFF660033).withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Animated Icon
                                AnimatedBuilder(
                                  animation: _pulseController!,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation?.value ?? 1.0,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF660033), Color(0xFF99004C)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF660033).withOpacity(0.3),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.verified_user,
                                          size: 32,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Welcome Text
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF660033),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                
                                // Subtitle
                                Text(
                                  "Sign in to your account",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Email Field
                                TextField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF660033),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      color: Color(0xFF660033),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF660033),
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: const Color(0xFF660033).withOpacity(0.7),
                                      size: 20,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                ),
                                
                                const SizedBox(height: 14),
                                
                                // Password Field
                                TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF660033),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      color: Color(0xFF660033),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    hintText: 'Enter your password',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF660033),
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: const Color(0xFF660033).withOpacity(0.7),
                                      size: 20,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Login Button - FIXED (mainAxisSize: MainAxisSize.min)
                                AnimatedBuilder(
                                  animation: _buttonFloatController!,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: _buttonFloatAnimation?.value ?? Offset.zero,
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton(
                                          onPressed: loading ? null : login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF660033),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            elevation: 4,
                                            shadowColor: const Color(0xFF660033).withOpacity(0.4),
                                          ),
                                          child: loading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Row(
                                                  mainAxisSize: MainAxisSize.min, // 👈 FIX: Sirf utni jagah lo jitni zaroorat ho
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Sign In',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Icon(Icons.arrow_forward, size: 18),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 14),
                                
                                // Divider with text
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'or',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 14),
                                
                                // Sign Up Link - FIXED (mainAxisSize: MainAxisSize.min)
                                AnimatedBuilder(
                                  animation: _buttonFloatController!,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: _signupFloatAnimation?.value ?? Offset.zero,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min, // 👈 FIX: Sirf utni jagah lo jitni zaroorat ho
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "New BridalEase? ",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(25),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFF660033).withOpacity(0.1),
                                                    const Color(0xFF99004C).withOpacity(0.05),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: const Color(0xFF660033).withOpacity(0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  color: Color(0xFF660033),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      },
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
    _fadeController?.dispose();
    _slideController?.dispose();
    _scaleController?.dispose();
    _pulseController?.dispose();
    _floatController?.dispose();
    _buttonFloatController?.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}