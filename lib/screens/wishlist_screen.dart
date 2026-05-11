import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/dress_detail_screen.dart';

final supabase = Supabase.instance.client;

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _bookmarkedDresses = [];
  bool _loading = true;
  final String baseUrl = 'https://bvdbjhsjssukynvalycx.supabase.co/storage/v1/object/public/dresses/';

  @override
  void initState() {
    super.initState();
    _loadBookmarkedDresses();
  }

  Future<void> _loadBookmarkedDresses() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final response = await supabase
          .from('wishlist')
          .select('dresses(*)')
          .eq('user_id', user.id);
      
      List<Map<String, dynamic>> dresses = [];
      for (var item in response) {
        if (item['dresses'] != null) {
          dresses.add(Map<String, dynamic>.from(item['dresses']));
        }
      }
      
      setState(() {
        _bookmarkedDresses = dresses;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading bookmarked dresses: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFromBookmarks(String dressId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('wishlist')
          .delete()
          .eq('user_id', user.id)
          .eq('dress_id', dressId);

      setState(() {
        _bookmarkedDresses.removeWhere((dress) => dress['id'] == dressId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from bookmarks'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
    }
  }

  Future<void> _clearAllBookmarks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('wishlist')
          .delete()
          .eq('user_id', user.id);

      setState(() {
        _bookmarkedDresses.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All bookmarks cleared'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('Error clearing bookmarks: $e');
    }
  }

  String _formatImageUrl(dynamic imagePath) {
    String path = imagePath.toString();
    if (path.startsWith('http')) return path;
    return '$baseUrl${path.replaceAll(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: const Color(0xFF660033),
        actions: [
          if (_bookmarkedDresses.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllBookmarks,
              tooltip: 'Clear All',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookmarkedDresses,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedDresses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'No bookmarked dresses yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        'Bookmark dresses to see them here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarkedDresses.length,
                  itemBuilder: (context, index) {
                    final dress = _bookmarkedDresses[index];
                    final images = List.from(dress['images'] ?? []);
                    final imageUrl = images.isNotEmpty ? _formatImageUrl(images[0]) : '';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.desk_outlined),
                                  ),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.desk_outlined, size: 30),
                              ),
                        title: Text(
                          dress['name'] ?? 'Unnamed Dress',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${dress['price']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF660033),
                              ),
                            ),
                            if (dress['event_type'] != null)
                              Text(
                                dress['event_type'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFromBookmarks(dress['id']),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DressDetailScreen(
                                dress: dress,
                                role: 'bride',
                                allDresses: _bookmarkedDresses,
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
}