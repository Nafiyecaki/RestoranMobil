import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final User user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);

  late final TextEditingController _adiController;
  late final TextEditingController _soyadiController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _adiController = TextEditingController(text: widget.user.uyeAdi ?? '');
    _soyadiController = TextEditingController(
      text: widget.user.uyeSoyadi ?? '',
    );
    _emailController = TextEditingController(text: widget.user.uyeEmail ?? '');
    _telefonController = TextEditingController(
      text: widget.user.uyeTelefon ?? '',
    );
  }

  @override
  void dispose() {
    _adiController.dispose();
    _soyadiController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final adi = _adiController.text.trim();
    final soyadi = _soyadiController.text.trim();
    final telefon = _telefonController.text.trim();

    if (adi.isEmpty || soyadi.isEmpty || telefon.isEmpty) {
      _showSnackBar(
        'Lutfen ad, soyad ve telefon alanlarini doldurun',
        Colors.orange,
      );
      return;
    }

    final cleanedPhone = telefon.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanedPhone.length < 10) {
      _showSnackBar('Telefon numarasi gecerli gorunmuyor', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await ApiService.updateProfile(
        adi: adi,
        soyadi: soyadi,
        telefon: telefon,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isSaving = false);
        _showSnackBar(result['message'] ?? 'Profil guncellenemedi', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('Profil guncellenirken hata olustu: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Duzenle'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bilgilerini guncelle. E-posta adresi su an sadece goruntulenir.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 18),
              _formField(
                controller: _adiController,
                label: 'Ad',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _formField(
                controller: _soyadiController,
                label: 'Soyad',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _formField(
                controller: _emailController,
                label: 'E-posta',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
                helperText: 'E-posta degisikligi bu surumde kapali',
              ),
              const SizedBox(height: 12),
              _formField(
                controller: _telefonController,
                label: 'Telefon',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF5F7F5) : Colors.white,
        prefixIcon: Icon(icon, size: 20, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.6),
        ),
      ),
    );
  }
}
