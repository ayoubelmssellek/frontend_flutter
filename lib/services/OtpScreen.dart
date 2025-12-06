import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;
  final Function? onResendCode;

  const OtpScreen({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
    this.onResendCode,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool loading = false;
  int countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startCountdown();
    
    // Auto-focus first field
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void startCountdown() {
    countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() => countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      showSnackBar('Please enter a 6-digit code');
      return;
    }

    setState(() => loading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Success - navigate to home
       //sneckpar
      showSnackBar('Phone number verified successfully!');
      
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      
      if (e.code == 'invalid-verification-code') {
        showSnackBar('Invalid verification code');
        // Clear all fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        showSnackBar('Verification failed: ${e.message}');
      }
    } catch (e) {
      setState(() => loading = false);
      showSnackBar('An error occurred: $e');
    }
  }

  void onResendCode() {
    if (countdown == 0 && widget.onResendCode != null) {
      widget.onResendCode!();
      startCountdown();
      showSnackBar('New code sent');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-digit code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Sent to ${widget.phoneNumber}',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return Container(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      
                      // Auto-submit when all fields are filled
                      if (index == 5 && value.isNotEmpty) {
                        String fullOtp = _controllers.map((c) => c.text).join();
                        if (fullOtp.length == 6) {
                          verifyOtp();
                        }
                      }
                    },
                  ),
                );
              }),
            ),
            
            SizedBox(height: 32),
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(0xFFC63232),
                      ),
                      child: Text(
                        'Verify',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),
            
            SizedBox(height: 20),
            
            // Resend Code
            Center(
              child: countdown > 0
                  ? Text(
                      'Resend code in $countdown seconds',
                      style: TextStyle(color: Colors.grey),
                    )
                  : TextButton(
                      onPressed: onResendCode,
                      child: Text(
                        'Resend Code',
                        style: TextStyle(color: Color(0xFFC63232)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}