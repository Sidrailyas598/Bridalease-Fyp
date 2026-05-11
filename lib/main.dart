import 'package:bridalease_fyp/screens/ProfileSetupScreen.dart';
import 'package:bridalease_fyp/screens/UpdatePasswordScreen.dart';
import 'package:bridalease_fyp/screens/general_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import background services - TEMPORARILY COMMENTED
// import 'package:bridalease_fyp/services/background_service.dart';
// import 'package:bridalease_fyp/services/rental_reminder_service.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_based_screen.dart' hide LoginScreen;

final AppLinks appLinks = AppLinks();
final supabase = Supabase.instance.client;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Load environment variables
  await dotenv.load(fileName: ".env");
  
  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: 'https://booeleldfprujllrxoik.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvb2VsZWxkZnBydWpsbHJ4b2lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzOTY1NTcsImV4cCI6MjA3OTk3MjU1N30.E4RQ9GZaqJs7pE5VxkgfUkIC_F3xREKzJ2k96a_3e0U',
  );

  // ✅ Initialize notification system for rental reminders - TEMPORARILY COMMENTED
  // await RentalReminderService.initNotifications();
  
  // ✅ Initialize background service for automatic reminders - TEMPORARILY COMMENTED
  // await BackgroundService.init();
  
  // Optional: Check reminders immediately on app start
  // Uncomment if you want to check immediately
  // await BackgroundService.forceCheck();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initDeepLink();
  }

  void initDeepLink() {
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print('🔗 Deep Link Received: $uri');
        print('📝 Query Parameters: ${uri.queryParameters}');
        
        // Handle email verification
        if (uri.toString().contains('type=signup') || 
            uri.queryParameters['type'] == 'signup') {
          print('✅ Email verification link detected');
          _showVerificationSuccess();
        }
        
        // Handle password reset
        if (uri.toString().contains('type=recovery') || 
            uri.queryParameters['type'] == 'recovery') {
          print('🔑 Password reset link detected');
          
          final accessToken = uri.queryParameters['access_token'];
          final refreshToken = uri.queryParameters['refresh_token'];
          final type = uri.queryParameters['type'];
          
          print('📧 Access Token: $accessToken');
          print('🔄 Type: $type');
          
          if (type == 'recovery' && accessToken != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _navigateToResetPassword(accessToken, refreshToken);
            });
          }
        }
      }
    }, onError: (error) {
      print('❌ Deep link error: $error');
    });
  }

  void _showVerificationSuccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: const Text('✅ Email verified successfully! You can now sign in.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  void _navigateToResetPassword(String accessToken, String? refreshToken) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => UpdatePasswordScreen(
            accessToken: accessToken,
          ),
        ),
        (route) => false,
      );
    });
  }

  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF660033),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink,
        ).copyWith(
          secondary: const Color(0xFF660033),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          final authState = snapshot.data!;
          final session = authState.session;
          final user = session?.user;
          
          print('🔐 Auth Event: ${authState.event}');
          print('👤 User: ${user?.email}');
          print('📧 Email Verified: ${user?.emailConfirmedAt != null}');

          // Check if this is a recovery session
          final isRecoverySession = authState.event == AuthChangeEvent.passwordRecovery;
          
          if (isRecoverySession) {
            print('🔄 Recovery session detected');
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Processing password reset...'),
                  ],
                ),
              ),
            );
          }

          if (user != null && user.emailConfirmedAt != null) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserData(user.id),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading your profile...'),
                        ],
                      ),
                    ),
                  );
                }

                if (userSnapshot.hasError) {
                  print('❌ Error fetching user data: ${userSnapshot.error}');
                  return _buildErrorScreen('Error loading profile. Please try again.');
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userData = userSnapshot.data!;
                  final role = userData['role'] ?? 'bride';
                  final isBlocked = userData['is_blocked'] ?? false;
                  final isProfileComplete = userData['is_profile_complete'] ?? false;

                  print('🎭 User Role: $role');
                  print('🚫 User Blocked: $isBlocked');
                  print('✅ Profile Complete: $isProfileComplete');

                  if (isBlocked == true) {
                    return _buildBlockedScreen();
                  }

                  // Check if profile is complete
                  if (!isProfileComplete) {
                    return ProfileSetupScreen(
                      isFromLogin: true,
                      existingUserData: userData,
                    );
                  }

                  return RoleBasedScreen(role: role);
                }

                // User data not found - redirect to profile setup
                return ProfileSetupScreen(
                  isFromLogin: true,
                );
              },
            );
          } else if (user != null && user.emailConfirmedAt == null) {
            // Email not verified
            return LoginScreen();
          }
        }

        // Not logged in
        return const WelcomeScreen();
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        print('✅ User data fetched successfully');
        return response;
      } else {
        print('⚠️ No user data found');
        return null;
      }
    } catch (error) {
      print('❌ Error fetching user data: $error');
      return null;
    }
  }

  Widget _buildBlockedScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Account Blocked',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account has been temporarily suspended.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact our support team for assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const GeneralScreen()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF660033),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Return to Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const GeneralScreen()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF660033),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}