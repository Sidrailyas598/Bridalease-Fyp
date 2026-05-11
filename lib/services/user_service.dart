import 'package:bridalease_fyp/supabase.dart';

class UserService {
  
  // Current user ki complete profile fetch karo
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Sirf body measurements fetch karo
  static Map<String, dynamic> extractBodyMeasurements(Map<String, dynamic>? userData) {
    if (userData == null) return {};

    final measurements = userData['body_measurements'] ?? {};
    return {
      'height_cm': measurements['height_cm'],
      'weight_kg': measurements['weight_kg'],
      'chest_cm': measurements['chest_cm'],
      'waist_cm': measurements['waist_cm'],
      'hips_cm': measurements['hips_cm'],
      'shoulder_cm': measurements['shoulder_width_cm'],
      'inseam_cm': measurements['inseam_cm'],
      'body_type': measurements['body_type'] ?? userData['body_type'], // fallback
      'skin_tone': userData['skin_tone'],
    };
  }

  // Measurements ko AI avatar categories mein map karo
  static Map<String, String> mapMeasurementsToAvatarParams(Map<String, dynamic> measurements) {
    
    // Waist se body type (agar body_type na diya ho to)
    String getBodyTypeFromWaist(double? waist) {
      if (waist == null) return 'average';
      if (waist < 70) return 'slim';        // < 70 cm
      if (waist < 85) return 'average';     // 70-85 cm
      if (waist < 100) return 'curvy';      // 85-100 cm
      return 'plus';                         // > 100 cm
    }

    // Height se height category
    String getHeightCategory(double? heightCm) {
      if (heightCm == null) return 'medium';
      if (heightCm < 155) return 'short';    // < 5'1"
      if (heightCm < 170) return 'medium';   // 5'1" - 5'7"
      return 'tall';                           // > 5'7"
    }

    // Skin tone map
    String mapSkinTone(String? skinTone) {
      switch(skinTone?.toLowerCase()) {
        case 'light': return 'fair';
        case 'medium': return 'wheatish';
        case 'tan': return 'wheatish';
        case 'brown': return 'dark';
        case 'dark': return 'dark';
        default: return 'wheatish';
      }
    }

    final waist = measurements['waist_cm'] != null 
        ? double.tryParse(measurements['waist_cm'].toString()) 
        : null;
    
    final height = measurements['height_cm'] != null 
        ? double.tryParse(measurements['height_cm'].toString()) 
        : null;

    // Pehle user ke selected body_type ko priority do, nahi to waist se calculate karo
    String bodyType = measurements['body_type'] ?? getBodyTypeFromWaist(waist);
    
    return {
      'bodyType': bodyType,
      'heightType': getHeightCategory(height),
      'skinTone': mapSkinTone(measurements['skin_tone']),
    };
  }
}