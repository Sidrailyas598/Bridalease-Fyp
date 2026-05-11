import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ReturnRequestScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final User user;

  const ReturnRequestScreen({
    super.key,
    required this.order,
    required this.user,
  });

  @override
  State<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen> {
  String? _selectedReason;
  bool _isLoading = false;
  bool _alreadyRequested = false;
  String? _existingRequestStatus;
  final TextEditingController _otherReasonController = TextEditingController();

  final List<String> _returnReasons = [
    'Rental period completed',
    'Dress damaged',
    'Wrong size received',
    'Not as described',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkAlreadyRequested();
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  // ✅ Check if return already requested
  Future<void> _checkAlreadyRequested() async {
    try {
      final response = await supabase
          .from('return_requests')
          .select('return_status')
          .eq('order_id', widget.order['id'])
          .maybeSingle();
      
      if (response != null) {
        setState(() {
          _alreadyRequested = true;
          _existingRequestStatus = response['return_status'];
        });
      }
    } catch (e) {
      debugPrint('Error checking existing request: $e');
    }
  }

  // ✅ Get days left for return (including grace period)
  int _getDaysLeftForReturn() {
    final endDateStr = widget.order['rental_end_date'];
    if (endDateStr == null) return 0;
    
    try {
      final rentalEndDate = DateTime.parse(endDateStr.toString());
      final today = DateTime.now();
      final graceEndDate = rentalEndDate.add(const Duration(days: 3));
      
      if (today.isAfter(graceEndDate)) {
        return -999;
      }
      
      if (today.isBefore(rentalEndDate)) {
        return rentalEndDate.difference(today).inDays;
      }
      
      return graceEndDate.difference(today).inDays;
    } catch (e) {
      return 0;
    }
  }

  // ✅ Check if return is allowed
  bool _canReturn() {
    if (_alreadyRequested) return false;
    final daysLeft = _getDaysLeftForReturn();
    return daysLeft > 0;
  }

  // ✅ Get return status message
  String _getReturnStatusMessage() {
    if (_alreadyRequested) {
      if (_existingRequestStatus == 'pending_inspection') {
        return 'Your return request is pending inspection. Dress will be inspected by vendor.';
      } else if (_existingRequestStatus == 'pending_approval') {
        return 'Your return request is pending approval from vendor.';
      } else if (_existingRequestStatus == 'approved') {
        return 'Your return request has been approved. Pickup will be arranged.';
      } else if (_existingRequestStatus == 'completed') {
        return 'Return already completed';
      } else if (_existingRequestStatus == 'rejected') {
        return 'Your return request was rejected. Contact support.';
      }
      return 'Return request already submitted';
    }
    
    final endDateStr = widget.order['rental_end_date'];
    if (endDateStr == null) return 'Return not available';
    
    try {
      final rentalEndDate = DateTime.parse(endDateStr.toString());
      final today = DateTime.now();
      final graceEndDate = rentalEndDate.add(const Duration(days: 3));
      
      if (today.isAfter(graceEndDate)) {
        return 'Return window closed';
      }
      
      if (today.isBefore(rentalEndDate)) {
        final daysLeft = rentalEndDate.difference(today).inDays;
        return 'Rental period: $daysLeft days remaining';
      }
      
      final daysLeft = graceEndDate.difference(today).inDays;
      return 'Grace period: $daysLeft days left to return';
    } catch (e) {
      return 'Return not available';
    }
  }

  // ✅ Get days left display
  String _getDaysLeftDisplay() {
    final daysLeft = _getDaysLeftForReturn();
    if (daysLeft <= 0) return '0';
    return daysLeft.toString();
  }

  // ✅ Get order ID safely
  String _getOrderId() {
    final id = widget.order['id'];
    if (id == null) return 'Unknown';
    return id.toString().substring(0, 8).toUpperCase();
  }

  // ✅ Get status color for existing request
  Color _getRequestStatusColor() {
    if (_existingRequestStatus == 'pending_inspection') return Colors.purple;
    if (_existingRequestStatus == 'pending_approval') return Colors.orange;
    if (_existingRequestStatus == 'approved') return Colors.blue;
    if (_existingRequestStatus == 'completed') return Colors.green;
    if (_existingRequestStatus == 'rejected') return Colors.red;
    return Colors.grey;
  }

  // ✅ Get status icon for existing request
  IconData _getRequestStatusIcon() {
    if (_existingRequestStatus == 'pending_inspection') return Icons.preview;
    if (_existingRequestStatus == 'pending_approval') return Icons.access_time;
    if (_existingRequestStatus == 'approved') return Icons.check_circle;
    if (_existingRequestStatus == 'completed') return Icons.check_circle;
    if (_existingRequestStatus == 'rejected') return Icons.cancel;
    return Icons.info_outline;
  }

  Future<void> _submitReturnRequest() async {
    // Check if already requested
    if (_alreadyRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted a return request for this order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if return is allowed
    if (!_canReturn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return window has been closed. Please contact support.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a return reason')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String reason;
      if (_selectedReason == 'Other') {
        final otherText = _otherReasonController.text;
        if (otherText == null || otherText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please specify the reason')),
          );
          setState(() => _isLoading = false);
          return;
        }
        reason = otherText.trim();
      } else {
        reason = _selectedReason!;
      }

      // Get dress_id from order_items
      final itemsResponse = await supabase
          .from('order_items')
          .select('dress_id')
          .eq('order_id', widget.order['id'])
          .limit(1)
          .maybeSingle();

      final dressId = itemsResponse?['dress_id'];

      // ✅ Create return request with pending_inspection status
      await supabase.from('return_requests').insert({
        'order_id': widget.order['id'],
        'user_id': widget.user.id,
        'vendor_id': widget.order['vendor_id'],
        'dress_id': dressId,
        'return_reason': reason,
        'return_status': 'pending_inspection',  // ✅ Updated to pending_inspection
        'requested_at': DateTime.now().toIso8601String(),
      });

      // Update order return status
      await supabase
          .from('orders')
          .update({'return_status': 'pending_inspection'})  // ✅ Updated
          .eq('id', widget.order['id']);

      // Send notification to vendor
      if (widget.order['vendor_id'] != null) {
        await supabase.from('notifications').insert({
          'user_id': widget.order['vendor_id'],
          'user_type': 'vendor',
          'type': 'return_requested',
          'title': '📦 Return Request',
          'message': 'Customer requested return for order #${_getOrderId()}. Please inspect the dress.',
          'data': {'order_id': widget.order['id']},
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return request submitted successfully! Vendor will inspect the dress.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canReturn = _canReturn();
    final daysLeft = _getDaysLeftForReturn();
    final orderId = _getOrderId();
    final statusMessage = _getReturnStatusMessage();
    
    final endDateStr = widget.order['rental_end_date'];
    String rentalEndDateText = 'Not set';
    String graceEndDateText = 'Not set';
    
    if (endDateStr != null) {
      try {
        final rentalEndDate = DateTime.parse(endDateStr.toString());
        final graceEndDate = rentalEndDate.add(const Duration(days: 3));
        rentalEndDateText = '${rentalEndDate.day}/${rentalEndDate.month}/${rentalEndDate.year}';
        graceEndDateText = '${graceEndDate.day}/${graceEndDate.month}/${graceEndDate.year}';
      } catch (e) {
        rentalEndDateText = endDateStr.toString();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        title: const Text('Return Request'),
        backgroundColor: const Color(0xFF660033),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Order Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderId',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF660033),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Rental ends: $rentalEndDateText',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Return deadline: $graceEndDateText',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ If already requested, show status card
            if (_alreadyRequested) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getRequestStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getRequestStatusColor().withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getRequestStatusIcon(),
                      size: 48,
                      color: _getRequestStatusColor(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getRequestStatusText(_existingRequestStatus),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getRequestStatusColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getRequestStatusColor(),
                      ),
                    ),
                    if (_existingRequestStatus == 'rejected')
                      const SizedBox(height: 16),
                    if (_existingRequestStatus == 'rejected')
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please contact support at support@bridalease.com'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Contact Support'),
                      ),
                  ],
                ),
              ),
            ],

            // Return Window Card (only if not already requested)
            if (!_alreadyRequested) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: canReturn
                      ? const LinearGradient(colors: [Color(0xFF660033), Color(0xFF99004C)])
                      : const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      canReturn ? Icons.assignment_return : Icons.cancel,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      canReturn ? 'Return Window Open' : 'Return Window Closed',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    if (canReturn)
                      Text(
                        _getDaysLeftDisplay(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      statusMessage,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Return Reason Selection (only if return is allowed AND not already requested)
            if (canReturn && !_alreadyRequested) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason for Return',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._returnReasons.map((reason) => RadioListTile<String>(
                      value: reason,
                      groupValue: _selectedReason,
                      onChanged: (value) => setState(() => _selectedReason = value),
                      title: Text(reason),
                      activeColor: const Color(0xFF660033),
                      contentPadding: EdgeInsets.zero,
                    )),
                    if (_selectedReason == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: TextField(
                          controller: _otherReasonController,
                          decoration: InputDecoration(
                            hintText: 'Please specify',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          maxLines: 2,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Once you submit, the vendor will inspect the dress. You will be notified once inspection is complete.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReturnRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF660033),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Return Request',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],

            // Return Closed Message (if window closed and not requested)
            if (!canReturn && !_alreadyRequested)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cancel, size: 48, color: Colors.red.shade700),
                    const SizedBox(height: 12),
                    Text(
                      'Return Window Has Been Closed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can no longer request a return for this order. Please contact customer support for assistance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Helper method to get status text
  String _getRequestStatusText(String? status) {
    switch (status) {
      case 'pending_inspection':
        return 'PENDING INSPECTION';
      case 'pending_approval':
        return 'PENDING APPROVAL';
      case 'approved':
        return 'APPROVED';
      case 'completed':
        return 'COMPLETED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'REQUEST SUBMITTED';
    }
  }
}