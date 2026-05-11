// lib/services/free_avatar_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class FreeAvatarService {
  // 🎯 FREE 3D Models Collection
  static final List<Map<String, dynamic>> avatarCollection = [
    {
      'id': 'avatar-1',
      'name': 'Modern Girl',
      'url': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/CesiumMan/glTF-Binary/CesiumMan.glb',
      'thumbnail': '👩',
      'style': 'realistic',
      'gender': 'female',
      'description': 'Casual modern outfit'
    },
    {
      'id': 'avatar-2',
      'name': 'Stylish Woman',
      'url': 'https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/RobotExpressive/RobotExpressive.glb',
      'thumbnail': '🤖',
      'style': 'stylish',
      'gender': 'female',
      'description': 'Expressive character'
    },
    {
      'id': 'avatar-3',
      'name': 'Elegant Lady',
      'url': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/DamagedHelmet/glTF-Binary/DamagedHelmet.glb',
      'thumbnail': '👸',
      'style': 'elegant',
      'gender': 'female',
      'description': 'Elegant appearance'
    },
    {
      'id': 'avatar-4',
      'name': 'Simple Girl',
      'url': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/SciFiHelmet/glTF-Binary/SciFiHelmet.glb',
      'thumbnail': '👧',
      'style': 'simple',
      'gender': 'female',
      'description': 'Simple and clean'
    },
    {
      'id': 'avatar-5',
      'name': 'Bridal Style',
      'url': 'https://raw.githubusercontent.com/twhitney/threejs-examples/main/public/models/gltf/SheenChair/SheenChair.glb',
      'thumbnail': '👰',
      'style': 'bridal',
      'gender': 'female',
      'description': 'Elegant bridal look'
    },
  ];

  // Sabhi avatars ki list return karo
  static List<Map<String, dynamic>> getAllAvatars() {
    return avatarCollection;
  }

  // ID se specific avatar dhoondo
  static Map<String, dynamic>? getAvatarById(String id) {
    try {
      return avatarCollection.firstWhere((avatar) => avatar['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Bride ke liye filtered avatars (female)
  static List<Map<String, dynamic>> getBrideAvatars() {
    return avatarCollection.where((a) => a['gender'] == 'female').toList();
  }

  // Avatar select karo aur database mein save karo
  static Future<Map<String, dynamic>> selectAvatar({
    required String userId,
    required String avatarId,
  }) async {
    try {
      final avatar = getAvatarById(avatarId);
      if (avatar == null) {
        return {
          'success': false,
          'message': 'Avatar not found',
        };
      }

      // Supabase mein save karo
      await Supabase.instance.client
          .from('user_avatars')
          .upsert({
            'user_id': userId,
            'avatar_url': avatar['url'],
            'avatar_name': avatar['name'],
            'avatar_id': avatar['id'],
            'selected_at': DateTime.now().toIso8601String(),
          });

      return {
        'success': true,
        'avatarUrl': avatar['url'],
        'avatarName': avatar['name'],
        'message': 'Avatar selected successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // User ka selected avatar lo
  static Future<String?> getUserAvatar(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_avatars')
          .select('avatar_url')
          .eq('user_id', userId)
          .order('selected_at', ascending: false)
          .maybeSingle();
      
      return response?['avatar_url'];
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}