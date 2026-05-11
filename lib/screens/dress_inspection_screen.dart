import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class DressInspectionScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> returnRequest;

  const DressInspectionScreen({
    super.key,
    required this.order,
    required this.returnRequest,
  });

  @override
  State<DressInspectionScreen> createState() => _DressInspectionScreenState();
}

class _DressInspectionScreenState extends State<DressInspectionScreen> {
  String _selectedCondition = 'perfect';
  final TextEditingController _damageController = TextEditingController();
  final TextEditingController _penaltyController = TextEditingController();
  List<String> _photos = [];
  bool _isSubmitting = false;
  bool _isUploading = false;

  final List<Map<String, dynamic>> _conditionOptions = [
    {'value': 'perfect', 'label': 'Perfect - No issues', 'color': Colors.green, 'penaltyPercent': 0},
    {'value': 'minor_wear', 'label': 'Minor wear - Acceptable', 'color': Colors.blue, 'penaltyPercent': 0},
    {'value': 'minor_damage', 'label': 'Minor damage - Penalty applies (20%)', 'color': Colors.orange, 'penaltyPercent': 0.2},
    {'value': 'major_damage', 'label': 'Major damage - Reject with penalty (100%)', 'color': Colors.red, 'penaltyPercent': 1.0},
  ];

  @override
  void initState() {
    super.initState();
    _penaltyController.text = '0';
    _penaltyController.addListener(_onPenaltyChanged);
  }

  @override
  void dispose() {
    _damageController.dispose();
    _penaltyController.dispose();
    _penaltyController.removeListener(_onPenaltyChanged);
    super.dispose();
  }

  void _onPenaltyChanged() {
    setState(() {});
  }

  // ✅ Safe double conversion helper
  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  double get _securityDeposit {
    return _toDouble(widget.order['security_deposit']);
  }

  double get _dressPrice {
    final totalAmount = widget.order['total_amount'];
    if (totalAmount != null) {
      return _toDouble(totalAmount);
    }
    
    final items = widget.order['order_items'];
    if (items != null && items is List && items.isNotEmpty) {
      double sum = 0;
      for (var item in items) {
        sum += _toDouble(item['price']);
      }
      return sum;
    }
    
    return 10000;
  }

  double _getSuggestedPenalty() {
    // ✅ FIXED: Manual loop instead of firstWhere to avoid type issues
    double percent = 0;
    for (var opt in _conditionOptions) {
      if (opt['value'] == _selectedCondition) {
        percent = (opt['penaltyPercent'] as num).toDouble();
        break;
      }
    }
    
    final dressPrice = _dressPrice;
    return dressPrice * percent;
  }

  double get _currentPenalty {
    final text = _penaltyController.text;
    if (text.isEmpty) return _getSuggestedPenalty();
    
    final penalty = double.tryParse(text);
    if (penalty != null && penalty >= 0) {
      return penalty;
    }
    return _getSuggestedPenalty();
  }

