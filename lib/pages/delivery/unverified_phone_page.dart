// unverified_phone_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/pages/auth/verify_page.dart';
import 'package:food_app/providers/auth_providers.dart';

class UnverifiedPhonePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onVerified;

  const UnverifiedPhonePage({
    super.key,
    required this.userData,
    required this.onVerified,
  });

  @override
  ConsumerState<UnverifiedPhonePage> createState() =>
      _UnverifiedPhonePageState();
}

class _UnverifiedPhonePageState extends ConsumerState<UnverifiedPhonePage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _useCurrentNumber = true;

  @override
  void initState() {
    super.initState();
    // Set current phone number
    final userDataMap = widget.userData['data'] as Map<String, dynamic>?;
    final currentPhone = userDataMap?['number_phone']?.toString() ?? '';
    _phoneController.text = currentPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('unverified_phone_page.enter_phone'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(
        changePhoneNumberProvider(_phoneController.text.trim()).future,
      );

      if (result['success'] == true) {
        // ✅ CHECK WHATSAPP STATUS LIKE IN REGISTRATION
        final whatsappStatus = result['whatsapp_status']
            ?.toString()
            .toLowerCase();
        print('📱 WhatsApp Status from update: $whatsappStatus');

        if (whatsappStatus == 'failed') {
          // ❌ WhatsApp failed - show success message and continue
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ??
                      'unverified_phone_page.phone_updated'.tr(),
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            widget.onVerified();
          }
        } else {
          // ✅ WhatsApp success - navigate to verify code page
          if (mounted) {
            final userDataMap =
                widget.userData['data'] as Map<String, dynamic>?;
            final userId = userDataMap?['id'] as int?;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => VerifyPage(
                  phoneNumber: _phoneController.text.trim(),
                  userType: 'delivery_driver',
                  userId: userId,
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'unverified_phone_page.failed_update_phone'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataMap = widget.userData['data'] as Map<String, dynamic>?;
    final currentPhone = userDataMap?['number_phone']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('unverified_phone_page.phone_verification_required'.tr()),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.phone_android, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'unverified_phone_page.phone_verification_required'.tr(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'unverified_phone_page.verification_needed_desc'.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'unverified_phone_page.current_phone_on_file'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                currentPhone.isNotEmpty
                    ? currentPhone
                    : 'unverified_phone_page.no_phone_number'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Checkbox(
                  value: _useCurrentNumber,
                  onChanged: (value) {
                    setState(() {
                      _useCurrentNumber = value ?? true;
                      if (_useCurrentNumber) {
                        _phoneController.text = currentPhone;
                      } else {
                        _phoneController.clear();
                      }
                    });
                  },
                ),
                Text(
                  'unverified_phone_page.use_current_number'.tr(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            if (!_useCurrentNumber) ...[
              const SizedBox(height: 16),
              Text(
                'unverified_phone_page.enter_new_phone'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'unverified_phone_page.enter_phone_hint'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'unverified_phone_page.verification_code_message'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPhoneNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'unverified_phone_page.verify_phone_button'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
