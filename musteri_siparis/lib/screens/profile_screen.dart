// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  List<Address> _addresses = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _orderHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Profil düzenleme
  bool _isEditing = false;
  final _adiController = TextEditingController();
  final _soyadiController = TextEditingController();
  final _telefonController = TextEditingController();

  // Şifre değiştirme
  bool _showPasswordChange = false;
  final _eskiSifreController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();

  // Adres ekleme
  bool _showAddAddress = false;
  final _adresTipiController = TextEditingController();
  final _acikAdresController = TextEditingController();
  bool _teslimatBolgesindeMi = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _adiController.dispose();
    _soyadiController.dispose();
    _telefonController.dispose();
    _eskiSifreController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    _adresTipiController.dispose();
    _acikAdresController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.getProfile();
      final addresses = await ApiService.getAddresses();
      final orders = await ApiService.getMyOrders();
      final history = await ApiService.getOrderHistory();

      setState(() {
        _user = user;
        _addresses = addresses;
        _orders = orders;
        _orderHistory = history;
        _isLoading = false;

        _adiController.text = user.uyeAdi ?? '';
        _soyadiController.text = user.uyeSoyadi ?? '';
        _telefonController.text = user.uyeTelefon ?? '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    final result = await ApiService.updateProfile(
      adi: _adiController.text.trim(),
      soyadi: _soyadiController.text.trim(),
      telefon: _telefonController.text.trim(),
    );

    if (result['success']) {
      setState(() {
        _isEditing = false;
        if (_user != null) {
          _user = User(
            uyeId: _user!.uyeId,
            uyeAdi: _adiController.text.trim(),
            uyeSoyadi: _soyadiController.text.trim(),
            uyeEmail: _user!.uyeEmail,
            uyeTelefon: _telefonController.text.trim(),
            cinsiyet: _user!.cinsiyet,
            kayitTarihi: _user!.kayitTarihi,
            adresler: _user!.adresler,
          );
        }
      });
      _showSnackBar('✅ Profil güncellendi!', Colors.green);
    } else {
      _showSnackBar(result['message'] ?? 'Güncellenemedi', Colors.red);
    }
  }

  Future<void> _changePassword() async {
    if (_yeniSifreController.text != _yeniSifreTekrarController.text) {
      _showSnackBar('❌ Yeni şifreler eşleşmiyor!', Colors.red);
      return;
    }

    final result = await ApiService.changePassword(
      eskiSifre: _eskiSifreController.text,
      yeniSifre: _yeniSifreController.text,
    );

    if (result['success']) {
      setState(() {
        _showPasswordChange = false;
        _eskiSifreController.clear();
        _yeniSifreController.clear();
        _yeniSifreTekrarController.clear();
      });
      _showSnackBar('✅ Şifre değiştirildi!', Colors.green);
    } else {
      _showSnackBar(result['message'] ?? 'Şifre değiştirilemedi', Colors.red);
    }
  }

  Future<void> _addAddress() async {
    if (_acikAdresController.text.trim().isEmpty) {
      _showSnackBar('Lütfen adres girin', Colors.orange);
      return;
    }

    final result = await ApiService.addAddress(
      adresTipi: _adresTipiController.text.trim().isNotEmpty
          ? _adresTipiController.text.trim()
          : 'Ev',
      acikAdres: _acikAdresController.text.trim(),
      teslimatBolgesindeMi: _teslimatBolgesindeMi,
    );

    if (result['success']) {
      setState(() {
        _showAddAddress = false;
        _adresTipiController.clear();
        _acikAdresController.clear();
        _teslimatBolgesindeMi = false;
      });
      _loadProfileData();
      _showSnackBar('✅ Adres eklendi!', Colors.green);
    } else {
      _showSnackBar(result['message'] ?? 'Adres eklenemedi', Colors.red);
    }
  }

  Future<void> _deleteAddress(int adresId) async {
    final result = await ApiService.deleteAddress(adresId);
    if (result['success']) {
      _loadProfileData();
      _showSnackBar('✅ Adres silindi!', Colors.green);
    } else {
      _showSnackBar('❌ Adres silinemedi', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text(
          '👤 Profilim',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProfileData,
          ),
        ],
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : _buildContent(isDark),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Profil yükleniyor...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 50,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfileData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadProfileData,
      color: const Color(0xFF2E7D32),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileCard(isDark),
            const SizedBox(height: 16),
            _buildAddressSection(isDark),
            const SizedBox(height: 16),
            _buildOrdersSection(isDark),
            const SizedBox(height: 16),
            _buildOrderHistorySection(isDark),
            const SizedBox(height: 16),
            _buildLogoutButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profil Başlığı
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFF2E7D32),
                      child: Text(
                        _user?.uyeAdi?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.tamAdi ?? 'İsimsiz',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _user?.uyeEmail ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _user?.uyeTelefon ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit_outlined,
                      color: const Color(0xFF2E7D32),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing) {
                          _adiController.text = _user?.uyeAdi ?? '';
                          _soyadiController.text = _user?.uyeSoyadi ?? '';
                          _telefonController.text = _user?.uyeTelefon ?? '';
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _adiController,
                decoration: InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _soyadiController,
                decoration: InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonController,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _adiController.text = _user?.uyeAdi ?? '';
                          _soyadiController.text = _user?.uyeSoyadi ?? '';
                          _telefonController.text = _user?.uyeTelefon ?? '';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(),
            // Şifre Değiştir
            if (!_showPasswordChange)
              InkWell(
                onTap: () {
                  setState(() => _showPasswordChange = true);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFF2E7D32).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Şifre Değiştir',
                        style: TextStyle(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            if (_showPasswordChange) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _eskiSifreController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Eski Şifre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yeniSifreController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: const Icon(Icons.lock_open_outlined, size: 20),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yeniSifreTekrarController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: const Icon(Icons.lock_open_outlined, size: 20),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showPasswordChange = false;
                          _eskiSifreController.clear();
                          _yeniSifreController.clear();
                          _yeniSifreTekrarController.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Değiştir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF2E7D32),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Adreslerim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_addresses.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    setState(() => _showAddAddress = !_showAddAddress);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _showAddAddress ? Icons.close : Icons.add,
                      color: const Color(0xFF2E7D32),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Kayıtlı adresiniz yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._addresses.map((address) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : const Color(0xFF2E7D32).withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.home,
                            color: Color(0xFF2E7D32),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.adresTipi,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                address.acikAdres,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteAddress(address.adresId),
                        ),
                      ],
                    ),
                  )),
            if (_showAddAddress) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _adresTipiController,
                decoration: InputDecoration(
                  labelText: 'Adres Tipi (Ev, İş, vb.)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: const Icon(Icons.label_outline, size: 20),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _acikAdresController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _teslimatBolgesindeMi,
                    onChanged: (value) {
                      setState(() => _teslimatBolgesindeMi = value ?? false);
                    },
                    activeColor: const Color(0xFF2E7D32),
                  ),
                  const Text('Teslimat bölgesinde mi?'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showAddAddress = false;
                          _adresTipiController.clear();
                          _acikAdresController.clear();
                          _teslimatBolgesindeMi = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Ekle'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aktif Siparişlerim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (_orders.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_orders.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_orders.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Aktif siparişiniz yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._orders.map((order) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : const Color(0xFF2E7D32).withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF2E7D32),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${order['siparisId']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${order['toplamTutar']} ₺ - ${order['siparisDurumu']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          order['siparisTarihi'] != null
                              ? DateTime.parse(order['siparisTarihi'])
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0]
                              : '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistorySection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_outlined,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sipariş Geçmişim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (_orderHistory.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_orderHistory.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_orderHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Geçmiş siparişiniz yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._orderHistory.take(5).map((order) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.grey.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${order['siparisId']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${order['toplamTutar']} ₺ - ${order['siparisDurumu']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          order['siparisTarihi'] != null
                              ? DateTime.parse(order['siparisTarihi'])
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0]
                              : '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )),
            if (_orderHistory.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Tüm geçmişi göster
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                  child: const Text('Tümünü Gör'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Çıkış Yap'),
              content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Vazgeç'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Çıkış Yap'),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            await ApiService.logout();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        },
        icon: const Icon(Icons.logout, size: 22),
        label: const Text(
          'Çıkış Yap',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}