// lib/screens/ProfileSetupScreen.dart
import 'package:bridalease_fyp/screens/role_based_screen.dart';
import 'package:bridalease_fyp/supabase.dart';
import 'package:bridalease_fyp/utils/avatar_helper.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isFromLogin;
  final Map<String, dynamic>? existingUserData;

  const ProfileSetupScreen({
    super.key,
    this.isFromLogin = true,
    this.existingUserData,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _vendorInfoFormKey = GlobalKey<FormState>();

  // Common Fields
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Selected options
  String? _selectedHeightCategory;
  String? _selectedWeightCategory;
  String? _selectedSkinTone;

  // Vendor Business
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessDescriptionController = TextEditingController();

  String _selectedRole = 'bride';
  bool _loading = false;
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();
  String _avatarPreviewPath = '';

  // Height Categories
  final List<Map<String, dynamic>> _heightCategories = [
    {'name': 'short', 'icon': Icons.arrow_circle_down_rounded, 'label': 'Short', 'description': 'Below 155 cm', 'gradient': [Colors.blue.shade300, Colors.blue.shade600], 'emoji': '🦋'},
    {'name': 'medium', 'icon': Icons.height_rounded, 'label': 'Medium', 'description': '155 - 165 cm', 'gradient': [Colors.green.shade300, Colors.green.shade600], 'emoji': '🌸'},
    {'name': 'tall', 'icon': Icons.arrow_circle_up_rounded, 'label': 'Tall', 'description': 'Above 165 cm', 'gradient': [Colors.purple.shade300, Colors.purple.shade600], 'emoji': '🌺'},
  ];

  // Weight Categories
  final List<Map<String, dynamic>> _weightCategories = [
    {'name': 'slim', 'icon': Icons.flare_rounded, 'label': 'Slim', 'description': 'BMI < 18.5', 'gradient': [Colors.lightBlue.shade300, Colors.blue.shade600], 'emoji': '✨'},
    {'name': 'average', 'icon': Icons.auto_awesome_rounded, 'label': 'Average', 'description': 'BMI 18.5 - 25', 'gradient': [Colors.teal.shade300, Colors.teal.shade600], 'emoji': '🌟'},
    {'name': 'curvy', 'icon': Icons.waves_rounded, 'label': 'Curvy', 'description': 'BMI 25 - 30', 'gradient': [Colors.orange.shade300, Colors.deepOrange.shade600], 'emoji': '💫'},
    {'name': 'plus', 'icon': Icons.circle_rounded, 'label': 'Plus Size', 'description': 'BMI > 30', 'gradient': [Colors.pink.shade300, Colors.pink.shade600], 'emoji': '⭐'},
  ];

  // Skin tone options
  final List<Map<String, dynamic>> _skinTones = [
    {'name': 'fair', 'color': const Color(0xFFFFE0BD), 'label': 'Fair', 'emoji': '☀️'},
    {'name': 'wheatish', 'color': const Color(0xFFDEB887), 'label': 'Wheatish', 'emoji': '🌾'},
    {'name': 'dark', 'color': const Color(0xFF5D3A1A), 'label': 'Dark', 'emoji': '🌙'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = widget.existingUserData;
    if (data == null) return;

    debugPrint('📝 Loading existing user data for edit mode');
    
    _fullNameController.text = data['full_name'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _selectedRole = data['role'] ?? 'bride';
    _selectedSkinTone = data['skin_tone'];
    
    final measurements = data['body_measurements'] ?? {};
    double? height = measurements['height_cm']?.toDouble();
    double? weight = measurements['weight_kg']?.toDouble();
    
    if (height != null) {
      if (height < 155) _selectedHeightCategory = 'short';
      else if (height < 165) _selectedHeightCategory = 'medium';
      else _selectedHeightCategory = 'tall';
    }
    
    if (height != null && weight != null) {
      double bmi = weight / ((height/100) * (height/100));
      if (bmi < 18.5) _selectedWeightCategory = 'slim';
      else if (bmi < 25) _selectedWeightCategory = 'average';
      else if (bmi < 30) _selectedWeightCategory = 'curvy';
      else _selectedWeightCategory = 'plus';
    }

    _businessNameController.text = data['business_name'] ?? '';
    _businessAddressController.text = data['business_address'] ?? '';
    _businessPhoneController.text = data['business_phone'] ?? '';
    _businessDescriptionController.text = data['business_description'] ?? '';

    // Update avatar preview if bride
    if (_selectedRole == 'bride' && _selectedHeightCategory != null && 
        _selectedWeightCategory != null && _selectedSkinTone != null) {
      _updateAvatarPreview();
    }
  }

  void _updateAvatarPreview() {
    if (_selectedRole != 'bride') return;
    
    if (_selectedHeightCategory == null || _selectedWeightCategory == null || _selectedSkinTone == null) {
      return;
    }
    
    double height = _selectedHeightCategory == 'short' ? 150 
                  : _selectedHeightCategory == 'medium' ? 160 
                  : 170;
    
    double weight = _selectedWeightCategory == 'slim' ? 45
                  : _selectedWeightCategory == 'average' ? 60
                  : _selectedWeightCategory == 'curvy' ? 70
                  : 80;
    
    setState(() {
      _avatarPreviewPath = AvatarHelper.getAvatarPath(
        height: height,
        weight: weight,
        skinTone: _selectedSkinTone ?? 'wheatish',
      );
    });
  }

  List<Step> get _steps => [
    Step(
      title: Text('Basic Info', style: TextStyle(color: _currentStep == 0 ? const Color(0xFF660033) : Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 13)),
      content: _buildBasicInfoStep(),
      isActive: _currentStep >= 0,
      state: _currentStep == 0 ? StepState.editing : StepState.indexed,
    ),
    Step(
      title: Text(_selectedRole == 'bride' ? 'Body Type' : 'Business Info', 
        style: TextStyle(color: _currentStep == 1 ? const Color(0xFF660033) : Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 13)),
      content: _selectedRole == 'bride' ? _buildBrideBodyTypeStep() : _buildVendorBusinessStep(),
      isActive: _currentStep >= 1,
      state: _currentStep == 1 ? StepState.editing : StepState.indexed,
    ),
    Step(
      title: Text(_selectedRole == 'bride' ? 'Your Avatar' : 'Complete',
        style: TextStyle(color: _currentStep == 2 ? const Color(0xFF660033) : Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 13)),
      content: _selectedRole == 'bride' ? _buildAvatarCompletionStep() : _buildVendorCompletionStep(),
      isActive: _currentStep >= 2,
      state: _currentStep == 2 ? StepState.editing : StepState.indexed,
    ),
  ];

  Widget _buildBasicInfoStep() {
    return Form(
      key: _basicInfoFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFormField(
            label: 'Full Name',
            controller: _fullNameController,
            icon: Icons.person_outline,
            required: true,
            validator: (v) {
              if (v == null || v.isEmpty) return "Please enter your full name";
              if (RegExp(r'\d').hasMatch(v)) return "Numbers not allowed";
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildFormField(
            label: 'Phone',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            required: true,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
          ),
          const SizedBox(height: 12),
          _buildRoleSelection(),
        ],
      ),
    );
  }

  Widget _buildBrideBodyTypeStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Height Category
          _buildSection(
            icon: Icons.height_rounded,
            title: 'Your Height',
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _heightCategories.length,
                itemBuilder: (context, index) {
                  final category = _heightCategories[index];
                  bool isSelected = _selectedHeightCategory == category['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedHeightCategory = category['name'];
                        _updateAvatarPreview();
                      });
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(colors: category['gradient'] as List<Color>) : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category['icon'], size: 24, color: isSelected ? Colors.white : (category['gradient'] as List<Color>).last),
                          const SizedBox(height: 4),
                          Text(category['label'], style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade800)),
                          Text(category['description'], style: TextStyle(fontSize: 9, color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Weight Category
          _buildSection(
            icon: Icons.fitness_center_rounded,
            title: 'Your Body Type',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.4,
              ),
              itemCount: _weightCategories.length,
              itemBuilder: (context, index) {
                final category = _weightCategories[index];
                bool isSelected = _selectedWeightCategory == category['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedWeightCategory = category['name'];
                      _updateAvatarPreview();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? LinearGradient(colors: category['gradient'] as List<Color>) : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category['icon'], size: 22, color: isSelected ? Colors.white : (category['gradient'] as List<Color>).last),
                        const SizedBox(height: 4),
                        Text(category['label'], style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade800)),
                        Text(category['description'], style: TextStyle(fontSize: 9, color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skin Tone
          _buildSection(
            icon: Icons.color_lens_rounded,
            title: 'Your Skin Tone',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _skinTones.map((tone) {
                bool isSelected = _selectedSkinTone == tone['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSkinTone = tone['name'];
                      _updateAvatarPreview();
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(colors: [tone['color'], (tone['color'] as Color).withOpacity(0.7)]),
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? const Color(0xFF660033) : Colors.grey.shade300, width: isSelected ? 3 : 1.5),
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(tone['label'], style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF660033) : Colors.grey[700])),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Live Avatar Preview
          if (_avatarPreviewPath.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF660033).withOpacity(0.1), Colors.transparent]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF660033).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF660033).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.preview_rounded, color: Color(0xFF660033), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Avatar Preview:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
                  const Spacer(),
                  Container(
                    width: 45,
                    height: 65,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF660033), width: 1.5)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(_avatarPreviewPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20))),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF660033).withOpacity(0.05), Colors.transparent]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF660033).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFF660033), size: 16)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildAvatarCompletionStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: const Color(0xFF660033).withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF660033), width: 2)),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF660033), size: 30),
          ),
          const SizedBox(height: 10),
          const Text('Your Avatar is Ready!', style: TextStyle(fontSize: 16, color: Color(0xFF660033), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF660033).withOpacity(0.3))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your Virtual Avatar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
                const SizedBox(height: 10),
                Container(
                  height: 160,
                  width: 120,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _avatarPreviewPath.isNotEmpty
                        ? Image.asset(_avatarPreviewPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 30)))
                        : Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(color: Color(0xFF660033)))),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.height, 'Height', _getHeightLabel()),
                      const Divider(height: 10),
                      _buildInfoRow(_getWeightIcon(), 'Body Type', _getWeightLabel()),
                      const Divider(height: 10),
                      _buildInfoRow(Icons.color_lens, 'Skin Tone', _selectedSkinTone?.toUpperCase() ?? 'WHEATISH', color: AvatarHelper.getSkinToneColor(_selectedSkinTone ?? 'wheatish')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorBusinessStep() {
    return Form(
      key: _vendorInfoFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFormField(label: 'Business Name', controller: _businessNameController, icon: Icons.business_outlined, required: true),
          const SizedBox(height: 10),
          _buildFormField(label: 'Business Address', controller: _businessAddressController, icon: Icons.location_on_outlined, maxLines: 2),
          const SizedBox(height: 10),
          _buildFormField(label: 'Business Phone', controller: _businessPhoneController, icon: Icons.phone_outlined, required: true, keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          _buildFormField(label: 'Business Description', controller: _businessDescriptionController, icon: Icons.description_outlined, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildVendorCompletionStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 2)),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 30),
          ),
          const SizedBox(height: 10),
          const Text('Profile Complete!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF660033).withOpacity(0.3))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store, size: 40, color: Color(0xFF660033)),
                const SizedBox(height: 8),
                _buildVendorDetailRow(Icons.business, 'Business Name', _businessNameController.text),
                const Divider(height: 10),
                _buildVendorDetailRow(Icons.location_on, 'Address', _businessAddressController.text.isEmpty ? 'Not provided' : _businessAddressController.text),
                const Divider(height: 10),
                _buildVendorDetailRow(Icons.phone, 'Phone', _businessPhoneController.text),
                if (_businessDescriptionController.text.isNotEmpty) ...[
                  const Divider(height: 10),
                  _buildVendorDetailRow(Icons.description, 'Description', _businessDescriptionController.text, maxLines: 2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87, fontSize: 13),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: const TextStyle(color: Color(0xFF660033), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF660033), size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF660033), width: 2)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator ?? (required ? (val) => val == null || val.isEmpty ? "$label is required" : null : null),
    );
  }

  Widget _buildRoleSelection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select Your Role *', style: TextStyle(color: Color(0xFF660033), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildRoleButton('Bride', Icons.favorite_border, 'bride')),
              const SizedBox(width: 8),
              Expanded(child: _buildRoleButton('Vendor', Icons.business_center_outlined, 'vendor')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String label, IconData icon, String role) {
    bool isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _clearStep2Fields();
          if (role == 'bride') _updateAvatarPreview();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF660033).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF660033) : Colors.grey[300]!, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF660033) : Colors.grey[600], size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFF660033) : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _clearStep2Fields() {
    _selectedHeightCategory = null;
    _selectedWeightCategory = null;
    _selectedSkinTone = null;
    _avatarPreviewPath = '';
    _businessNameController.clear();
    _businessAddressController.clear();
    _businessPhoneController.clear();
    _businessDescriptionController.clear();
  }

  String _getHeightLabel() {
    switch (_selectedHeightCategory) {
      case 'short': return 'Short (below 155 cm)';
      case 'medium': return 'Medium (155-165 cm)';
      case 'tall': return 'Tall (above 165 cm)';
      default: return 'Not selected';
    }
  }

  String _getWeightLabel() {
    switch (_selectedWeightCategory) {
      case 'slim': return 'Slim';
      case 'average': return 'Average';
      case 'curvy': return 'Curvy';
      case 'plus': return 'Plus Size';
      default: return 'Not selected';
    }
  }

  IconData _getWeightIcon() {
    switch (_selectedWeightCategory) {
      case 'slim': return Icons.flare_rounded;
      case 'average': return Icons.auto_awesome_rounded;
      case 'curvy': return Icons.waves_rounded;
      case 'plus': return Icons.circle_rounded;
      default: return Icons.accessibility;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFF660033).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: const Color(0xFF660033), size: 14)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))])),
        if (color != null) Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
      ],
    );
  }

  Widget _buildVendorDetailRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF660033)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: maxLines, overflow: TextOverflow.ellipsis)])),
      ],
    );
  }

  void _handleStepContinue() {
    if (_currentStep == 0) {
      if (_basicInfoFormKey.currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 1) {
      if (_selectedRole == 'vendor') {
        if (_vendorInfoFormKey.currentState!.validate()) {
          setState(() => _currentStep += 1);
        }
      } else {
        bool isValid = true;
        if (_selectedHeightCategory == null) {
          isValid = false;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your height'), backgroundColor: Colors.red, duration: Duration(seconds: 1)));
        } else if (_selectedWeightCategory == null) {
          isValid = false;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your body type'), backgroundColor: Colors.red, duration: Duration(seconds: 1)));
        } else if (_selectedSkinTone == null) {
          isValid = false;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your skin tone'), backgroundColor: Colors.red, duration: Duration(seconds: 1)));
        }
        if (isValid) {
          _updateAvatarPreview();
          setState(() => _currentStep += 1);
        }
      }
    } else {
      _completeProfile();
    }
  }

  Future<void> _completeProfile() async {
    setState(() => _loading = true);
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      Map<String, dynamic> bodyMeasurements = {};
      if (_selectedRole == 'bride') {
        double height = _selectedHeightCategory == 'short' ? 150 : _selectedHeightCategory == 'medium' ? 160 : 170;
        double weight = _selectedWeightCategory == 'slim' ? 45 : _selectedWeightCategory == 'average' ? 60 : _selectedWeightCategory == 'curvy' ? 70 : 80;
        bodyMeasurements = {'height_cm': height, 'weight_kg': weight, 'body_type': _selectedWeightCategory};
      }

      final Map<String, dynamic> userData = {
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'skin_tone': _selectedSkinTone,
        'is_profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (_selectedRole == 'bride') userData['body_measurements'] = bodyMeasurements;
      if (_selectedRole == 'vendor') {
        userData.addAll({
          'business_name': _businessNameController.text.trim(),
          'business_address': _businessAddressController.text.trim(),
          'business_phone': _businessPhoneController.text.trim(),
          'business_description': _businessDescriptionController.text.trim(),
        });
      }

      userData.removeWhere((key, value) => value == null);
      await supabase.from('users').upsert({'id': currentUser.id, 'email': currentUser.email, ...userData}, onConflict: 'id');

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_selectedRole == 'bride' ? 'Profile completed! Your avatar is ready.' : 'Business profile completed!'),
        backgroundColor: const Color(0xFF660033),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1)
      ));

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => RoleBasedScreen(role: _selectedRole)), (route) => false);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: Image.asset('assets/images/flowers_bg.png', fit: BoxFit.cover)),
          Container(color: Colors.white.withOpacity(0.7)),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(decoration: const BoxDecoration(color: Color(0xFF660033), shape: BoxShape.circle), padding: const EdgeInsets.all(6), child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.isFromLogin ? 'Complete Your Profile' : 'Edit Profile', style: const TextStyle(fontSize: 18, color: Color(0xFF660033), fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF660033).withOpacity(0.3))),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: List.generate(3, (index) {
                            String stepLabel = index == 0 ? 'Basic' : index == 1 ? (_selectedRole == 'bride' ? 'Body' : 'Business') : (_selectedRole == 'bride' ? 'Avatar' : 'Done');
                            return Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 28, width: 28,
                                    decoration: BoxDecoration(color: _currentStep >= index ? const Color(0xFF660033) : Colors.grey[300], shape: BoxShape.circle, border: Border.all(color: _currentStep >= index ? const Color(0xFF660033) : Colors.grey[400]!, width: 2)),
                                    child: Center(child: Text((index + 1).toString(), style: TextStyle(color: _currentStep >= index ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 11))),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(stepLabel, style: TextStyle(color: _currentStep >= index ? const Color(0xFF660033) : Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                          padding: const EdgeInsets.all(8),
                          child: _steps[_currentStep].content,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => _currentStep -= 1),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF660033)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(vertical: 8)),
                                  child: const Text('Back', style: TextStyle(color: Color(0xFF660033), fontSize: 12)),
                                ),
                              ),
                            if (_currentStep > 0) const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleStepContinue,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF660033), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(vertical: 8)),
                                child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_currentStep < 2 ? 'Continue' : 'Complete', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessDescriptionController.dispose();
    super.dispose();
  }
}