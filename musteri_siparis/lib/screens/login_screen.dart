// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/sepet_provider.dart';
import '../services/api_service.dart';
import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kullaniciAdiController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _beniHatirla = false;
  String? _errorMessage;

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _secondaryColor = Color(0xFF66BB6A);
  static const Color _accentColor = Color(0xFF1B5E20);

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.login(
        kullaniciAdi: _kullaniciAdiController.text.trim(),
        sifre: _sifreController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] ?? {};
        final nestedData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : const <String, dynamic>{};

        // 🔥 ROL BELİRLEME (Web'deki gibi)
        String userRole = (data['rol'] ?? data['Rol'] ?? data['role'] ?? '')
            .toLowerCase()
            .trim();

        // 🔥 ROL EŞLEME
        final Map<String, String> roleMapping = {
          'admin': 'admin',
          'administrator': 'admin',
          'yönetici': 'admin',
          'yonetici': 'admin',
          'superadmin': 'admin',
          'garson': 'garson',
          'waiter': 'garson',
          'servis': 'garson',
          'komi': 'garson',
          'aşçı': 'asci',
          'asci': 'asci',
          'asçı': 'asci',
          'ascı': 'asci',
          'cook': 'asci',
          'chef': 'asci',
          'mutfak': 'asci',
          'şef': 'asci',
          'kurye': 'kurye',
          'courier': 'kurye',
          'delivery': 'kurye',
          'müşteri': 'user',
          'musteri': 'user',
          'customer': 'user',
          'user': 'user',
        };

        final validRoles = ['admin', 'garson', 'asci', 'kurye', 'user'];

        if (roleMapping.containsKey(userRole) &&
            validRoles.contains(roleMapping[userRole])) {
          userRole = roleMapping[userRole]!;
        } else {
          final kullaniciAdiLower = _kullaniciAdiController.text
              .trim()
              .toLowerCase();

          if (kullaniciAdiLower.contains('admin')) {
            userRole = 'admin';
          } else if (kullaniciAdiLower.contains('garson') ||
              kullaniciAdiLower.contains('waiter')) {
            userRole = 'garson';
          } else if (kullaniciAdiLower.contains('asci') ||
              kullaniciAdiLower.contains('aşçı')) {
            userRole = 'asci';
          } else if (kullaniciAdiLower.contains('kurye') ||
              kullaniciAdiLower.contains('courier')) {
            userRole = 'kurye';
          } else {
            userRole = 'user';
          }
        }

        // 🔥 Kullanıcı bilgilerini kaydet
        final user = {
          'id':
              data['userId'] ??
              data['UserId'] ??
              data['personelId'] ??
              data['PersonelId'] ??
              data['id'] ??
              nestedData['userId'] ??
              nestedData['UserId'] ??
              nestedData['personelId'] ??
              nestedData['PersonelId'] ??
              nestedData['id'] ??
              0,
          'name':
              data['adSoyad'] ??
              data['AdSoyad'] ??
              data['name'] ??
              _kullaniciAdiController.text.trim(),
          'email': data['email'] ?? _kullaniciAdiController.text.trim(),
          'role': userRole,
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user',
          jsonEncode(user),
        ); // ✅ jsonEncode çalışıyor
        await prefs.setString('user_id', user['id'].toString());

        if (!mounted) return;
        await context.read<SepetProvider>().reloadFavoriler();

        // 🔥 YÖNLENDİRME
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MenuScreen()),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Hoş geldiniz, ${user['name']}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Giriş başarısız!';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _misafirGiris() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = {
        'id': 0,
        'name': 'Misafir',
        'email': 'guest@local',
        'role': 'user',
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user));
      await prefs.setString('user_id', 'guest');

      if (!mounted) return;
      await context.read<SepetProvider>().reloadFavoriler();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Misafir girişi yapılamadı';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: size.width > 600 ? 60 : 24,
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.025),
                  _buildLogo(size, isDark),
                  SizedBox(height: size.height * 0.025),
                  _buildFormCard(isDark, size),
                  SizedBox(height: size.height * 0.025),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Size size, bool isDark) {
    double logoSize = size.width > 600 ? 140 : size.width * 0.34;
    if (logoSize > 165) logoSize = 165;
    if (logoSize < 96) logoSize = 96;

    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/Logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: _secondaryColor.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.restaurant,
                    size: 60,
                    color: _accentColor,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Şeker Restoran',
          style: TextStyle(
            fontSize: size.width > 600 ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : _accentColor,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark, Size size) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: size.width > 600 ? 420 : double.infinity,
      ),
      padding: EdgeInsets.all(size.width > 600 ? 36 : 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A1F18).withValues(alpha: 0.9)
            : const Color(0xFFFAFDF9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : _secondaryColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : _primaryColor.withValues(alpha: 0.12),
            blurRadius: 50,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const Text(
              'Kullanıcı Adı',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _kullaniciAdiController,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF7FCF7),
                hintText: 'kullanıcı adınız',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : _secondaryColor.withValues(alpha: 0.45),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : _secondaryColor.withValues(alpha: 0.45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kullanıcı adı giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Şifre',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sifreController,
              obscureText: !_showPassword,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF7FCF7),
                hintText: '••••••••',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : _secondaryColor.withValues(alpha: 0.45),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : _secondaryColor.withValues(alpha: 0.45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Şifre giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _beniHatirla,
                        onChanged: (val) {
                          setState(() {
                            _beniHatirla = val ?? false;
                          });
                        },
                        activeColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : _secondaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Beni hatırla',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Şifremi unuttum',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : _accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _girisYap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: _primaryColor.withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Giriş Yapılıyor...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'GİRİŞ YAP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _misafirGiris,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _secondaryColor.withValues(alpha: 0.6),
                  ),
                  foregroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.person_outline),
                label: const Text(
                  'Misafir Girişi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
