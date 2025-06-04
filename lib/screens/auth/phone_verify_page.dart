import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerifyPage extends StatefulWidget {
  const PhoneVerifyPage({super.key});
  @override
  State<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  final _auth = FirebaseAuth.instance;
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String? _verificationId;
  bool _loading = false;

  Future<void> _sendCode() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneCtrl.text.trim(),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        try {
          await _auth.signInWithCredential(cred);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Auto-verification failed: ${e.toString()}')),
            );
          }
        }
      },
      verificationFailed: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verification failed')),
        );
        setState(() => _loading = false);
      },
      codeSent: (id, _) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _loading = false;
        });
      },
      codeAutoRetrievalTimeout: (id) {
        _verificationId = id;
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null || _otpCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the OTP')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await _auth.signInWithCredential(cred);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Verification')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _phoneCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _sendCode,
                    child: const Text('Send OTP'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpCtrl,
                    decoration: const InputDecoration(labelText: 'Enter OTP'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _verifyCode,
                    child: const Text('Verify & Login'),
                  ),
                ],
              ),
            ),
    );
  }
}
