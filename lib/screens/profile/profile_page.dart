import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../widgets/top_bar.dart';
import '../../widgets/drawer_menu.dart';
import '../../utils/language_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '',
      _email = '',
      _phone = '',
      _lang = 'English',
      _country = 'India',
      _pincode = '';
  String _city = '', _state = '', _pincodeError = '';
  File? _avatar;
  final _picker = ImagePicker();
  final _countries = <String>['India', 'USA', 'UK'];
  final _searchController = TextEditingController();
  List<Map<String, String>> _filteredLanguages = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _filteredLanguages = LanguageUtils.allLanguages;
    _loadProfile().then((_) {
      if (_pincode.isNotEmpty) _fetchPincodeData(_pincode);
    });
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _name = prefs.getString('name') ?? '';
      _email = prefs.getString('email') ?? '';
      _phone = prefs.getString('phone') ?? '';
      _lang = prefs.getString('lang') ?? 'English';
      _country = prefs.getString('country') ?? 'India';
      _pincode = prefs.getString('pincode') ?? '';
      _city = prefs.getString('city') ?? '';
      _state = prefs.getString('state') ?? '';
    });
  }

  Future<void> _fetchPincodeData(String pincode) async {
    if (pincode.length != 6) {
      if (!mounted) return;
      setState(() {
        _city = '';
        _state = '';
        _pincodeError = 'Pincode must be 6 digits';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _pincodeError = '');

    try {
      final doc = await FirebaseFirestore.instance
          .collection('pincodes')
          .doc(pincode)
          .get();

      if (!mounted) return;
      setState(() {
        _city = doc.exists ? doc['district'] ?? '' : '';
        _state = doc.exists ? doc['state'] ?? '' : '';
        _pincodeError = doc.exists ? '' : 'Pincode not found';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _pincodeError = 'Network error. Try again.');
    }
  }

  Future<void> _saveProfile() async {
    if (_city.isEmpty || _state.isEmpty) {
      if (mounted) {
        setState(() => _pincodeError = 'Valid pincode required');
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _name);
    await prefs.setString('email', _email);
    await prefs.setString('phone', _phone);
    await prefs.setString('lang', _lang);
    await prefs.setString('country', _country);
    await prefs.setString('pincode', _pincode);
    await prefs.setString('city', _city);
    await prefs.setString('state', _state);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      maxHeight: 1024,
      maxWidth: 1024,
    );

    if (xfile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: xfile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Avatar',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      setState(() => _avatar = File(croppedFile.path));
    }
  }

  void _onLanguageSearch(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _filteredLanguages = LanguageUtils.searchLanguages(query);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Profile'),
      drawer: const DrawerMenu(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickAvatar(ImageSource.gallery),
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                child:
                    _avatar == null ? const Icon(Icons.person, size: 48) : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Full Name'),
              controller: TextEditingController(text: _name),
              onChanged: (v) => _name = v,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              controller: TextEditingController(text: _email),
              onChanged: (v) => _email = v,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              controller: TextEditingController(text: _phone),
              onChanged: (v) => _phone = v,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Pincode',
                errorText: _pincodeError.isNotEmpty ? _pincodeError : null,
              ),
              controller: TextEditingController(text: _pincode),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                _pincode = v;
                _fetchPincodeData(v);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'City'),
              controller: TextEditingController(text: _city),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'State'),
              controller: TextEditingController(text: _state),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Languages',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onLanguageSearch('');
                  },
                ),
              ),
              onChanged: _onLanguageSearch,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Content Language'),
              value: _lang,
              items: _filteredLanguages
                  .map((lang) => DropdownMenuItem(
                        value: lang['name'],
                        child: Text(lang['name']!),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _lang = value!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Country'),
              value: _country,
              items: _countries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _country = v!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
