// lib/screens/ForgotPasswordScreen.dart
import 'package:bridalease_fyp/supabase.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool loading = false;
  bool emailSent = false;
  bool emailExists = true; // Default true, will check
  String? errorMessage;

  Future<bool> _checkEmailExists(String email) async {
    try {
      // Check if user exists by trying to sign in (read-only operation)
      // Supabase doesn't have direct email check, so we try a safe method
      final response = await supabase
          .from('users')
          .select('id, email')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking email: $e');
      // If we can't check, assume it exists for security
      return true;
    }
  }

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Email format validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      emailExists = true; // Reset to default
    });

    try {
      // First check if email exists
      final emailExists = await _checkEmailExists(email);
      
      if (!emailExists) {
        setState(() {
          loading = false;
          this.emailExists = false;
          errorMessage = 'This email is not registered. Please create an account first.';
        });
        return;
      }

      // Send reset link only if email exists
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'bridalease://reset-password',
      );

      setState(() {
        loading = false;
        emailSent = true;
        this.emailExists = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Reset password error: $e');
      setState(() => loading = false);
      
      String errorMsg = 'Error sending reset link';
      
      // Check for specific errors
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('rate limit')) {
        errorMsg = 'Please wait before trying again';
      } else if (errorStr.contains('not found') || 
                 errorStr.contains('user not found') ||
                 errorStr.contains('invalid email')) {
        // This shouldn't happen if our check worked, but just in case
        setState(() {
          emailExists = false;
          errorMessage = 'This email is not registered. Please create an account first.';
        });
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    setState(() {
      emailSent = false;
      emailExists = true;
      errorMessage = null;
      emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color(0xFF660033),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/flowers_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.2),
          ),

          // Center card
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: size.width * 0.87,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      emailExists ? Icons.lock_reset : Icons.person_add,
                      size: 60,
                      color: emailExists ? const Color(0xFFF8E231) : Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      emailExists ? 'Reset Password' : 'Account Not Found',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: emailExists ? const Color(0xFF660033) : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Error message for unregistered email
                    if (errorMessage != null && !emailExists)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    Text(
                      emailSent
                          ? "Check your email for the reset link"
                          : emailExists
                              ? "Enter your email to receive a reset link"
                              : "This email is not registered with us",
                      style: TextStyle(
                        fontSize: 15,
                        color: emailExists ? Colors.grey.shade600 : Colors.orange,
                        fontWeight: emailExists ? FontWeight.normal : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    if (!emailSent && emailExists) ...[
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: const TextStyle(color: Color(0xFF660033)),
                          hintText: 'Enter your registered email',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFF8E231),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: const Color(0xFF660033).withOpacity(0.5),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.email, color: Color(0xFF660033)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Security note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.security, color: Colors.blue, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Reset link will only be sent to registered emails',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : sendResetLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF660033),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ] 
                    else if (!emailSent && !emailExists) ...[
                      // Show when email is not registered
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.person_add_disabled,
                              color: Colors.orange,
                              size: 50,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'No Account Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'The email "${emailController.text}" is not registered.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Please create an account first.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Buttons for unregistered email
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearForm,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: const BorderSide(color: Color(0xFF660033)),
                              ),
                              child: const Text(
                                'Try Different Email',
                                style: TextStyle(
                                  color: Color(0xFF660033),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/signup');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF660033),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]
                    else if (emailSent) ...[
                      // Success screen
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Email Sent Successfully!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF660033),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF660033).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          emailController.text.trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF660033),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text(
                        'Please check your inbox and follow the instructions in the email to reset your password.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.yellow.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Check your spam folder if you don\'t see the email',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _clearForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: Color(0xFF660033)),
                          ),
                          child: const Text(
                            'Send Another Link',
                            style: TextStyle(
                              color: Color(0xFF660033),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 25),
                    Divider(
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 15),
                    
                    // Back to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Remember your password? ",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFF660033),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
  
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}