import 'package:bridalease_fyp/screens/upload_dress_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class VendorDressManagementScreen extends StatefulWidget {
  const VendorDressManagementScreen({super.key});

  @override
  _VendorDressManagementScreenState createState() => _VendorDressManagementScreenState();
}

class _VendorDressManagementScreenState extends State<VendorDressManagementScreen> 
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _dresses = [];
  bool _loading = true;
  bool _isRefreshing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadVendorDresses();
  }

  // Helper function to safely get images list
  List<String> _getImages(dynamic images) {
    if (images == null) return [];
    if (images is List) {
      return images.whereType<String>().toList();
    }
    return [];
  }

  Future<void> _loadVendorDresses() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('dresses')
          .select()
          .eq('vendor_id', user.id)
          .order('created_at', ascending: false);

      print('Loaded ${response.length} dresses');

      if (mounted) {
        setState(() {
          _dresses = List<Map<String, dynamic>>.from(response);
          _loading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error loading dresses: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshDresses() async {
    setState(() => _isRefreshing = true);
    await _loadVendorDresses();
  }

  Future<void> _deleteDress(String dressId, String dressName) async {
    try {
      await supabase.from('dresses').delete().eq('id', dressId);
      
      setState(() {
        _dresses.removeWhere((dress) => dress['id'] == dressId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$dressName deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting dress: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String dressId, String dressName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Dress'),
        content: Text('Are you sure you want to delete "$dressName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDress(dressId, dressName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDress(Map<String, dynamic> dress) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadDressScreen(
          dressToEdit: dress,
          isEditMode: true,
        ),
      ),
    );

    if (result == true) {
      _refreshDresses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dress updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status, bool isApproved) {
    Color color;
    String text;
    
    if (isApproved) {
      color = Colors.green;
      text = 'Approved';
    } else if (status == 'pending') {
      color = Colors.orange;
      text = 'Pending';
    } else {
      color = Colors.grey;
      text = 'Draft';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      body: Stack(
        children: [
          // Background Image with gradient overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/welcome_bg2.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.3),
                  BlendMode.lighten,
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFF5F8).withOpacity(0.9),
                  Colors.white.withOpacity(0.95),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Dress List
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF660033),
                          ),
                        )
                      : _dresses.isEmpty
                          ? Center(
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
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 60,
                                      color: const Color(0xFF660033).withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'No Dresses Yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF660033),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap + button to add your first dress',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshDresses,
                              color: const Color(0xFF660033),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _dresses.length,
                                itemBuilder: (context, index) {
                                  final dress = _dresses[index];
                                  // 👇 FIXED: Safe image handling
                                  final images = _getImages(dress['images']);
                                  
                                  return FadeTransition(
                                    opacity: _animationController,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Dress Image
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                width: 100,
                                                height: 120,
                                                color: Colors.grey[100],
                                                child: images.isNotEmpty
                                                    ? Image.network(
                                                        images.first,
                                                        fit: BoxFit.cover,
                                                        width: 100,
                                                        height: 120,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            color: Colors.grey[200],
                                                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                          );
                                                        },
                                                      )
                                                    : const Center(
                                                        child: Icon(
                                                          Icons.image,
                                                          color: Colors.grey,
                                                          size: 40,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            
                                            // Dress Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Name and Status
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          dress['name'] ?? 'Unnamed Dress',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF333333),
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      _buildStatusBadge(
                                                        dress['status'] ?? 'draft',
                                                        dress['is_approved'] ?? false,
                                                      ),
                                                    ],
                                                  ),
                                                  
                                                  const SizedBox(height: 8),
                                                  
                                                  // Price
                                                  Text(
                                                    'Rs ${(dress['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF660033),
                                                    ),
                                                  ),
                                                  
                                                  // Rental Price
                                                  if (dress['rental_price'] != null && dress['rental_price'] > 0)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2),
                                                      child: Text(
                                                        'Rent: Rs ${(dress['rental_price'] as num).toStringAsFixed(0)}/day',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ),
                                                  
                                                  const SizedBox(height: 12),
                                                  
                                                  // Action Buttons - Icon only
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      // Edit Button
                                                      Container(
                                                        margin: const EdgeInsets.only(right: 8),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF660033).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: IconButton(
                                                          onPressed: () => _editDress(dress),
                                                          icon: const Icon(
                                                            Icons.edit_outlined,
                                                            color: Color(0xFF660033),
                                                            size: 20,
                                                          ),
                                                          constraints: const BoxConstraints(
                                                            minWidth: 40,
                                                            minHeight: 40,
                                                          ),
                                                          padding: EdgeInsets.zero,
                                                        ),
                                                      ),
                                                      
                                                      // Delete Button
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: IconButton(
                                                          onPressed: () => _showDeleteConfirmation(
                                                            dress['id'],
                                                            dress['name'] ?? 'this dress',
                                                          ),
                                                          icon: const Icon(
                                                            Icons.delete_outline,
                                                            color: Colors.red,
                                                            size: 20,
                                                          ),
                                                          constraints: const BoxConstraints(
                                                            minWidth: 40,
                                                            minHeight: 40,
                                                          ),
                                                          padding: EdgeInsets.zero,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UploadDressScreen(
                dressToEdit: null,
                isEditMode: false,
              ),
            ),
          );
          if (result == true) {
            _refreshDresses();
          }
        },
        backgroundColor: const Color(0xFF660033),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}