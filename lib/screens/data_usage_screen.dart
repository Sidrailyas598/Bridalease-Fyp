// lib/screens/data_usage_screen.dart
import 'package:flutter/material.dart';

class DataUsageScreen extends StatelessWidget {
  const DataUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text(
          'Data Usage & Privacy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF660033),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF660033).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF660033)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Data Collection Card
            _buildInfoCard(
              title: 'Data We Collect',
              icon: Icons.data_usage,
              color: Colors.blue,
              items: [
                '📝 Personal Information: Name, Email, Phone Number',
                '👗 Dress Preferences: Styles, Sizes, Colors',
                '📊 Usage Data: App interactions, Time spent',
                '📍 Location Data: For delivery address (optional)',
                '🖼️ Photos: Avatar images for virtual try-on',
              ],
            ),
            const SizedBox(height: 16),

            // How We Use Data Card
            _buildInfoCard(
              title: 'How We Use Your Data',
              icon: Icons.analytics,
              color: Colors.green,
              items: [
                '🎯 Personalize dress recommendations',
                '📦 Process your orders and deliveries',
                '📧 Send order updates and promotions',
                '🔧 Improve app performance and features',
                '🛡️ Prevent fraud and ensure security',
              ],
            ),
            const SizedBox(height: 16),

            // Data Sharing Card
            _buildInfoCard(
              title: 'Data Sharing',
              icon: Icons.share,
              color: Colors.orange,
              items: [
                '👗 Vendors: Share order details for processing',
                '🚚 Delivery Partners: Share address for delivery',
                '💳 Payment Processors: Share payment information',
                '❌ We NEVER sell your personal data to third parties',
              ],
            ),
            const SizedBox(height: 16),

            // Data Security Card
            _buildInfoCard(
              title: 'Data Security',
              icon: Icons.security,
              color: Colors.purple,
              items: [
                '🔒 End-to-end encryption for sensitive data',
                '🛡️ Secure servers with regular backups',
                '✅ GDPR and privacy law compliant',
                '🔐 Two-factor authentication available',
              ],
            ),
            const SizedBox(height: 16),

            // Your Rights Card
            _buildInfoCard(
              title: 'Your Rights',
              icon: Icons.gavel,
              color: Colors.teal,
              items: [
                '👁️ Access your personal data anytime',
                '✏️ Update or correct your information',
                '🗑️ Request account deletion',
                '📥 Download your data export',
                '🚫 Opt-out of marketing communications',
              ],
            ),
            const SizedBox(height: 16),

            // Contact Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF660033), Color(0xFF883366)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF660033).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.contact_support, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Questions About Your Data?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our data protection team is here to help',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showContactDialog(context);
                          },
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text('Email Us'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showContactDialog(context);
                          },
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Call Us'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // Last Updated
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Last Updated: ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent, size: 50, color: Color(0xFF660033)),
            const SizedBox(height: 16),
            const Text(
              'For data privacy concerns, contact our support team:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    '📧 privacy@bridalease.com',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📞 +92 312 5178619',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening email app...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
            ),
            child: const Text('Email Now'),
          ),
        ],
      ),
    );
  }
}