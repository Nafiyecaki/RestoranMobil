// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

        // Controller'ları doldur
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text(
          '👤 Profilim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text('Profil yükleniyor...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfileData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profil Kartı
                      _buildProfileCard(),
                      const SizedBox(height: 16),

                      // Adresler
                      _buildAddressSection(),
                      const SizedBox(height: 16),

                      // Siparişler
                      _buildOrdersSection(),
                      const SizedBox(height: 16),

                      // Sipariş Geçmişi
                      _buildOrderHistorySection(),
                      const SizedBox(height: 16),

                      // Çıkış Butonu
                      _buildLogoutButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF2E7D32),
                  child: Text(
                    _user?.uyeAdi?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.tamAdi ?? 'İsimsiz',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _user?.uyeEmail ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        _user?.uyeTelefon ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.close : Icons.edit,
                    color: const Color(0xFF2E7D32),
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
              ],
            ),
            if (_isEditing) ...[
              const Divider(),
              TextField(
                controller: _adiController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _soyadiController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _telefonController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
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
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
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
              TextButton.icon(
                onPressed: () {
                  setState(() => _showPasswordChange = true);
                },
                icon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
                label: const Text(
                  'Şifre Değiştir',
                  style: TextStyle(color: Color(0xFF2E7D32)),
                ),
              ),
            if (_showPasswordChange) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _eskiSifreController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Eski Şifre',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _yeniSifreController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _yeniSifreTekrarController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
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
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
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

  Widget _buildAddressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📍 Adreslerim',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    _showAddAddress ? Icons.close : Icons.add_location,
                    color: const Color(0xFF2E7D32),
                  ),
                  onPressed: () {
                    setState(() => _showAddAddress = !_showAddAddress);
                  },
                ),
              ],
            ),
            if (_addresses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Kayıtlı adresiniz yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._addresses.map((address) => ListTile(
                    leading: const Icon(Icons.home, color: Color(0xFF2E7D32)),
                    title: Text(address.adresTipi),
                    subtitle: Text(address.acikAdres),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteAddress(address.adresId),
                    ),
                  )),
            if (_showAddAddress) ...[
              const Divider(),
              TextField(
                controller: _adresTipiController,
                decoration: const InputDecoration(
                  labelText: 'Adres Tipi (Ev, İş, vb.)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _acikAdresController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
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
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
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

  Widget _buildOrdersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Aktif Siparişlerim',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_orders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aktif siparişiniz yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._orders.map((order) => ListTile(
                    leading: const Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
                    title: Text('#${order['siparisId']}'),
                    subtitle: Text(
                      '${order['toplamTutar']} ₺ - ${order['siparisDurumu']}',
                    ),
                    trailing: Text(
                      order['siparisTarihi'] != null
                          ? DateTime.parse(order['siparisTarihi']).toLocal().toString().split(' ')[0]
                          : '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistorySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📜 Sipariş Geçmişim',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_orderHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Geçmiş siparişiniz yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._orderHistory.take(5).map((order) => ListTile(
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: Text('#${order['siparisId']}'),
                    subtitle: Text(
                      '${order['toplamTutar']} ₺ - ${order['siparisDurumu']}',
                    ),
                    trailing: Text(
                      order['siparisTarihi'] != null
                          ? DateTime.parse(order['siparisTarihi']).toLocal().toString().split(' ')[0]
                          : '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )),
            if (_orderHistory.length > 5)
              TextButton(
                onPressed: () {
                  // Tüm geçmişi göster
                },
                child: const Text('Tümünü Gör'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await ApiService.logout();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Çıkış Yap'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}