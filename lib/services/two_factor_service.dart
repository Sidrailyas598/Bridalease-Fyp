// lib/services/two_factor_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class TwoFactorService {
  final supabase = Supabase.instance.client;

  // 1. Generate QR Code for Google Authenticator
  Future<String?> generateQRCode(String userId, String email) async {
    try {
      // Call your backend API to generate TOTP secret
      final response = await supabase.functions.invoke(
        'generate-2fa-secret',
        body: {'user_id': userId, 'email': email},
      );
      
      return response.data['qr_code_url'];
    } catch (e) {
      print('Error generating QR: $e');
      return null;
    }
  }

  // 2. Verify OTP code
  Future<bool> verifyOTP(String userId, String otpCode) async {
    try {
      final response = await supabase.functions.invoke(
        'verify-2fa-otp',
        body: {'user_id': userId, 'otp_code': otpCode},
      );
      
      return response.data['verified'] ?? false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // 3. Enable 2FA for user
  Future<bool> enable2FA(String userId, String otpCode) async {
    try {
      final response = await supabase.functions.invoke(
        'enable-2fa',
        body: {'user_id': userId, 'otp_code': otpCode},
      );
      
      if (response.data['success'] == true) {
        // Save to user_settings
        await supabase.from('user_settings').upsert({
          'user_id': userId,
          'two_factor_enabled': true,
          'two_factor_secret': response.data['secret'],
          'updated_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error enabling 2FA: $e');
      return false;
    }
  }

  // 4. Disable 2FA
  Future<bool> disable2FA(String userId) async {
    try {
      await supabase.from('user_settings').update({
        'two_factor_enabled': false,
        'two_factor_secret': null,
      }).eq('user_id', userId);
      
      return true;
    } catch (e) {
      print('Error disabling 2FA: $e');
      return false;
    }
  }
}