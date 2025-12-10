import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/pages/auth/forgot_password_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:easy_localization/easy_localization.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key}); // Remove the required callbacks

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final passwordData = {
        'current_password': _currentPasswordController.text,
        'new_password': _newPasswordController.text,
        'confirm_password': _confirmPasswordController.text,
      };
       
      final result = await ref.read(changePasswordProvider(passwordData).future);
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'delivery_profile_page.password_changed'.tr()),
              backgroundColor: const Color(0xFFCFC000), // primaryYellow
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context); // Go back to profile page
        }
      } else {
        final errorMessage = result['message'] ?? 'delivery_profile_page.password_change_failed'.tr();
        
        setState(() {
          _errorMessage = errorMessage;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: const Color(0xFFC63232), // secondaryRed
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Change password error: $e');
      
      final errorMessage = 'delivery_profile_page.password_change_error'.tr();
      
      setState(() {
        _errorMessage = errorMessage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFC63232), // secondaryRed
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'delivery_profile_page.confirm_password_required'.tr();
    }
    if (value != _newPasswordController.text) {
      return 'delivery_profile_page.passwords_not_match'.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFC63232)), // secondaryRed
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'delivery_profile_page.change_password'.tr(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'delivery_profile_page.change_password'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'delivery_profile_page.change_password_description'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666), // greyText
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Error Message Display
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC63232).withOpacity(0.1), // secondaryRed with opacity
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC63232)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFC63232)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFC63232),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage != null) const SizedBox(height: 20),

                // Current Password Field
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'delivery_profile_page.current_password'.tr(),
                    labelStyle: const TextStyle(color: Color(0xFF666666)), // greyText
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF0F0F0)), // lightGrey
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCFC000)), // primaryYellow
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF666666)), // greyText
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF666666), // greyText
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8), // greyBg
                  ),
                  obscureText: _obscureCurrentPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'delivery_profile_page.current_password_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // New Password Field
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'delivery_profile_page.new_password'.tr(),
                    labelStyle: const TextStyle(color: Color(0xFF666666)), // greyText
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF0F0F0)), // lightGrey
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCFC000)), // primaryYellow
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF666666)), // greyText
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF666666), // greyText
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8), // greyBg
                  ),
                  obscureText: _obscureNewPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'delivery_profile_page.new_password_required'.tr();
                    }
                    if (value.length < 8) {
                      return 'delivery_profile_page.password_min_length'.tr();
                    }
                  
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'delivery_profile_page.password_hint'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666), // greyText
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'delivery_profile_page.confirm_password'.tr(),
                    labelStyle: const TextStyle(color: Color(0xFF666666)), // greyText
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF0F0F0)), // lightGrey
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCFC000)), // primaryYellow
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF666666)), // greyText
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF666666), // greyText
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8), // greyBg
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 32),

                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCFC000), // primaryYellow
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFFCFC000).withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            'delivery_profile_page.change_password_button'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Forgot Password Link
                Center(
                  child: TextButton(
                    onPressed: _navigateToForgotPassword,
                    child: Text(
                      'delivery_profile_page.forgot_password'.tr(),
                      style: const TextStyle(
                        color: Color(0xFFC63232), // secondaryRed
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                

              ],
            ),
          ),
        ),
      ),
    );
  }

}