import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/auth/change_password_page.dart';
import 'package:food_app/pages/auth/change_phone_page.dart';
import 'package:food_app/pages/auth/forgot_password_page.dart';
import 'package:food_app/pages/auth/verify_page.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/delivery_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

class ProfileDialogs {
  static void showUpdateProfileDialog(BuildContext context, Map<String, dynamic> userData, WidgetRef ref) {
    final user = userData['data'] ?? {};
    final deliveryDriver = user['delivery_driver'] ?? {};
    
    showDialog(
      context: context,
      builder: (context) => _UpdateProfileDialog(
        currentName: user['name'] ?? '',
        currentAvatar: deliveryDriver['avatar'],
        onSave: (name, avatar) async {
          if (name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('delivery_profile_page.name_required'.tr())),
            );
            return false;
          }

          try {
            final profileData = {
              'name': name,
              if (avatar != null) 'avatar': avatar,
            };

            final result = await ref.read(updateDeliveryProfileProvider(profileData).future);
            
            if (result['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'delivery_profile_page.profile_updated'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
              return true;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'delivery_profile_page.update_failed'.tr()),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('delivery_profile_page.update_error'.tr()),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        },
      ),
    );
  }

  static void navigateToChangePasswordPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
  }

// In profile_dialogs.dart, update the showChangePhoneDialog method:
static void showChangePhoneDialog(BuildContext context, Map<String, dynamic> user, WidgetRef ref) {
  final currentPhone = user['number_phone'] ?? '';
  final userId = user['id'] as int? ?? 0;
  
  // Navigate to dedicated ChangePhonePage
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChangePhonePage(
        userId: userId,
        currentPhone: currentPhone.toString(),
        userRole: 'delivery_driver',

      ),
    ),
  );
}


 
  static void showForgotPasswordDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  static void showLanguageDialog(BuildContext context) {
    final currentLocale = context.locale;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.language'.tr()),
        content: Text('delivery_profile_page.change_app_language'.tr()),
        actions: [
          _buildLanguageOption('العربية', const Locale('ar'), currentLocale, context),
          _buildLanguageOption('English', const Locale('en'), currentLocale, context),
          _buildLanguageOption('Français', const Locale('fr'), currentLocale, context),
        ],
      ),
    );
  }

  static Widget _buildLanguageOption(String languageName, Locale locale, Locale currentLocale, BuildContext context) {
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      title: Text(languageName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.deepOrange) : null,
      onTap: () async {
        await context.setLocale(locale);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('locale', locale.languageCode);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.language_changed_to'.tr()} $languageName'),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  static void showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.contact_support'.tr()),
        content: Text('${'delivery_profile_page.customer_support'.tr()}\nEmail: support@foodapp.com\nPhone: +212 522 123 456'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  static void showFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.send_feedback'.tr()),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'delivery_profile_page.feedback_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('delivery_profile_page.feedback_sent'.tr())),
              );
            },
            child: Text('delivery_profile_page.send'.tr()),
          ),
        ],
      ),
    );
  }

  static void showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.privacy_policy'.tr()),
        content: SingleChildScrollView(
          child: Text('delivery_profile_page.privacy_policy_content'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }
}

// Update Profile Dialog Class (Name & Avatar only) with camera functionality
class _UpdateProfileDialog extends StatefulWidget {
  final String currentName;
  final String? currentAvatar;
  final Future<bool> Function(String name, File? avatar) onSave;

  const _UpdateProfileDialog({
    required this.currentName,
    this.currentAvatar,
    required this.onSave,
  });

  @override
  State<_UpdateProfileDialog> createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<_UpdateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _selectedAvatar;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedAvatar = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('delivery_profile_page.image_pick_error'.tr())),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedAvatar = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('delivery_profile_page.camera_error'.tr())),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_profile_page.choose_image_source'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage();
            },
            child: Text('delivery_profile_page.gallery'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _takePhoto();
            },
            child: Text('delivery_profile_page.camera'.tr()),
          ),
        ],
      ),
    );
  }

  void _removeAvatar() {
    setState(() {
      _selectedAvatar = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onSave(
        _nameController.text.trim(),
        _selectedAvatar,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrentAvatar = widget.currentAvatar != null && widget.currentAvatar!.isNotEmpty;
    final hasSelectedAvatar = _selectedAvatar != null;

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
                'delivery_profile_page.update_profile'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Avatar Selection with camera option
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.deepOrange, width: 2),
                          ),
                          child: ClipOval(
                            child: hasSelectedAvatar
                                ? Image.file(
                                    _selectedAvatar!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : hasCurrentAvatar
                                    ? CustomNetworkImage(
                                        imageUrl: ImageHelper.getImageUrl(widget.currentAvatar!),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        placeholder: 'avatar',
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                      ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              onPressed: _showImageSourceDialog,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (hasSelectedAvatar || hasCurrentAvatar)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                onPressed: _removeAvatar,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'delivery_profile_page.avatar_optional'.tr(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'delivery_profile_page.name'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'delivery_profile_page.name_required'.tr();
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
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('common.save'.tr()),
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

// Change Password Dialog Class
class _ChangePasswordDialog extends StatefulWidget {
  final Future<bool> Function(String currentPassword, String newPassword, String confirmPassword) onChangePassword;

  const _ChangePasswordDialog({required this.onChangePassword});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onChangePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _confirmPasswordController.text,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _newPasswordController.text) {
      return 'delivery_profile_page.passwords_not_match'.tr();
    }
    return null;
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
                'delivery_profile_page.change_password'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'delivery_profile_page.current_password'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureCurrentPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'delivery_profile_page.current_password_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'delivery_profile_page.new_password'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'delivery_profile_page.new_password_required'.tr();
                  }
                  if (value.length < 6) {
                    return 'delivery_profile_page.password_min_length'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'delivery_profile_page.confirm_password'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('delivery_profile_page.change_password'.tr()),
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

// Change Phone Dialog Class
class _ChangePhoneDialog extends StatefulWidget {
  final String currentPhone;
  final Future<bool> Function(String newPhone) onChangePhone;

  const _ChangePhoneDialog({
    required this.currentPhone,
    required this.onChangePhone,
  });

  @override
  State<_ChangePhoneDialog> createState() => _ChangePhoneDialogState();
}

class _ChangePhoneDialogState extends State<_ChangePhoneDialog> {
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

  Future<void> _changePhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onChangePhone(_phoneController.text.trim());

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
                'delivery_profile_page.change_phone'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${'delivery_profile_page.current'.tr()}: ${widget.currentPhone}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'delivery_profile_page.new_phone'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'delivery_profile_page.phone_required'.tr();
                  }
                  if (value.length < 10) {
                    return 'delivery_profile_page.phone_valid'.tr();
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
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('delivery_profile_page.send_code'.tr()),
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