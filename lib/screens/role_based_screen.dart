import 'package:bridalease_fyp/screens/ProfileSetupScreen.dart';
import 'package:bridalease_fyp/screens/budget_assistance_screen.dart';
import 'package:bridalease_fyp/screens/cart_screen.dart';
import 'package:bridalease_fyp/screens/change_language_screen.dart';
import 'package:bridalease_fyp/screens/contact_us_screen.dart';
import 'package:bridalease_fyp/screens/faqs_screen.dart';
import 'package:bridalease_fyp/screens/general_screen.dart';
import 'package:bridalease_fyp/screens/manage_account_screen.dart';
import 'package:bridalease_fyp/screens/privacy_policy_screen.dart';
import 'package:bridalease_fyp/screens/order_history_screen.dart' hide supabase;
import 'package:bridalease_fyp/screens/terms_conditions_screen.dart';
import 'package:bridalease_fyp/screens/catalog_screen.dart' hide supabase;
import 'package:bridalease_fyp/screens/upload_dress_screen.dart';
import 'package:bridalease_fyp/screens/vendor_dress_management_screen.dart' hide supabase;
import 'package:bridalease_fyp/screens/vendor_orders_screen.dart' hide supabase;
import 'package:bridalease_fyp/screens/sales_analytics_screen.dart' hide supabase;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleBasedScreen extends StatefulWidget {
  final String role;
  const RoleBasedScreen({super.key, required this.role});

  @override
  State<RoleBasedScreen> createState() => _RoleBasedScreenState();
}

class _RoleBasedScreenState extends State<RoleBasedScreen> {
  String userEmail = '';
  String userName = '';
  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      
      try {
        final response = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          userEmail = user.email ?? 'User';
          userName = response['full_name'] ?? 'User';
          _userData = response;
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          userEmail = user.email ?? 'User';
          userName = 'User';
        });
      }
    }
  }

  Widget getBody() {
    if (widget.role == 'vendor') {
      return UploadDressScreen();
    } else {
      return CatalogScreen(role: widget.role);
    }
  }

  void logout() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GeneralScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  void _navigateToManageAccount() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageAccountScreen()),
    );
  }

  void _navigateToUpdateProfile() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(
          isFromLogin: false,
          existingUserData: _userData, // ✅ Pass existing data for edit
        ),
      ),
    ).then((result) {
      if (result == true) {
        fetchUser(); // Refresh user data after update
      }
    });
  }

  Widget drawerTile(IconData icon, String title, VoidCallback onTap, {Color? iconColor, Color? bgColor}) {
    final color = iconColor ?? const Color(0xFF660033);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon, 
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(226, 0, 0, 0),
            fontSize: 15,
          ),
        ),
        trailing: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.chevron_right,
            color: color,
            size: 20,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF660033),
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFFF5F5F5),
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF660033),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF660033),
                      Color(0xFF8B0040),
                    ],
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF660033),
                    ),
                  ),
                ),
                accountName: Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  userEmail,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              
              // ========== PROFILE SECTION ==========
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  'PROFILE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              // ✅ Update Profile with existing data
              drawerTile(Icons.person, "Update Profile", _navigateToUpdateProfile, 
                iconColor: const Color(0xFF660033)),
              
              // ========== ACCOUNT SETTINGS ==========
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  'ACCOUNT SETTINGS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              drawerTile(Icons.settings, "Manage Account", _navigateToManageAccount, 
                iconColor: const Color(0xFF660033)),
              
              drawerTile(Icons.language, "Change Language", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangeLanguageScreen()),
                );
              }, iconColor: const Color(0xFF660033)),
              
              // ========== VENDOR SPECIFIC ==========
              if (widget.role == 'vendor') ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'VENDOR TOOLS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                drawerTile(
                  Icons.shopping_bag, 
                  "Manage Orders", 
                  () {
                    Navigator.pop(context);
                    if (_currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendorOrdersScreen(
                            user: _currentUser!,
                          ),
                        ),
                      );
                    }
                  },
                  iconColor: Colors.orange,
                ),
                
                drawerTile(Icons.view_list, "My Dresses", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VendorDressManagementScreen()),
                  );
                }, iconColor: Colors.purple),
                
                drawerTile(Icons.analytics, "Sales Analytics", () {
                  Navigator.pop(context);
                  if (_currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalesAnalyticsScreen(
                          user: _currentUser!,
                        ),
                      ),
                    );
                  }
                }, iconColor: Colors.green),
                
                drawerTile(Icons.cloud_upload, "Upload Dress", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadDressScreen()),
                  );
                }, iconColor: const Color(0xFF660033)),
              ],
              
              // ========== BRIDE SPECIFIC ==========
              if (widget.role == 'bride') ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'SHOPPING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                drawerTile(Icons.history, "Order History", () {
                  Navigator.pop(context);
                  if (_currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderHistoryScreen(
                          user: _currentUser!,
                        ),
                      ),
                    );
                  }
                }, iconColor: const Color(0xFF660033)),
                
                drawerTile(Icons.shopping_cart, "My Cart", () {
                  Navigator.pop(context);
                  if (_currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(
                          user: _currentUser!,
                        ),
                      ),
                    );
                  }
                }, iconColor: const Color(0xFF660033)),
                
                // ✅ Budget Assistant - Already exists in home, but adding in drawer too
                drawerTile(Icons.calculate, "Budget Assistant", () {
                  Navigator.pop(context);
                  // Get all dresses from catalog
                  // For now, navigate with empty list - will be populated from catalog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetAssistanceScreen(
                        dresses: [], // Will be populated from catalog
                        onBack: () {},
                      ),
                    ),
                  );
                }, iconColor: Colors.teal),
              ],
              
              // ========== SUPPORT SECTION ==========
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  'SUPPORT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              drawerTile(Icons.help_center, "FAQs", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FAQsScreen()),
                );
              }, iconColor: Colors.blue),
              
              drawerTile(Icons.phone, "Contact Us", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                );
              }, iconColor: Colors.teal),
              
              drawerTile(Icons.feedback, "Feedback", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                );
              }, iconColor: Colors.deepPurple),
              
              // ========== LEGAL SECTION ==========
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  'LEGAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              drawerTile(Icons.security, "Privacy Policy", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              }, iconColor: Colors.indigo),
              
              drawerTile(Icons.description, "Terms & Conditions", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsConditionsScreen(),
                  ),
                );
              }, iconColor: Colors.brown),
              
              const Divider(),
              drawerTile(Icons.logout, "Logout", logout, iconColor: Colors.red),
              
              // App Info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'BridalEase v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Making bridal dreams come true',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copyright, size: 10, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${DateTime.now().year} BridalEase. All rights reserved.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: getBody(),
    );
  }
}