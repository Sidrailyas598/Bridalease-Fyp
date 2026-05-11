import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF660033),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/flowers_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Center(
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF660033),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 20),

                      // Last Updated
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF660033).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF660033).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.update, color: Color(0xFF660033)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Last Updated: January 1, 2024',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF660033),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Sections
                      _buildSection(
                        title: '1. Information We Collect',
                        content: '''
• Personal Information: Name, email, phone number, profile picture
• Wedding Details: Wedding date, venue, preferences
• Body Measurements: For dress fitting (optional)
• Vendor Business Info: Business name, address, contact details
• Payment Information: Securely processed via third-party providers
• Usage Data: How you interact with our app''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '2. How We Use Your Information',
                        content: '''
• To provide and maintain our services
• To personalize your bridal experience
• To connect brides with relevant vendors
• To process payments securely
• To send important updates and notifications
• To improve our app features''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '3. Data Sharing',
                        content: '''
We do NOT sell your personal data. We may share information:
• With trusted vendors (only with your consent)
• For legal compliance and protection
• With service providers (payment processors, hosting)
• During business transfers (mergers, acquisitions)''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '4. Data Security',
                        content: '''
• End-to-end encryption for sensitive data
• Secure cloud storage with Supabase
• Regular security audits
• Access controls and authentication
• SSL/TLS encryption for all communications''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '5. Your Rights',
                        content: '''
• Access your personal data
• Correct inaccurate information
• Delete your account and data
• Export your data
• Opt-out of marketing communications
• Withdraw consent at any time''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '6. Cookies & Tracking',
                        content: '''
• We use essential cookies for app functionality
• Optional analytics cookies to improve services
• You can manage cookie preferences in settings
• Third-party cookies from payment providers''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '7. Children\'s Privacy',
                        content: '''
Our services are not directed to individuals under 18.
We do not knowingly collect data from children.
If we discover such data, we will delete it immediately.''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '8. Contact Us',
                        content: '''
For privacy-related questions or concerns:
Email: privacy@bridalease.com
Address: 123 Bridal Street, Fashion City
Phone: +1 (555) 123-4567

Response Time: Within 48 hours''',
                      ),

                      const SizedBox(height: 30),

                      // Accept Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for reviewing our Privacy Policy!'),
                                backgroundColor: Color(0xFF660033),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF660033),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'I Understand',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Footer Note
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'By using BridalEase, you agree to our Privacy Policy. '
                    'We may update this policy periodically.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF660033),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}