import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/auth/verify_page.dart';
import 'package:food_app/providers/auth_providers.dart';

class VerificationDialog {
  static void showVerificationRequiredDialog(BuildContext context, Map<String, dynamic> userData, WidgetRef ref) {
    final status = userData['status']?.toString() ?? 'unverified';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600).withOpacity(0.1), // accentYellow with opacity
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_outlined,
                color: const Color(0xFFCFC000), // primaryYellow
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Account Verification Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF000000), // black
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account needs to be verified to place orders and access all features.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF666666), // greyText
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600).withOpacity(0.1), // accentYellow with opacity
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCFC000).withOpacity(0.2)), // primaryYellow with opacity
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFFCFC000), // primaryYellow
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current Status: ${status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000), // black
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Verification helps ensure the security of your account and enables:',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF666666), // greyText
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Place orders and make payments'),
            _buildFeatureItem('Access order history'),
            _buildFeatureItem('Contact delivery partners'),
            _buildFeatureItem('Use all app features'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Verify Later',
              style: TextStyle(color: const Color(0xFF666666)), // greyText
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPhoneVerificationDialog(context, userData, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC63232), // secondaryRed
              foregroundColor: const Color(0xFFFFFFFF), // white
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );
  }

  static void _showPhoneVerificationDialog(BuildContext context, Map<String, dynamic> userData, WidgetRef ref) {
    final currentPhone = userData['number_phone'] ?? '';
    final userId = userData['id'];
    
    showDialog(
      context: context,
      builder: (context) => _PhoneVerificationDialog(
        currentPhone: currentPhone,
        onVerify: (newPhone) async {
          if (newPhone.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number is required')),
            );
            return false;
          }

          try {
            // ✅ FIXED: Always use the provider to send verification code
            final result = await ref.read(verifyFirebaseTokenProvider(newPhone as Map<String, dynamic>).future);
            
            if (result['success'] == true) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerifyPage(
                    flowType: 'phone_change',
                    phoneNumber: newPhone,
                    userId: userId,
                  ),
                ),
              );
              return true;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to send verification code'),
                  backgroundColor: const Color(0xFFC63232), // secondaryRed
                ),
              );
              return false;
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start verification: $e'),
                backgroundColor: const Color(0xFFC63232), // secondaryRed
              ),
            );
            return false;
          }
        },
      ),
    );
  }

  static Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFFCFC000), // primaryYellow
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF666666), // greyText
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneVerificationDialog extends StatefulWidget {
  final String currentPhone;
  final Future<bool> Function(String newPhone) onVerify;

  const _PhoneVerificationDialog({
    required this.currentPhone,
    required this.onVerify,
  });

  @override
  State<_PhoneVerificationDialog> createState() => _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<_PhoneVerificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onVerify(_phoneController.text.trim());

      if (success && mounted) {
        // Navigation is handled in the parent
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Verification',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000000), // black
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${'Current'}: ${widget.currentPhone}',
                style: TextStyle(
                  color: const Color(0xFF666666), // greyText
                ),
              ),
              const SizedBox(height: 20),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'New Phone Number',
                  labelStyle: TextStyle(color: const Color(0xFF666666)), // greyText
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFFF0F0F0)), // lightGrey
                  ),
                  prefixIcon: Icon(Icons.phone, color: const Color(0xFF666666)), // greyText
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: const Color(0xFF666666)), // greyText
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC63232), // secondaryRed
                        foregroundColor: const Color(0xFFFFFFFF), // white
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFFFFF), // white
                              ),
                            )
                          : const Text('Send Code'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}