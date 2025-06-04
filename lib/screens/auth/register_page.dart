import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/language_utils.dart'; // For language list

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String? _contentLang;
  bool _loading = false;
  String _city = '';
  String _state = '';
  String _pincodeError = '';

  // Fetch district/state from Firestore
  Future<void> _fetchPincodeData(String pincode) async {
    if (pincode.length != 6) {
      if (mounted) {
        setState(() {
          _city = '';
          _state = '';
          _pincodeError = 'Pincode must be 6 digits';
        });
      }
      return;
    }

    if (mounted) setState(() => _pincodeError = '');

    try {
      final doc = await _db.collection('pincodes').doc(pincode).get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          _city = doc['district'] ?? '';
          _state = doc['state'] ?? '';
          _pincodeError = _city.isEmpty ? 'Invalid pincode data' : '';
        });
      } else {
        setState(() {
          _city = '';
          _state = '';
          _pincodeError = 'Pincode not found';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pincodeError = 'Network error. Try again.');
    }
  }

  Future<void> _register() async {
    if (_city.isEmpty || _state.isEmpty) {
      if (mounted) setState(() => _pincodeError = 'Valid pincode required');
      return;
    }

    if (mounted) setState(() => _loading = true);
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      await _db.collection('users').doc(userCred.user!.uid).set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'pincode': _pinCtrl.text.trim(),
        'city': _city,
        'state': _state,
        'contentLang': _contentLang,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _pincodeError = e.message ?? 'Registration failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pincodeError = 'An unexpected error occurred');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _pinCtrl,
              decoration: InputDecoration(
                labelText: 'Pincode',
                errorText: _pincodeError.isNotEmpty ? _pincodeError : null,
              ),
              keyboardType: TextInputType.number,
              onChanged: _fetchPincodeData,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'City'),
              controller: TextEditingController(text: _city),
              readOnly: true,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'State'),
              controller: TextEditingController(text: _state),
              readOnly: true,
            ),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Content Language'),
              value: _contentLang,
              items: LanguageUtils.allLanguages
                  .map((lang) => DropdownMenuItem(
                        value: lang['name'],
                        child: Text(lang['name']!),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _contentLang = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }
}
