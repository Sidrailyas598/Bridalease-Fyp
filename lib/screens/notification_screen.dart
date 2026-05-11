import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final User user;

  const NotificationScreen({super.key, required this.user});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final notifications = await _notificationService.getAllNotifications(widget.user.id);
    setState(() {
      _notifications = notifications;
      _loading = false;
    });
  }

  Future<void> _markAsRead(String id) async {
    await _notificationService.markAsRead(id);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead(widget.user.id);
    _loadNotifications();
  }

  Future<void> _deleteNotification(String id) async {
    await _notificationService.deleteNotification(id);
    _loadNotifications();
  }

  Future<void> _deleteAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _notificationService.deleteAllNotifications(widget.user.id);
      _loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications deleted'), backgroundColor: Colors.green),
      );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'order_confirmed':
        return Icons.check_circle_outline;
      case 'order_delivered':
        return Icons.delivery_dining;
      case 'return_requested':
        return Icons.assignment_return;
      case 'return_approved':
        return Icons.check_circle;
      case 'return_rejected':
        return Icons.cancel;
      case 'return_completed':
        return Icons.check_circle;
      case 'rental_started':
        return Icons.calendar_today;
      case 'rental_reminder':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    if (type.contains('confirm') || type.contains('approved') || type.contains('completed')) {
      return Colors.green;
    } else if (type.contains('rejected') || type.contains('cancelled')) {
      return Colors.red;
    } else if (type.contains('delivered')) {
      return Colors.blue;
    } else if (type.contains('return')) {
      return Colors.orange;
    } else if (type.contains('rental')) {
      return Colors.purple;
    }
    return const Color(0xFF660033);
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF660033),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'delete_all') {
                  _deleteAllNotifications();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 18),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete all', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF660033)))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isUnread = notification['is_read'] == false;
                    
                    return Dismissible(
                      key: Key(notification['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white, size: 24),
                      ),
                      onDismissed: (direction) => _deleteNotification(notification['id']),
                      child: GestureDetector(
                        onTap: () => _markAsRead(notification['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? const Color(0xFF660033).withOpacity(0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: isUnread
                                ? Border.all(color: const Color(0xFF660033).withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getColorForType(notification['type']).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconForType(notification['type']),
                                  color: _getColorForType(notification['type']),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'],
                                      style: TextStyle(
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['message'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(notification['created_at']),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF660033),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF660033).withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none,
              size: 60,
              color: const Color(0xFF660033).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF660033),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}