  double get _refundAmount {
    final refund = _securityDeposit - _currentPenalty;
    return refund > 0 ? refund : 0;
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (photo != null) {
      setState(() => _isUploading = true);
      
      try {
        final fileName = 'inspection/${widget.order['id']}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(photo.path);
        
        await supabase.storage.from('returns').upload(fileName, file);
        final imageUrl = supabase.storage.from('returns').getPublicUrl(fileName);
        
        setState(() {
          _photos.add(imageUrl);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully'), backgroundColor: Colors.green),
        );
      } catch (e) {
        debugPrint('Upload error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _removePhoto(int index) async {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _submitInspection() async {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take photos of the dress'), backgroundColor: Colors.orange),
      );
      return;
    }

    if ((_selectedCondition == 'minor_damage' || _selectedCondition == 'major_damage') && _damageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the damage'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now().toIso8601String();
      final penalty = _currentPenalty;
      final isAccepted = _selectedCondition == 'perfect' || _selectedCondition == 'minor_wear';
      
      await supabase
          .from('return_requests')
          .update({
            'inspection_status': isAccepted ? 'accepted' : 'rejected',
            'damage_description': _damageController.text.trim(),
            'penalty_amount': penalty,
            'inspection_photos': _photos,
            'inspected_at': now,
            'return_status': isAccepted ? 'completed' : 'rejected',
          })
          .eq('id', widget.returnRequest['id']);

      if (isAccepted) {
        final refundAmount = _refundAmount;
        
        await supabase
            .from('orders')
            .update({
              'return_status': 'completed',
              'security_deposit_refunded': true,
              'refund_amount': refundAmount,
              'penalty_charged': penalty,
              'return_completed_at': now,
            })
            .eq('id', widget.order['id']);

        final itemsResponse = await supabase
            .from('order_items')
            .select('dress_id')
            .eq('order_id', widget.order['id'])
            .maybeSingle();
        
        if (itemsResponse?['dress_id'] != null) {
          await supabase
              .from('dresses')
              .update({'status': 'available'})
              .eq('id', itemsResponse?['dress_id']);
        }

        await supabase.from('notifications').insert({
          'user_id': widget.order['user_id'],
          'user_type': 'bride',
          'type': 'return_accepted',
          'title': '✅ Return Accepted',
          'message': penalty > 0 
              ? 'Your return has been accepted. Penalty of Rs ${NumberFormat('#,##0').format(penalty)} has been deducted. Refund amount: Rs ${NumberFormat('#,##0').format(refundAmount)}'
              : 'Your return has been accepted. Security deposit of Rs ${NumberFormat('#,##0').format(_securityDeposit)} has been refunded.',
          'data': {'order_id': widget.order['id']},
          'created_at': now,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(penalty > 0 
                ? 'Return accepted! Penalty: Rs ${NumberFormat('#,##0').format(penalty)}' 
                : 'Return accepted! Refund processed.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // ✅ FIX: Go back to orders screen properly
        if (mounted) {
          Navigator.pop(context); // Close inspection screen
          Navigator.pop(context); // Close return screen, go back to orders
        }
        
      } else {
        // ✅ REJECT CASE - Fixed navigation
        await supabase
            .from('orders')
            .update({
              'return_status': 'rejected',
              'penalty_charged': penalty,
              'rejection_reason': _damageController.text.trim(),
              'inspected_at': now,
            })
            .eq('id', widget.order['id']);

        await supabase.from('notifications').insert({
          'user_id': widget.order['user_id'],
          'user_type': 'bride',
          'type': 'return_rejected',
          'title': '❌ Return Rejected',
          'message': 'Your return has been rejected.\nReason: ${_damageController.text.trim()}\nPenalty charged: Rs ${NumberFormat('#,##0').format(penalty)}',
          'data': {'order_id': widget.order['id']},
          'created_at': now,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Return rejected! Penalty: Rs ${NumberFormat('#,##0').format(penalty)}'),
            backgroundColor: Colors.red,
          ),
        );
        
        // ✅ FIX: Proper navigation after rejection
        if (mounted) {
          // Pop inspection screen (current screen)
          Navigator.pop(context);
          // Pop return request screen (previous screen) - this will go back to orders list
          Navigator.pop(context);
        }
      }
      
    } catch (e) {
      debugPrint('Inspection error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    return 'Rs ${NumberFormat('#,##0').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final suggestedPenalty = _getSuggestedPenalty();
    final isDamaged = _selectedCondition == 'minor_damage' || _selectedCondition == 'major_damage';
    final currentPenalty = _currentPenalty;
    final refundAmount = _refundAmount;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        title: const Text('Dress Inspection', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF660033),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // ✅ FIX: Proper back navigation
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${widget.order['id'].substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF660033)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Text('PENDING INSPECTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.order['customer_name'] ?? 'Customer', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Security Deposit: ${_formatCurrency(_securityDeposit)}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Photos Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.camera_alt, size: 18, color: Color(0xFF660033)),
                      SizedBox(width: 8),
                      Text('Dress Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Take clear photos from all angles', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._photos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final photo = entry.value;
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (!_isUploading)
                        InkWell(
                          onTap: _takePhoto,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 24, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Take', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      if (_isUploading)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        ),
                    ],
                  ),
                  if (_photos.isEmpty && !_isUploading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No photos taken yet. Please take photos of the dress.',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Condition Check
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF660033)),
                      SizedBox(width: 8),
                      Text('Dress Condition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF660033))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._conditionOptions.map((option) => RadioListTile(
                    value: option['value'],
                    groupValue: _selectedCondition,
                    onChanged: (value) {
                      setState(() {
                        _selectedCondition = value!;
                        _penaltyController.text = _getSuggestedPenalty().toStringAsFixed(0);
                      });
                    },
                    title: Text(option['label'], style: TextStyle(color: option['color'], fontWeight: _selectedCondition == option['value'] ? FontWeight.bold : FontWeight.normal)),
                    activeColor: const Color(0xFF660033),
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
            ),

            // Damage Description and Penalty (if damaged)
            if (isDamaged) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Damage Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _damageController,
                      decoration: const InputDecoration(
                        hintText: 'Describe the damage (tears, stains, burns, missing parts, etc.)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.currency_rupee, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Penalty Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _penaltyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter penalty amount',
                        prefixText: 'Rs ',
                        border: const OutlineInputBorder(),
                        helperText: 'Suggested penalty: ${_formatCurrency(suggestedPenalty)}',
                        helperStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _buildSummaryRow('Security Deposit', _formatCurrency(_securityDeposit)),
                          const Divider(height: 8),
                          _buildSummaryRow('Penalty Amount', _formatCurrency(currentPenalty), isPenalty: true),
                          const Divider(height: 8),
                          _buildSummaryRow('Refund Amount', _formatCurrency(refundAmount), isBold: true, color: refundAmount > 0 ? Colors.green : Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // ✅ FIX: Cancel button - just pop current screen
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitInspection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDamaged ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isDamaged ? 'Reject with Penalty' : 'Accept Return', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isPenalty = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isPenalty ? Colors.orange.shade700 : Colors.grey.shade700)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color ?? (isPenalty ? Colors.orange.shade700 : Colors.grey.shade800))),
        ],
      ),
    );
  }
}