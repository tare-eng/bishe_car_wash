import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class PaymentVerificationDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onSuccess;

  const PaymentVerificationDialog({
    super.key,
    required this.booking,
    required this.onSuccess,
  });

  @override
  State<PaymentVerificationDialog> createState() =>
      _PaymentVerificationDialogState();
}

class _PaymentVerificationDialogState extends State<PaymentVerificationDialog> {
  String _selectedPaymentMethod = 'telebirr';
  final _refController = TextEditingController();
  XFile? _pickedImage;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickScreenshot() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _processPayment() async {
    final double amount = (widget.booking['total_amount'] ?? 0.0) as double;
    final String plate =
        widget.booking['vehicles']?['license_plate'] ?? 'UNKNOWN';

    if (_selectedPaymentMethod != 'cash' &&
        _refController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter Transaction Ref / SMS Ref Number')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;

      if (_pickedImage != null) {
        final fileExt = _pickedImage!.path.split('.').last;
        final fileName =
            'payments/${widget.booking['id']}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await Supabase.instance.client.storage
            .from('payment_proofs')
            .upload(fileName, File(_pickedImage!.path));

        imageUrl = Supabase.instance.client.storage
            .from('payment_proofs')
            .getPublicUrl(fileName);
      }

      await Supabase.instance.client.from('bookings').update({
        'payment_status': 'paid',
        'status': 'completed',
        'payment_method': _selectedPaymentMethod,
        'transaction_ref': _refController.text.trim(),
        'payment_proof_url': imageUrl,
      }).eq('id', widget.booking['id']);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          content: Text('Payment verified for $plate ($amount ETB)!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.booking['vehicles'] ?? {};
    final double totalAmount =
        (widget.booking['total_amount'] ?? 0.0) as double;

    return AlertDialog(
      title: Text(
        'Verify Payment: ${vehicle['license_plate'] ?? 'Vehicle'}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${widget.booking['owner_name'] ?? 'N/A'}'),
            Text(
              'Amount Due: $totalAmount ETB',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue),
            ),
            const Divider(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Select Payment Channel',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'cash', child: Text('Cash (Physical Handover)')),
                DropdownMenuItem(
                    value: 'telebirr', child: Text('Telebirr Direct')),
                DropdownMenuItem(
                    value: 'cbe_birr', child: Text('CBE / CBE Birr')),
                DropdownMenuItem(
                    value: 'coop_bank', child: Text('Coop Bank of Oromia')),
                DropdownMenuItem(
                    value: 'awash_bank', child: Text('Awash Bank')),
                DropdownMenuItem(
                    value: 'abyssinia_bank', child: Text('Bank of Abyssinia')),
              ],
              onChanged: (val) =>
                  setState(() => _selectedPaymentMethod = val ?? 'cash'),
            ),
            const SizedBox(height: 12),
            if (_selectedPaymentMethod != 'cash') ...[
              TextField(
                controller: _refController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Ref / SMS Code',
                  hintText: 'e.g. DET1234567 or Bank Ref',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickScreenshot,
                icon: const Icon(Icons.add_a_photo),
                label: Text(_pickedImage == null
                    ? 'Attach Payment Screenshot'
                    : 'Change Screenshot'),
              ),
              if (_pickedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(
                    File(_pickedImage!.path),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: _isUploading ? null : _processPayment,
          child: _isUploading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Confirm & Mark Paid'),
        ),
      ],
    );
  }
}
