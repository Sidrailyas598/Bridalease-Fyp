import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

// Assuming this is correctly initialized in your main file
final supabase = Supabase.instance.client;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // strong password regex: at least 8 characters, one uppercase, one lowercase, one digit
  final _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  // -------------------------------------------------------
  // AUTH LOGIC IMPLEMENTATION (UPDATED)
  // -------------------------------------------------------

  /// The main function for the sign-up process.
  Future<void> _signUpFinal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final displayName = _displayNameController.text.trim();
      final phone = _phoneController.text.trim();

      // 1. Attempt to sign up directly.
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          "display_name": displayName,
          "phone": phone,
        },
        // IMPORTANT: The 'bridalease://login-callback' URL must be correctly configured
        emailRedirectTo: 'bridalease://login-callback',
      );

      // 2. Check if user was created
      if (response.user != null) {
        // SUCCESS CASE: New account created, verification email sent.
        _showSuccessDialog();
      } else {
        // If no user returned but no error thrown, this is unexpected
        setState(() => _loading = false);
        _showErrorDialog("Signup failed. Please try again.");
      }

    } on AuthException catch (authError) {
      setState(() => _loading = false);
      
      final errorMessage = authError.message.toLowerCase();
      
      // Check if this is an "already registered" error
      if (errorMessage.contains('already registered') ||
          errorMessage.contains('already exists') ||
          errorMessage.contains('email already') ||
          errorMessage.contains('user already')) {
        // ACCOUNT EXISTS CASE
        _showAccountExistsDialog();
      } else {
        // OTHER AUTH ERRORS
        _showErrorDialog(authError.message);
      }
      
    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog("An unexpected error occurred. Please try again.");
    }
  }

  // --- Widget Build and UI components (Unchanged for your request) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/flowers_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay for better text visibility
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.3),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Back button with custom positioning
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6.0),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main signup card
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9), // Semi-transparent white
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Section
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF660033), // Dark maroon color
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Join BridalEase to find your perfect dress',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Input Fields
                            _buildInput(
                              label: "Display Name *",
                              icon: Icons.person,
                              controller: _displayNameController,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Please enter your name";
                                }
                                if (RegExp(r'\d').hasMatch(v)) {
                                  return "Name should not contain numbers";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildInput(
                              label: "Email Address *",
                              icon: Icons.email,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Please enter your email";
                                }
                                // Basic email regex check
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                  return "Please enter a valid email address";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildInput(
                              label: "Phone Number *",
                              icon: Icons.phone,
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Please enter phone number";
                                }
                                if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                                  return "Only numbers allowed";
                                }
                                if (v.length > 11) return "Number too short";
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildPassword(
                              label: "Password *",
                              controller: _passwordController,
                              obscure: _obscurePassword,
                              toggle: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Enter password";
                                }
                                if (!_passwordRegex.hasMatch(v)) {
                                  return "Must be 8+ chars, with 1 uppercase, 1 lowercase, and 1 digit.";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildPassword(
                              label: "Confirm Password *",
                              controller: _confirmPasswordController,
                              obscure: _obscureConfirmPassword,
                              toggle: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return "Passwords do not match";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 30),

                            // Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _signUpFinal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF660033),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                    : const Text(
                                          "Create Account",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Already have account
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => LoginScreen()),
                                      );
                                    },
                                    child: const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        color: Color(0xFF660033),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // UTILITY WIDGETS (Unchanged)
  // -------------------------------------------------------

  Widget _buildInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: const Color(0xFF660033)),
        enabledBorder: _border(),
        focusedBorder: _border(color: const Color(0xFF660033)),
        border: _border(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
      ),
    );
  }

  Widget _buildPassword({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF660033)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF660033),
          ),
          onPressed: toggle,
        ),
        enabledBorder: _border(),
        focusedBorder: _border(color: const Color(0xFF660033)),
        border: _border(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
      ),
    );
  }

  OutlineInputBorder _border({Color color = Colors.grey}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  // --- Dialogs ---

  void _showAccountExistsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text("Account Exists"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("This email is already registered with us:"),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF660033),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Please use a different email or sign in with this email.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _emailController.clear();
              setState(() {});
            },
            child: const Text(
              "Try Different Email",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
            ),
            child: const Text(
              "Go to Sign In",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Sign Up Success"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Verification email has been sent to:"),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF660033),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Please check your email and click the verification link.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "After verification, you can sign in to your account.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow),
              ),
              child: const Text(
                "Note: Check your spam folder if you don't see the email.",
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
            ),
            child: const Text(
              "Go to Login",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ).then((_) {
      setState(() => _loading = false);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text("Error"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}