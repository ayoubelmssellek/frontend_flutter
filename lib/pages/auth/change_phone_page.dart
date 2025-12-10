import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/core/firebase_auth_service.dart';
import 'package:food_app/pages/auth/verify_page.dart';
import 'package:food_app/core/secure_storage.dart';
import 'package:food_app/providers/auth_providers.dart';

// Color Palette from Logo
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

class ChangePhonePage extends ConsumerStatefulWidget {
  final int userId;
  final String currentPhone;
  final String userRole;

  const ChangePhonePage({
    super.key,
    required this.userId,
    required this.currentPhone,
    required this.userRole,
  });

  @override
  ConsumerState<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends ConsumerState<ChangePhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentPhone;
    
    print('🔍 ChangePhonePage Debug:');
    print('🔍 User ID: ${widget.userId}');
    print('🔍 Widget currentPhone: ${widget.currentPhone}');
    print('🔍 User Role: ${widget.userRole}');
    
    // Get actual current phone from API
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final userResult = await ref.refresh(currentUserProvider.future);
        if (userResult['success'] == true && userResult['data'] != null) {
          final userData = userResult['data'];
          final apiPhone = userData['number_phone']?.toString();
          print('🔍 API currentPhone: $apiPhone');
          
          if (apiPhone != null && apiPhone != widget.currentPhone) {
            print('⚠️ WARNING: Widget phone (${widget.currentPhone}) != API phone ($apiPhone)');
            // Update the controller with the correct phone
            if (mounted) {
              setState(() {
                _phoneController.text = apiPhone;
              });
            }
          }
        }
      } catch (e) {
        print('❌ Error fetching user data: $e');
      }
      
      FirebaseAuthService.clearData();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _checkTokenBeforeAction() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        _showSessionExpiredDialog();
        return false;
      }
      return true;
    } catch (e) {
      _showSessionExpiredDialog();
      return false;
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('change_phone_page.session_expired'.tr()),
        content: Text('change_phone_page.session_expired_message'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }
Future<void> _sendVerificationCode() async {
  if (!_formKey.currentState!.validate()) return;

  final newPhone = _phoneController.text.trim();
  
  // Remove any non-numeric characters
  final cleanPhone = newPhone.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Get the ACTUAL current phone from user data
  String actualCurrentPhone = widget.currentPhone;
  
  // Fetch current user data to get the correct phone
  try {
    final userResult = await ref.read(currentUserProvider.future);
    if (userResult['success'] == true && userResult['data'] != null) {
      final userData = userResult['data'];
      actualCurrentPhone = userData['number_phone']?.toString() ?? widget.currentPhone;
      print('📱 Actual current phone from API: $actualCurrentPhone');
    }
  } catch (e) {
    print('❌ Error fetching user data: $e');
  }
  
  // Clean the actual current phone
  final cleanCurrentPhone = actualCurrentPhone.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Check if phone is same as current
  if (cleanPhone == cleanCurrentPhone) {
    setState(() {
      _errorMessage = 'change_phone_page.phone_same'.tr();
    });
    
    // Show snackbar message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('change_phone_page.phone_same'.tr()),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return;
  }

  // Check token before proceeding
  if (!await _checkTokenBeforeAction()) {
    return;
  }

  // Set loading state BEFORE async operations
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  // Try to check if phone exists (optional step)
  bool phoneExists = false;
  try {
    print('🔍 Checking if phone exists: $cleanPhone');
    final checkResult = await ref.read(checkPhoneProvider(cleanPhone).future);
    phoneExists = checkResult['exists'] == true;
  } catch (e) {
    print('⚠️ Phone check failed, continuing with verification: $e');
    // Continue with verification even if check fails
  }

  // If phone already exists, show error and return
  if (phoneExists) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('change_phone_page.phone_exists'.tr()),
          backgroundColor: secondaryRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    setState(() => _isLoading = false);
    return;
  }

  // Main OTP sending logic
  try {
    // Format phone for Firebase
    String formattedPhoneForFirebase;
    if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
      formattedPhoneForFirebase = '+212${cleanPhone.substring(1)}';
    } else if (cleanPhone.length == 9) {
      formattedPhoneForFirebase = '+212$cleanPhone';
    } else if (cleanPhone.startsWith('212') && cleanPhone.length == 12) {
      formattedPhoneForFirebase = '+$cleanPhone';
    } else {
      formattedPhoneForFirebase = '+212$cleanPhone';
    }

    print('📱 Sending OTP to new phone: $formattedPhoneForFirebase');
    print('📱 Current phone (clean): $cleanCurrentPhone');
    print('📱 New phone (clean): $cleanPhone');
    
    FirebaseAuthService.clearData();
    await FirebaseAuthService.sendOTP(phoneNumber: formattedPhoneForFirebase);
    
    // Navigate to VerifyPage with ACTUAL current phone
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyPage(
            flowType: 'change_phone',
            phoneNumber: cleanPhone,
            oldPhoneNumber: cleanCurrentPhone, // Use the ACTUAL current phone
            userId: widget.userId,
            userRole: widget.userRole,
          ),
        ),
      );
    }
    
  } catch (e) {
    _handleSendOTPError(e);
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

// Separate method for error handling
void _handleSendOTPError(dynamic e) {
  print('❌ Send OTP error: $e');
  
  String errorMsg = FirebaseAuthService.extractErrorMessage(e.toString());
  
  if (errorMsg.toLowerCase().contains('token')) {
    setState(() => _errorMessage = 'change_phone_page.session_expired'.tr());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSessionExpiredDialog();
    });
    return;
  }
  
  if (errorMsg.contains('invalid') || errorMsg.contains('غير صحيح')) {
    setState(() => _errorMessage = 'change_phone_page.phone_invalid'.tr());
  } else if (errorMsg.contains('quota') || errorMsg.contains('exceeded')) {
    setState(() => _errorMessage = 'change_phone_page.quota_exceeded'.tr());
  } else if (errorMsg.contains('network')) {
    setState(() => _errorMessage = 'change_phone_page.network_error'.tr());
  } else {
    setState(() => _errorMessage = 'change_phone_page.send_error'.tr());
  }
  
  // Show error message in snackbar too
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: secondaryRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: primaryYellow,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'change_phone_page.title'.tr(),
          style: TextStyle(
            color: black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header with icon
              Row(
                children: [
                  Icon(
                    Icons.phone_android,
                    color: primaryYellow,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'change_phone_page.title'.tr(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: black,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'change_phone_page.description'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: greyText,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Current Phone Info with role badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryYellow.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryYellow.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryYellow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleDisplayName(),
                            style: TextStyle(
                              color: white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.phone,
                          color: primaryYellow,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'change_phone_page.current_phone'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: greyText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _phoneController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryYellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'change_phone_page.new_phone'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: black,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: 'change_phone_page.new_phone_hint'.tr(),
                        hintStyle: TextStyle(
                          color: lightGrey,
                        ),
                        prefixIcon: Icon(Icons.phone_android, color: primaryYellow),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: lightGrey,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryYellow,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'change_phone_page.phone_required'.tr();
                        }
                        
                        final phone = value.trim();
                        
                        // Moroccan phone number validation (starts with 06 or 07)
                        if (!phone.startsWith('06') && !phone.startsWith('07')) {
                          return 'change_phone_page.phone_invalid'.tr();
                        }
                        
                        if (phone.length != 10) {
                          return 'change_phone_page.phone_length'.tr();
                        }
                        
                        return null;
                      },
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: secondaryRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _sendVerificationCode,
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation(white),
                                ),
                              )
                            : Text(
                                'change_phone_page.send_code'.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: white,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: primaryYellow,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'change_phone_page.cancel'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryYellow,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
 
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName() {
    switch (widget.userRole) {
      case 'admin':
        return 'admin_profile_page.role_admin'.tr();
      case 'delivery_driver':
        return 'delivery_profile_page.delivery_driver'.tr();
      case 'admin_delivery_driver':
        return 'admin_profile_page.role_admin_delivery_driver'.tr();
      case 'client':
        return 'client_profile_page.client'.tr();
      default:
        return 'client_profile_page.client'.tr();
    }
  }
}