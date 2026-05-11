import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
                        child: Column(
                          children: [
                            Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF660033),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'BridalEase - Wedding Dress Marketplace',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 20),

                      // Effective Date
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF660033).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF660033).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFF660033)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Effective Date: January 1, 2024\nThese terms govern your use of BridalEase app.',
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

                      // Important Note
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Please read these terms carefully before using our services. '
                                'By using BridalEase, you agree to be bound by these terms.',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Sections
                      _buildSection(
                        title: '1. Acceptance of Terms',
                        content: '''
By accessing or using BridalEase, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions. If you do not agree, you must immediately discontinue use of the app.''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '2. User Accounts',
                        content: '''
• You must be at least 18 years old to create an account
• Provide accurate and complete registration information
• Maintain the confidentiality of your login credentials
• Notify us immediately of any unauthorized account access
• You are responsible for all activities under your account''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '3. User Responsibilities',
                        content: '''
• Use the app only for lawful purposes
• Do not upload offensive, illegal, or copyrighted content
• Respect other users' privacy and rights
• Do not attempt to hack or disrupt the app
• Report any suspicious activities to us
• Provide truthful information in profiles and listings''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '4. Vendor Terms',
                        content: '''
• Vendors must provide accurate business information
• Quality of products/services must match descriptions
• Responsive communication with clients is required
• Pricing must be transparent with no hidden fees
• Cancellation policies must be clearly stated
• Maintain professional conduct at all times''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '5. Bride/Buyer Terms',
                        content: '''
• Provide accurate measurements for dress fittings
• Make timely payments for bookings
• Respect vendors' cancellation policies
• Provide honest reviews and feedback
• Do not misuse the booking system
• Communicate respectfully with vendors''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '6. Payments & Refunds',
                        content: '''
• All payments are processed securely via third-party providers
• Transaction fees may apply
• Refund policies vary by vendor
• Disputes must be reported within 7 days
• We are not liable for payment disputes between users
• Bookings may require deposits (non-refundable in some cases)''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '7. Content Ownership',
                        content: '''
• You retain ownership of your uploaded content
• By uploading, you grant BridalEase license to display content
• We may remove inappropriate content without notice
• Do not upload others' copyrighted material
• Reviews and ratings become our property for display''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '8. Dispute Resolution',
                        content: '''
• First attempt direct resolution between parties
• Contact our support team for mediation
• Formal complaints must be in writing
• We reserve right to suspend accounts during disputes
• Legal jurisdiction: [Your Country/State] courts''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '9. Limitation of Liability',
                        content: '''
• We are not liable for dress fitting issues
• Not responsible for vendor services quality
• No liability for app downtime or data loss
• Maximum liability limited to service fees paid
• We mediate but do not guarantee transaction outcomes''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '10. Termination',
                        content: '''
• We may terminate accounts for violations
• You may delete your account anytime
• Upon termination, your data may be retained as per privacy policy
• Outstanding payments remain due after termination
• Prohibited from creating new accounts after termination''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '11. Changes to Terms',
                        content: '''
• We may update these terms periodically
• Continued use after changes means acceptance
• Significant changes will be notified via email
• Review terms regularly for updates
• Old versions archived on our website''',
                      ),

                      const SizedBox(height: 25),

                      _buildSection(
                        title: '12. Contact Information',
                        content: '''
For questions about these Terms & Conditions:
Email: legal@bridalease.com
Phone: +1 (555) 987-6543
Address: Legal Department, BridalEase Inc.
123 Wedding Avenue, Suite 456
Fashion City, FC 10001

Response Time: 3-5 business days''',
                      ),

                      const SizedBox(height: 30),

                      // Accept & Decline Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You declined the Terms & Conditions'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text(
                                'Decline',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thank you for accepting our Terms & Conditions!'),
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
                                'I Agree',
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

                      const SizedBox(height: 20),

                      // Checkbox for Agreement (Optional for signup)
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: null,
                            activeColor: const Color(0xFF660033),
                          ),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms & Conditions and Privacy Policy',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Legal Disclaimer
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'These Terms & Conditions constitute a legal agreement between you and BridalEase. '
                    'For legal advice, please consult with an attorney.',
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
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF660033).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  title.split('.')[0],
                  style: const TextStyle(
                    color: Color(0xFF660033),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}