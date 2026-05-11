import 'package:flutter/material.dart';
import 'package:bridalease_fyp/supabase.dart';
import 'package:bridalease_fyp/screens/privacy_policy_screen.dart';
import 'package:bridalease_fyp/screens/terms_conditions_screen.dart';
import 'package:bridalease_fyp/screens/data_usage_screen.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  bool _notificationsEnabled = true;
  bool _emailUpdates = true;
  bool _smsNotifications = false;
  bool _is2FAEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _notificationsEnabled = response['notifications_enabled'] ?? true;
          _emailUpdates = response['email_updates'] ?? true;
          _smsNotifications = response['sms_notifications'] ?? false;
          _is2FAEnabled = response['two_factor_enabled'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('user_settings').upsert({
        'user_id': user.id,
        'notifications_enabled': _notificationsEnabled,
        'email_updates': _emailUpdates,
        'sms_notifications': _smsNotifications,
        'two_factor_enabled': _is2FAEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> _changePassword() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password'),
        content: const Text('A password reset link will be sent to your email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await supabase.auth.resetPasswordForEmail(user.email!);
                _showSnackBar('Password reset email sent!', Colors.green);
              } catch (e) {
                _showSnackBar('Error: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
            ),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle2FA() async {
    setState(() {
      _is2FAEnabled = !_is2FAEnabled;
    });
    await _saveSettings();

    if (_is2FAEnabled) {
      _show2FADialog();
    } else {
      _showSnackBar('2FA disabled', Colors.orange);
    }
  }

  void _show2FADialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enable 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF660033)),
            const SizedBox(height: 16),
            const Text(
              'Two-Factor Authentication adds an extra layer of security to your account.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Demo Mode: 123456',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _is2FAEnabled = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('2FA enabled successfully!', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF660033),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you absolutely sure? This will permanently delete all your data including orders, favorites, and account information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Account'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showSnackBar(
                  'Please contact support to delete your account: support@bridalease.com',
                  Colors.red);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveAndShowSnackBar() async {
    await _saveSettings();
    _showSnackBar('Settings saved successfully!', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text(
          'Manage Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF660033),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF660033).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18,
                color: Color(0xFF660033)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Notification Settings Card
            _buildCard(
              title: 'Notification Settings',
              icon: Icons.notifications_active,
              children: [
                _buildSettingSwitch(
                  title: 'Push Notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _saveSettings();
                  },
                ),
                _buildSettingSwitch(
                  title: 'Email Updates',
                  value: _emailUpdates,
                  onChanged: (value) {
                    setState(() => _emailUpdates = value);
                    _saveSettings();
                  },
                ),
                _buildSettingSwitch(
                  title: 'SMS Notifications',
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() => _smsNotifications = value);
                    _saveSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Security Card
            _buildCard(
              title: 'Security',
              icon: Icons.security,
              children: [
                _buildSettingTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: _changePassword,
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  icon: Icons.qr_code_scanner,
                  title: 'Two-Factor Authentication',
                  subtitle: _is2FAEnabled ? 'Enabled' : 'Disabled',
                  onTap: _toggle2FA,
                  trailing: Switch(
                    value: _is2FAEnabled,
                    onChanged: (_) => _toggle2FA(),
                    activeColor: const Color(0xFF660033),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Privacy Card
            _buildCard(
              title: 'Privacy',
              icon: Icons.privacy_tip,
              children: [
                _buildSettingTile(
                  icon: Icons.visibility,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  icon: Icons.data_usage,
                  title: 'Data Usage',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataUsageScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Danger Zone Card
            _buildCard(
              title: 'Danger Zone',
              icon: Icons.warning_amber,
              iconColor: Colors.red,
              titleColor: Colors.red,
              backgroundColor: Colors.red.shade50,
              children: [
                _buildSettingTile(
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and all data',
                  onTap: _deleteAccount,
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Save All Button
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveAndShowSnackBar,
                icon: const Icon(Icons.save, size: 20),
                label: const Text(
                  'Save All Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF660033),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? iconColor,
    Color? titleColor,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? const Color(0xFF660033)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF660033),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor ?? const Color(0xFF660033),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF660033),
      activeTrackColor: const Color(0xFF660033).withOpacity(0.3),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF660033)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF660033),
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: titleColor ?? Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}