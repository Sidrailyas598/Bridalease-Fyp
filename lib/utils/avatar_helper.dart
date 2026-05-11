// lib/utils/avatar_helper.dart
import 'package:flutter/material.dart';

class AvatarHelper {
  // 📁 Complete Avatar Mapping - ALL 36 COMBINATIONS
  static const Map<String, String> _avatarMap = {
    // ===== SLIM SERIES =====
    // Slim Short
    'slim_short_fair': 'assets/avatars/slim_short_fair_fullbody.png',
    'slim_short_wheatish': 'assets/avatars/slim_short_wheatish_fullbody.png',
    'slim_short_dark': 'assets/avatars/slim_short_dark_fullbody.png',
    
    // Slim Medium
    'slim_medium_fair': 'assets/avatars/slim_medium_fair_fullbody.png',
    'slim_medium_wheatish': 'assets/avatars/slim_medium_wheatish_fullbody.png',
    'slim_medium_dark': 'assets/avatars/slim_medium_dark_fullbody.png',
    
    // Slim Tall
    'slim_tall_fair': 'assets/avatars/slim_tall_fair_fullbody.png',
    'slim_tall_wheatish': 'assets/avatars/slim_tall_wheatish_fullbody.png',
    'slim_tall_dark': 'assets/avatars/slim_tall_dark_fullbody.png',

    // ===== AVERAGE SERIES =====
    // Average Short
    'average_short_fair': 'assets/avatars/average_short_fair_fullbody.png',
    'average_short_wheatish': 'assets/avatars/average_short_wheatish_fullbody.png',
    'average_short_dark': 'assets/avatars/average_short_dark_fullbody.png',
    
    // Average Medium
    'average_medium_fair': 'assets/avatars/average_medium_fair_fullbody.png',
    'average_medium_wheatish': 'assets/avatars/average_medium_wheatish_fullbody.png',
    'average_medium_dark': 'assets/avatars/average_medium_dark_fullbody.png',
    
    // Average Tall
    'average_tall_fair': 'assets/avatars/average_tall_fair_fullbody.png',
    'average_tall_wheatish': 'assets/avatars/average_tall_wheatish_fullbody.png',
    'average_tall_dark': 'assets/avatars/average_tall_dark_fullbody.png',

    // ===== CURVY SERIES =====
    // Curvy Short
    'curvy_short_fair': 'assets/avatars/curvy_short_fair_fullbody.png',
    'curvy_short_wheatish': 'assets/avatars/curvy_short_wheatish_fullbody.png',
    'curvy_short_dark': 'assets/avatars/curvy_short_dark_fullbody.png',
    
    // Curvy Medium
    'curvy_medium_fair': 'assets/avatars/curvy_medium_fair_fullbody.png',
    'curvy_medium_wheatish': 'assets/avatars/curvy_medium_wheatish_fullbody.png',
    'curvy_medium_dark': 'assets/avatars/curvy_medium_dark_fullbody.png',
    
    // Curvy Tall
    'curvy_tall_fair': 'assets/avatars/curvy_tall_fair_fullbody.png',
    'curvy_tall_wheatish': 'assets/avatars/curvy_tall_wheatish_fullbody.png',
    'curvy_tall_dark': 'assets/avatars/curvy_tall_dark_fullbody.png',

    // ===== PLUS SERIES =====
    // Plus Short
    'plus_short_fair': 'assets/avatars/plus_short_fair_fullbody.png',
    'plus_short_wheatish': 'assets/avatars/plus_short_wheatish_fullbody.png',
    'plus_short_dark': 'assets/avatars/plus_short_dark_fullbody.png',
    
    // Plus Medium
    'plus_medium_fair': 'assets/avatars/plus_medium_fair_fullbody.png',
    'plus_medium_wheatish': 'assets/avatars/plus_medium_wheatish_fullbody.png',
    'plus_medium_dark': 'assets/avatars/plus_medium_dark_fullbody.png',
    
    // Plus Tall
    'plus_tall_fair': 'assets/avatars/plus_tall_fair_fullbody.png',
    'plus_tall_wheatish': 'assets/avatars/plus_tall_wheatish_fullbody.png',
    'plus_tall_dark': 'assets/avatars/plus_tall_dark_fullbody.png',
  };

