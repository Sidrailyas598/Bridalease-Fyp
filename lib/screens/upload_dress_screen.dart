import 'dart:io';
import 'dart:typed_data';
import 'package:bridalease_fyp/screens/vendor_dress_management_screen.dart';
import 'package:bridalease_fyp/screens/vendor_orders_screen.dart' hide supabase;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:bridalease_fyp/supabase.dart' hide supabase;

class UploadDressScreen extends StatefulWidget {
  final Map<String, dynamic>? dressToEdit;
  final bool isEditMode;

  const UploadDressScreen({
    super.key, 
    this.dressToEdit,
    this.isEditMode = false,
  });

  @override
  _UploadDressScreenState createState() => _UploadDressScreenState();
}

class _UploadDressScreenState extends State<UploadDressScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Text Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController fabricController = TextEditingController();
  final TextEditingController styleController = TextEditingController();
  final TextEditingController seasonController = TextEditingController();
  final TextEditingController eventTypeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController rentalPriceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController availableFromController = TextEditingController();
  final TextEditingController availableToController = TextEditingController();

  // State Variables
  List<File> selectedImages = [];
  List<String> existingImages = [];
  bool loading = false;
  int _selectedTabIndex = 0; // 0 = Upload, 1 = My Dresses, 2 = Orders
  
  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.isEditMode && widget.dressToEdit != null) {
      _loadDressDataForEdit();
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
  }

  // ✅ FIXED: Safe null handling in load dress data
  void _loadDressDataForEdit() {
    final dress = widget.dressToEdit!;
    
    // Safe text extraction with null checks
    nameController.text = _safeString(dress['name']);
    descriptionController.text = _safeString(dress['description']);
    colorController.text = _safeString(dress['color']);
    sizeController.text = _safeString(dress['size']);
    fabricController.text = _safeString(dress['fabric']);
    styleController.text = _safeString(dress['style']);
    seasonController.text = _safeString(dress['season']);
    eventTypeController.text = _safeString(dress['event_type']);
    
    // Safe numeric extraction
    priceController.text = _safeNumber(dress['price']);
    rentalPriceController.text = _safeNumber(dress['rental_price']);
    
    // Safe date extraction
    availableFromController.text = _safeString(dress['available_from']);
    availableToController.text = _safeString(dress['available_to']);
    
    // Safe images extraction
    if (dress['images'] != null && dress['images'] is List) {
      existingImages = List<String>.from(dress['images']).where((img) => img != null).toList();
    } else {
      existingImages = [];
    }
    
    debugPrint('✅ Loaded dress for edit: ${nameController.text}');
    debugPrint('✅ Images count: ${existingImages.length}');
  }

  // Helper: Safe string extraction
  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // Helper: Safe number extraction
  String _safeNumber(dynamic value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(0);
    return value.toString();
  }

  // ==================== IMAGE PICKING ====================
  Future<void> pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final totalImages = selectedImages.length + existingImages.length + pickedFiles.length;
        if (totalImages > 10) {
          _showSnackBar("Maximum 10 images allowed", Colors.orange);
          return;
        }

        setState(() {
          selectedImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
        });

        _showSnackBar("${pickedFiles.length} image(s) selected", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Failed to pick images", Colors.red);
    }
  }

  // ==================== IMAGE UPLOAD ====================
  Future<List<String>> uploadImages(String dressId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    List<String> urls = [];
    
    for (int i = 0; i < selectedImages.length; i++) {
      final file = selectedImages[i];
      try {
        final originalName = file.path.split('/').last;
        final safeName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
        final fileName = '${_uuid.v4()}_$safeName';
        final path = '${user.id}/$dressId/$fileName';

        final Uint8List fileBytes = await file.readAsBytes();
        
        await supabase.storage.from('dresses').uploadBinary(path, fileBytes);
        
        final url = supabase.storage.from('dresses').getPublicUrl(path);
        urls.add(url);
        
      } catch (e) {
        throw Exception("Failed to upload image $i: ${e.toString()}");
      }
    }
    
    return urls;
  }

  // ==================== DATE PICKER ====================
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF660033),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final formattedDate = "${picked.year}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";
      controller.text = formattedDate;
    }
  }

  // ==================== DATE VALIDATION ====================
  bool _isValidDate(String date) {
    if (date.isEmpty) return true;
    try {
      final parts = date.split('-');
      if (parts.length != 3) return false;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      if (year < 2000 || year > 2100) return false;
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      
      DateTime(year, month, day);
      return true;
    } catch (e) {
      return false;
    }
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // ==================== SUBMIT DRESS ====================
  Future<void> submitDress() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please check all required fields", Colors.orange);
      return;
    }

    if (selectedImages.isEmpty && existingImages.isEmpty) {
      _showSnackBar("Please select at least one image", Colors.orange);
      return;
    }

    // Date validation
    if (availableFromController.text.isNotEmpty && availableToController.text.isNotEmpty) {
      try {
        final fromDate = _parseDate(availableFromController.text);
        final toDate = _parseDate(availableToController.text);
        
        if (toDate.isBefore(fromDate)) {
          _showSnackBar('"Available To" date must be after "Available From" date', Colors.red);
          return;
        }
      } catch (e) {
        _showSnackBar('Invalid date format', Colors.red);
        return;
      }
    }

    setState(() => loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("Please login again");

      final dressId = widget.isEditMode ? widget.dressToEdit!['id'] : _uuid.v4();
      
      // Upload new images
      final newImageUrls = await uploadImages(dressId);
      
      // Combine with existing images
      final allImageUrls = [...existingImages, ...newImageUrls];

      // Prepare dress data with safe null handling
      final Map<String, dynamic> dressData = {
        'id': dressId,
        'vendor_id': user.id,
        'name': nameController.text.trim(),
        'color': colorController.text.trim(),
        'size': sizeController.text.trim(),
        'fabric': fabricController.text.trim().isEmpty ? null : fabricController.text.trim(),
        'style': styleController.text.trim().isEmpty ? null : styleController.text.trim(),
        'season': seasonController.text.trim().isEmpty ? null : seasonController.text.trim(),
        'event_type': eventTypeController.text.trim().isEmpty ? null : eventTypeController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0.0,
        'rental_price': rentalPriceController.text.trim().isEmpty ? null : double.tryParse(rentalPriceController.text.trim()),
        'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        'images': allImageUrls,
        'status': 'available',
        'available_from': availableFromController.text.trim().isEmpty ? null : availableFromController.text.trim(),
        'available_to': availableToController.text.trim().isEmpty ? null : availableToController.text.trim(),
        'is_approved': widget.isEditMode ? (widget.dressToEdit!['is_approved'] ?? false) : false,
        'view_count': widget.isEditMode ? (widget.dressToEdit!['view_count'] ?? 0) : 0,
        'wishlist_count': widget.isEditMode ? (widget.dressToEdit!['wishlist_count'] ?? 0) : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (!widget.isEditMode) {
        dressData['created_at'] = DateTime.now().toIso8601String();
      }

      // Insert or update in database
      if (widget.isEditMode) {
        await supabase
            .from('dresses')
            .update(dressData)
            .eq('id', dressId);
        
        if (mounted) {
          _showSnackBar("Dress updated successfully!", Colors.green);
          Navigator.pop(context, true);
        }
      } else {
        await supabase
            .from('dresses')
            .insert(dressData);
        
        if (mounted) {
          _showSuccessDialog();
        }
      }

    } catch (e) {
      setState(() => loading = false);
      _showSnackBar("Error: ${e.toString()}", Colors.red);
      debugPrint('❌ Submit error: $e');
    }
  }

  // ==================== SUCCESS DIALOG ====================
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF5F8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Successfully Uploaded!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF660033),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your dress has been uploaded and is pending admin approval.\nYou will be notified once it\'s approved.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetForm();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF660033)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Upload Another',
                          style: TextStyle(
                            color: Color(0xFF660033),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedTabIndex = 1;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF660033),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'View My Dresses',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => setState(() => loading = false));
  }

  // ==================== HELPER METHODS ====================
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      loading = false;
      selectedImages.clear();
      existingImages.clear();
      nameController.clear();
      colorController.clear();
      sizeController.clear();
      fabricController.clear();
      styleController.clear();
      seasonController.clear();
      eventTypeController.clear();
      priceController.clear();
      rentalPriceController.clear();
      descriptionController.clear();
      availableFromController.clear();
      availableToController.clear();
      _formKey.currentState?.reset();
    });
  }

  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        existingImages.removeAt(index);
      } else {
        selectedImages.removeAt(index);
      }
    });
    _showSnackBar("Image removed", Colors.grey);
  }

  // ==================== UI BUILDERS ====================
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: const TextStyle(color: Color(0xFF660033)),
          prefixIcon: prefixIcon != null 
              ? Icon(prefixIcon, color: const Color(0xFF660033), size: 20)
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF660033), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
        validator: validator ?? (required ? (val) => val == null || val.isEmpty ? "$label is required" : null : null),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    bool required = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context, controller),
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: const TextStyle(color: Color(0xFF660033)),
          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF660033), size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF660033)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF660033), width: 2),
          ),
          hintText: 'YYYY-MM-DD',
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) return '$label is required';
                if (!_isValidDate(value)) return 'Invalid date format';
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildImagePreview() {
    final allImages = [
      ...existingImages.map((url) => ImageItem(isNetwork: true, url: url)),
      ...selectedImages.map((file) => ImageItem(isNetwork: false, file: file)),
    ];

    if (allImages.isEmpty) {
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF660033).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      size: 50,
                      color: Color(0xFF660033),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No images selected',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maximum 10 images',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: allImages.length,
          itemBuilder: (context, index) {
            final item = allImages[index];
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: item.isNetwork
                            ? Image.network(
                                item.url!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, size: 30),
                                  );
                                },
                              )
                            : Image.file(
                                item.file!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => _removeImage(
                            item.isNetwork ? existingImages.indexOf(item.url!) : selectedImages.indexOf(item.file!),
                            isExisting: item.isNetwork,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          bottom: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF660033).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Main',
                              style: TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF660033).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${allImages.length} of 10 images selected',
            style: const TextStyle(
              color: Color(0xFF660033),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF660033).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF660033), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660033),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== GET CURRENT BODY ====================
  Widget _getBody() {
    switch (_selectedTabIndex) {
      case 0: // Upload Dress
        return _buildUploadForm();
      case 1: // My Dresses
        return const VendorDressManagementScreen();
      case 2: // Orders
        final user = supabase.auth.currentUser;
        if (user != null) {
          return VendorOrdersScreen(user: user);
        } else {
          return const Center(
            child: Text('Please login to view orders'),
          );
        }
      default:
        return _buildUploadForm();
    }
  }

  Widget _buildUploadForm() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/flowers_bg.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
          colorFilter: ColorFilter.mode(
            const Color(0xFF660033).withOpacity(0.05),
            BlendMode.softLight,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Basic Information Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white.withOpacity(0.9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.info_outline,
                              title: 'Basic Information',
                              subtitle: 'Enter the basic details of your dress',
                            ),
                            const SizedBox(height: 20),
                            _buildFormField(
                              label: 'Dress Name',
                              controller: nameController,
                              prefixIcon: Icons.style,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Dress name is required';
                                if (RegExp(r'\d').hasMatch(v)) return 'Numbers are not allowed';
                                return null;
                              },
                            ),
                            _buildFormField(
                              label: 'Description',
                              controller: descriptionController,
                              maxLines: 3,
                              prefixIcon: Icons.description,
                              required: false,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Color',
                                    controller: colorController,
                                    prefixIcon: Icons.color_lens,
                                    required: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Size',
                                    controller: sizeController,
                                    prefixIcon: Icons.straighten,
                                    required: false,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Fabric',
                                    controller: fabricController,
                                    required: false,
                                    prefixIcon: Icons.texture,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Style',
                                    controller: styleController,
                                    required: false,
                                    prefixIcon: Icons.design_services,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pricing & Details Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white.withOpacity(0.9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.payments_outlined,
                              title: 'Pricing & Details',
                              subtitle: 'Set pricing and availability',
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Season',
                                    controller: seasonController,
                                    required: false,
                                    prefixIcon: Icons.wb_sunny,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Event Type',
                                    controller: eventTypeController,
                                    required: false,
                                    prefixIcon: Icons.event,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Price (Rs.)',
                                    controller: priceController,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.currency_rupee,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Price is required';
                                      if (double.tryParse(val) == null) return 'Invalid price';
                                      if (double.parse(val) <= 0) return 'Price must be greater than 0';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Rental Price (Rs.)',
                                    controller: rentalPriceController,
                                    keyboardType: TextInputType.number,
                                    required: false,
                                    prefixIcon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Available From',
                                    controller: availableFromController,
                                    context: context,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Available To',
                                    controller: availableToController,
                                    context: context,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Images Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white.withOpacity(0.9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.photo_library_outlined,
                              title: 'Dress Images',
                              subtitle: 'Upload clear photos (max 10)',
                            ),
                            const SizedBox(height: 20),
                            _buildImagePreview(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: pickImages,
                                    icon: const Icon(Icons.add_photo_alternate_outlined),
                                    label: Text(
                                      selectedImages.isEmpty && existingImages.isEmpty 
                                          ? 'Select Images' 
                                          : 'Add More Images',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF660033),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                                if (selectedImages.isNotEmpty || existingImages.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 56,
                                    child: ElevatedButton(
                                      onPressed: () => setState(() {
                                        selectedImages.clear();
                                        existingImages.clear();
                                      }),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: const Icon(Icons.delete_outline),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF660033), Color(0xFF8B0040)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF660033).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: loading ? null : submitDress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.isEditMode ? Icons.save_outlined : Icons.cloud_upload_outlined,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.isEditMode ? 'Update Dress' : 'Upload Dress',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _getBody(),
      
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF660033),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload_outlined),
              activeIcon: Icon(Icons.cloud_upload),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_outlined),
              activeIcon: Icon(Icons.inventory),
              label: 'My Dresses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
          ],
        ),
      ),

      // FAB for My Dresses tab
      floatingActionButton: _selectedTabIndex == 1 
          ? TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    backgroundColor: const Color(0xFF660033),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                );
              },
            )
          : null,
      
      floatingActionButtonLocation: _selectedTabIndex == 1
          ? FloatingActionButtonLocation.endFloat
          : null,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    colorController.dispose();
    sizeController.dispose();
    fabricController.dispose();
    styleController.dispose();
    seasonController.dispose();
    eventTypeController.dispose();
    priceController.dispose();
    rentalPriceController.dispose();
    descriptionController.dispose();
    availableFromController.dispose();
    availableToController.dispose();
    super.dispose();
  }
}

class ImageItem {
  final bool isNetwork;
  final String? url;
  final File? file;

  ImageItem({required this.isNetwork, this.url, this.file});
}