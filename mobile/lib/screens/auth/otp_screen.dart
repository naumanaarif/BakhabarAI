import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import '../../core/theme.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final Function(String name) onAuthenticated;

  const OtpScreen({
    Key? key,
    this.phoneNumber = '+92 300 XXXXXXX',
    required this.verificationId,
    required this.onAuthenticated,
  }) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyOtp(String code) async {
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() => _isLoading = false);

      if (mounted) {
        _showNameInputDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Invalid OTP code.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  void _showNameInputDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Welcome to BakhabarAI',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter your name to register:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Ahmed Ali',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: AppColors.primary.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your name.'),
                          backgroundColor: AppColors.dangerRed,
                        ),
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    widget.onAuthenticated(name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 46,
      height: 54,
      textStyle: AppTextStyles.h1.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.accent, width: 2),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Header Text
          Text(
            'Enter Verification Code',
            style: AppTextStyles.h1.copyWith(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 26,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sent to ${widget.phoneNumber}',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Pinput Widget
          Pinput(
            length: 6,
            controller: _pinController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            onCompleted: (pin) => _verifyOtp(pin),
          ),
          const SizedBox(height: 48),

          // Action Buttons
          SizedBox(
            width: 200,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _verifyOtp(_pinController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.accent.withOpacity(0.3),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Verify',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: Text(
              'Resend OTP',
              style: AppTextStyles.body.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