  // 📊 BMI Calculate
  static double _calculateBMI(double height, double weight) {
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // 📏 Height Category
  static String _getHeightCategory(double height) {
    if (height < 155) return 'short';
    if (height < 165) return 'medium';
    return 'tall';
  }

  // 👤 Body Type from BMI
  static String _getBodyType(double bmi) {
    if (bmi < 18.5) return 'slim';
    if (bmi < 25) return 'average';
    if (bmi < 30) return 'curvy';
    return 'plus';
  }

  // 🎯 MAIN FUNCTION - Get Avatar Path
  static String getAvatarPath({
    double? height,
    double? weight,
    String? skinTone,
    Map<String, dynamic>? measurements,
  }) {
    // Handle measurements parameter if provided
    if (measurements != null) {
      height = measurements['height_cm']?.toDouble() ?? height ?? 160;
      weight = measurements['weight_kg']?.toDouble() ?? weight ?? 60;
      skinTone = skinTone ?? 'wheatish';
    }
    
    // Default values
    height = height ?? 160;
    weight = weight ?? 60;
    skinTone = skinTone?.toLowerCase() ?? 'wheatish';
    
    // Debug prints
    debugPrint('🎯 AvatarHelper Input - Height: $height, Weight: $weight, Skin: $skinTone');
    
    // BMI calculate
    double bmi = _calculateBMI(height, weight);
    debugPrint('📊 BMI: ${bmi.toStringAsFixed(1)}');
    
    // Body type from BMI
    String bodyType = _getBodyType(bmi);
    debugPrint('👤 Body Type: $bodyType');
    
    // Height category
    String heightCategory = _getHeightCategory(height);
    debugPrint('📏 Height Category: $heightCategory');
    
    // Skin tone normalize
    String normalizedSkinTone = skinTone.toLowerCase().trim();
    if (!['fair', 'wheatish', 'dark'].contains(normalizedSkinTone)) {
      debugPrint('⚠️ Invalid skin tone: $normalizedSkinTone, using wheatish');
      normalizedSkinTone = 'wheatish';
    }
    
    // Avatar key
    String avatarKey = '${bodyType}_${heightCategory}_$normalizedSkinTone';
    debugPrint('🔑 Avatar Key: $avatarKey');
    
    // Get path from map
    String? avatarPath = _avatarMap[avatarKey];
    
    if (avatarPath == null) {
      debugPrint('⚠️ Avatar not found for $avatarKey, using fallback');
      // Try alternative - maybe medium height as fallback
      String fallbackKey = '${bodyType}_medium_$normalizedSkinTone';
      avatarPath = _avatarMap[fallbackKey];
      
      if (avatarPath == null) {
        // Ultimate fallback
        avatarPath = 'assets/avatars/average_medium_wheatish_fullbody.png';
        debugPrint('🆘 Ultimate fallback used');
      } else {
        debugPrint('✅ Fallback found: $fallbackKey');
      }
    }
    
    debugPrint('🖼️ Final Avatar Path: $avatarPath');
    return avatarPath;
  }

  // ✅ NEW: Get avatar path from categories (used by ProfileSetupScreen)
  static String getAvatarPathFromCategories({
    required String heightCategory, // 'short', 'medium', 'tall'
    required String bodyType,       // 'slim', 'average', 'curvy', 'plus'
    required String skinTone,       // 'fair', 'wheatish', 'dark'
  }) {
    debugPrint('🎯 Categories Input - Height: $heightCategory, Body: $bodyType, Skin: $skinTone');
    
    // Validate height category
    if (!['short', 'medium', 'tall'].contains(heightCategory)) {
      debugPrint('⚠️ Invalid height category: $heightCategory, using medium');
      heightCategory = 'medium';
    }
    
    // Validate body type
    if (!['slim', 'average', 'curvy', 'plus'].contains(bodyType)) {
      debugPrint('⚠️ Invalid body type: $bodyType, using average');
      bodyType = 'average';
    }
    
    // Validate skin tone
    String normalizedSkinTone = skinTone.toLowerCase().trim();
    if (!['fair', 'wheatish', 'dark'].contains(normalizedSkinTone)) {
      debugPrint('⚠️ Invalid skin tone: $normalizedSkinTone, using wheatish');
      normalizedSkinTone = 'wheatish';
    }
    
    // Avatar key
    String avatarKey = '${bodyType}_${heightCategory}_$normalizedSkinTone';
    debugPrint('🔑 Avatar Key: $avatarKey');
    
    // Get path from map
    String? avatarPath = _avatarMap[avatarKey];
    
    if (avatarPath == null) {
      debugPrint('⚠️ Avatar not found for $avatarKey, using fallback');
      // Try medium height fallback
      String fallbackKey = '${bodyType}_medium_$normalizedSkinTone';
      avatarPath = _avatarMap[fallbackKey];
      
      if (avatarPath == null) {
        // Ultimate fallback
        avatarPath = 'assets/avatars/average_medium_wheatish_fullbody.png';
        debugPrint('🆘 Ultimate fallback used');
      }
    }
    
    debugPrint('🖼️ Final Avatar Path: $avatarPath');
    return avatarPath;
  }

  // ✅ Body type display name
  static String getBodyTypeDisplayName(String bodyType) {
    switch (bodyType.toLowerCase()) {
      case 'slim': return 'Slim';
      case 'average': return 'Average';
      case 'curvy': return 'Curvy';
      case 'plus': return 'Plus Size';
      default: return 'Average';
    }
  }

  // ✅ Skin tone color
  static Color getSkinToneColor(String skinTone) {
    switch (skinTone.toLowerCase()) {
      case 'fair': return const Color(0xFFFFE0BD);
      case 'wheatish': return const Color(0xFFDEB887);
      case 'dark': return const Color(0xFF5D3A1A);
      default: return const Color(0xFFDEB887);
    }
  }

  // ✅ Height display name
  static String getHeightDisplayName(String heightCategory) {
    switch (heightCategory.toLowerCase()) {
      case 'short': return 'Short (below 155 cm)';
      case 'medium': return 'Medium (155-165 cm)';
      case 'tall': return 'Tall (above 165 cm)';
      default: return 'Medium';
    }
  }

  // ✅ Get icon for body type
  static IconData getBodyTypeIcon(String bodyType) {
    switch (bodyType.toLowerCase()) {
      case 'slim': return Icons.flare_rounded;
      case 'average': return Icons.auto_awesome_rounded;
      case 'curvy': return Icons.waves_rounded;
      case 'plus': return Icons.circle_rounded;
      default: return Icons.accessibility;
    }
  }

  // ✅ Get gradient colors for body type
  static List<Color> getBodyTypeGradient(String bodyType) {
    switch (bodyType.toLowerCase()) {
      case 'slim': return [Colors.lightBlue.shade300, Colors.blue.shade600];
      case 'average': return [Colors.teal.shade300, Colors.teal.shade600];
      case 'curvy': return [Colors.orange.shade300, Colors.deepOrange.shade600];
      case 'plus': return [Colors.pink.shade300, Colors.pink.shade600];
      default: return [Colors.grey.shade300, Colors.grey.shade600];
    }
  }

  // ✅ Get gradient colors for height
  static List<Color> getHeightGradient(String heightCategory) {
    switch (heightCategory.toLowerCase()) {
      case 'short': return [Colors.blue.shade300, Colors.blue.shade600];
      case 'medium': return [Colors.green.shade300, Colors.green.shade600];
      case 'tall': return [Colors.purple.shade300, Colors.purple.shade600];
      default: return [Colors.grey.shade300, Colors.grey.shade600];
    }
  }

  // ✅ Get icon for height
  static IconData getHeightIcon(String heightCategory) {
    switch (heightCategory.toLowerCase()) {
      case 'short': return Icons.arrow_circle_down_rounded;
      case 'medium': return Icons.height_rounded;
      case 'tall': return Icons.arrow_circle_up_rounded;
      default: return Icons.height_rounded;
    }
  }

  // ✅ Check if all avatars exist (for debugging)
  static void checkAllAvatars() {
    List<String> bodyTypes = ['slim', 'average', 'curvy', 'plus'];
    List<String> heights = ['short', 'medium', 'tall'];
    List<String> skinTones = ['fair', 'wheatish', 'dark'];
    
    debugPrint('📋 CHECKING ALL AVATARS (36 combinations):');
    debugPrint('=' * 50);
    
    int found = 0;
    int missing = 0;
    
    for (var bodyType in bodyTypes) {
      for (var height in heights) {
        for (var skin in skinTones) {
          String avatarKey = '${bodyType}_${height}_$skin';
          String? path = _avatarMap[avatarKey];
          
          if (path == null) {
            debugPrint('❌ MISSING: $avatarKey');
            missing++;
          } else {
            debugPrint('✅ FOUND: $avatarKey → $path');
            found++;
          }
        }
      }
    }
    
    debugPrint('=' * 50);
    debugPrint('📊 SUMMARY: Found: $found, Missing: $missing, Total: ${found + missing}');
  }
}