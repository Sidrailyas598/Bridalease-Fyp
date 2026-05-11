import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final supabase = Supabase.instance.client;

  // Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String userType,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await supabase.from('notifications').insert({
        'user_id': userId,
        'user_type': userType,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Notification sent to $userType: $title');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // Get all notifications for a user
  Future<List<Map<String, dynamic>>> getAllNotifications(String userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Get unread notifications for a user
  Future<List<Map<String, dynamic>>> getUnreadNotifications(String userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return [];
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      
      return response.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }
}