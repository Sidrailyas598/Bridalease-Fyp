// lib/screens/vendor_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bridalease_fyp/screens/chat_screen.dart';

final supabase = Supabase.instance.client;

class VendorChatListScreen extends StatefulWidget {
  const VendorChatListScreen({super.key});

  @override
  State<VendorChatListScreen> createState() => _VendorChatListScreenState();
}

class _VendorChatListScreenState extends State<VendorChatListScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    
    try {
      final vendor = supabase.auth.currentUser;
      if (vendor == null) return;

      // Get all unique brides who have messaged this vendor
      // This would need a messages table in Supabase
      // For now, we'll use dummy data
      
      // Get vendor's dresses to find interested brides
      final dresses = await supabase
          .from('dresses')
          .select('id, name')
          .eq('vendor_id', vendor.id);

      // Get unique brides from cart/wishlist/bookings
      final brideIds = await supabase
          .from('cart')
          .select('user_id, users(full_name)')
          .inFilter('dress_id', dresses.map((d) => d['id']).toList());

      // Group by bride
      final Map<String, Map<String, dynamic>> uniqueChats = {};
      
      for (var item in brideIds) {
        final brideId = item['user_id'];
        final brideName = item['users']['full_name'] ?? 'Bride';
        
        if (!uniqueChats.containsKey(brideId)) {
          uniqueChats[brideId] = {
            'bride_id': brideId,
            'bride_name': brideName,
            'last_message': 'Tap to start chat',
            'last_time': DateTime.now(),
            'unread': 0,
          };
        }
      }

      setState(() {
        _chats = uniqueChats.values.toList();
        _loading = false;
      });

    } catch (e) {
      print('Error loading chats: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats with Brides'),
        backgroundColor: const Color(0xFF660033),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF660033),
                          child: Text(
                            chat['bride_name'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(chat['bride_name']),
                        subtitle: Text(chat['last_message']),
                        trailing: chat['unread'] > 0
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF660033),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${chat['unread']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : Text(
                                _formatTime(chat['last_time']),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentUserId: supabase.auth.currentUser!.id,
                                otherUserId: chat['bride_id'],
                                otherUserName: chat['bride_name'],
                              ),
                            ),
                          );
                        },
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
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When brides contact you, they will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}