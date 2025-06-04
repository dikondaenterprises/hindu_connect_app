import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _auth = FirebaseAuth.instance;
  final _emailCtrl = TextEditingController();
  bool _sent = false, _loading = false;

  Future<void> _sendReset() async {
    if (_emailCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email address')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.sendPasswordResetEmail(email: _emailCtrl.text.trim());

      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_sent) ...[
                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _sendReset,
                      child: const Text('Send Reset Link'),
                    ),
                  ] else
                    const Text(
                      'Password reset email sent.\nPlease check your inbox.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }
}
