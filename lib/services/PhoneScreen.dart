import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_app/services/OtpScreen.dart';

class ProductionPhoneAuth extends StatefulWidget {
  @override
  State<ProductionPhoneAuth> createState() => _ProductionPhoneAuthState();
}

class _ProductionPhoneAuthState extends State<ProductionPhoneAuth> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController phoneController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Configure for production
    _configureFirebaseForProduction();
  }

  Future<void> _configureFirebaseForProduction() async {
    await _auth.setSettings(
      appVerificationDisabledForTesting: false, // IMPORTANT: false for production
      forceRecaptchaFlow: false, // Let Firebase decide
    );
  }

  String _formatMoroccanPhone(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // Moroccan phone number logic
    if (digits.startsWith('0')) {
      // Remove leading 0 and add +212
      digits = digits.substring(1);
    }
    
    // Should be 9 digits after +212
    if (digits.length == 9) {
      return '+212$digits';
    }
    
    // If already has country code
    if (digits.startsWith('212')) {
      return '+$digits';
    }
    
    // Return as is if we can't format
    return phone;
  }

  Future<void> sendVerificationCode() async {
    String phone = phoneController.text.trim();
    
    if (phone.isEmpty) {
      _showSnackBar('Please enter a phone number');
      return;
    }

    // Format for Morocco
    String formattedPhone = _formatMoroccanPhone(phone);
    
    // Validate Moroccan phone format
    if (!formattedPhone.startsWith('+212') || formattedPhone.length != 13) {
      _showSnackBar('Please enter a valid Moroccan phone number (e.g., 0612345678)');
      return;
    }

    setState(() => loading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Auto-verification successful');
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.code} - ${e.message}');
          setState(() => loading = false);
          
          String errorMessage = _getErrorMessage(e.code);
          _showSnackBar(errorMessage);
          
          // Log the error for debugging
          print('Phone: $formattedPhone, Error: ${e.code}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent to $formattedPhone');
          setState(() => loading = false);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                verificationId: verificationId,
                phoneNumber: formattedPhone,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto-retrieval timeout');
          setState(() => loading = false);
        },
      );
    } catch (e) {
      setState(() => loading = false);
      print('General error: $e');
      _showSnackBar('An error occurred. Please try again.');
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use format: 0612345678 or +212612345678';
      case 'too-many-requests':
        return 'Too many attempts. Try again in 24 hours';
      case 'quota-exceeded':
        return 'Daily SMS limit reached. Try again tomorrow';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Contact support';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Try again';
      case 'missing-client-identifier':
        return 'App not configured properly. Check SHA fingerprints in Firebase';
      default:
        return 'Verification failed. Please try again';
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user != null) {
        print('User signed in: ${user.uid}');
        
        // Navigate to home
        //snackpar
        _showSnackBar('Phone number verified successfully!');
      }
    } catch (e) {
      print('Sign in error: $e');
      _showSnackBar('Invalid verification code');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Verify Your Phone",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Enter your Moroccan phone number to receive a verification code",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          
          // Phone Input
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              hintText: "0612345678",
              prefixText: "+212 ",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
            ),
          ),
          
          SizedBox(height: 12),
          Text(
            "Enter your number without the leading 0 (e.g., 612345678)",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Send Code Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: loading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC63232)),
                    ),
                  )
                : ElevatedButton(
                    onPressed: sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC63232),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Send Verification Code",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}