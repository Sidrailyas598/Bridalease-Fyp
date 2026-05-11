import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class RentalReminderService {
  static final supabase = Supabase.instance.client;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notification channel
  static Future<void> initNotifications() async {
    try {
      print('🔔 Initializing notifications (disabled for now)...');
      // Temporarily disabled to fix build issues
      return;
      
      /* Original code - temporarily disabled
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );
      
      await _notifications.initialize(settings);
      
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
      
      await _createNotificationChannel();
      
      print('✅ Notifications initialized successfully');
      */
    } catch (e) {
      print('❌ Notification init error: $e');
    }
  }

  // Create notification channel (Android 8.0+)
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rental_reminders',
      'Rental Reminders',
      description: 'Reminders for rental dress returns',
      importance: Importance.high,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      print('✅ Notification channel created');
    }
  }

  // Show notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      print('🔔 Notification (disabled): $title');
      return;
      
      /* Original code - temporarily disabled
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rental_reminders',
        'Rental Reminders',
        channelDescription: 'Reminders for rental dress returns',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
      print('✅ Notification shown: $title');
      */
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  // Check for expiring rentals and send reminders
  static Future<void> checkAndSendReminders() async {
    try {
      print('🔍 Checking rental reminders (disabled for now)...');
      return;
      
      /* Original code - temporarily disabled
      print('🔍 Checking rental reminders...');
      
      final today = DateTime.now();
      
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in');
        return;
      }
      
      print('👤 Checking reminders for user: ${user.email}');
      
      final response = await supabase
          .from('orders')
          .select('*')
          .eq('user_id', user.id)
          .eq('order_type', 'rent')
          .eq('status', 'delivered')
          .eq('return_status', 'pending')
          .eq('reminder_sent', false);
      
      print('📦 Found ${response.length} rental orders to check');
      
      for (var order in response) {
        final endDateStr = order['rental_end_date'];
        if (endDateStr == null) continue;
        
        final endDate = DateTime.parse(endDateStr);
        final daysLeft = endDate.difference(today).inDays;
        
        if (daysLeft <= 2 && daysLeft >= 0) {
          await _sendReminderNotification(order, daysLeft);
          
          await supabase
              .from('orders')
              .update({'reminder_sent': true})
              .eq('id', order['id']);
              
          print('✅ Reminder sent for order: ${order['id'].substring(0, 8)}');
        }
        
        if (daysLeft < 0) {
          final isOverdueSent = order['overdue_reminder_sent'] ?? false;
          if (!isOverdueSent) {
            await _sendOverdueNotification(order, -daysLeft);
            
            await supabase
                .from('orders')
                .update({'overdue_reminder_sent': true})
                .eq('id', order['id']);
                
            print('⚠️ Overdue reminder sent for order: ${order['id'].substring(0, 8)}');
          }
        }
      }
      
      print('✅ Reminder check completed');
      */
    } catch (e) {
      print('❌ Error checking reminders: $e');
    }
  }
  
  static Future<void> _sendReminderNotification(
      Map<String, dynamic> order, int daysLeft) async {
    final orderId = order['id'].substring(0, 8).toUpperCase();
    final endDate = DateFormat('dd MMM yyyy').format(
        DateTime.parse(order['rental_end_date']));
    
    String title;
    String body;
    
    if (daysLeft == 0) {
      title = '⏰ Last Day to Return!';
      body = 'Order #$orderId - Your rental period ends TODAY ($endDate). Please return the dress.';
    } else if (daysLeft == 1) {
      title = '⏰ 1 Day Left to Return';
      body = 'Order #$orderId - Your rental period ends tomorrow ($endDate). Please prepare for return.';
    } else {
      title = '⏰ Rental Return Reminder';
      body = 'Order #$orderId - Your rental period ends in $daysLeft days ($endDate). Please initiate return.';
    }
    
    await showNotification(
      id: order['id'].hashCode,
      title: title,
      body: body,
      payload: 'order_${order['id']}',
    );
  }
  
  static Future<void> _sendOverdueNotification(
      Map<String, dynamic> order, int daysOverdue) async {
    final orderId = order['id'].substring(0, 8).toUpperCase();
    
    await showNotification(
      id: order['id'].hashCode,
      title: '⚠️ Rental Return Overdue',
      body: 'Order #$orderId - Your rental is overdue by $daysOverdue days. Please return immediately.',
      payload: 'order_${order['id']}',
    );
  }
  
  // Test method
  static Future<void> sendTestNotification() async {
    print('🧪 Test notification disabled');
  }
}