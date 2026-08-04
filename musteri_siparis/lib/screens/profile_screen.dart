import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sepet_item.dart';
import '../models/urun.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';
import '../providers/sepet_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'address_list_screen.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_favorites_screen.dart';
import 'profile_who_we_are_screen.dart';
import 'sepet_screen.dart';
import 'siparis_ozet_screen.dart';

enum ProfileBackTarget { menu, sepet }

class ProfileScreen extends StatefulWidget {
  final ProfileBackTarget geriDonusHedefi;

  const ProfileScreen({
    super.key,
    this.geriDonusHedefi = ProfileBackTarget.menu,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _secondaryColor = Color(0xFF66BB6A);
  static const Color _accentColor = Color(0xFF1B5E20);
  final ScrollController _profileScrollController = ScrollController();

  User? _user;

  List<Address> _addresses = [];
  int? _defaultAddressId;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoggingOut = false;
  bool _showPasswordChange = false;
  bool _emailVerified = false;
  bool _phoneVerified = false;
  String? _avatarBase64;
  String? _errorMessage;
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  final List<Map<String, dynamic>> _orders = [];
  final List<Map<String, dynamic>> _orderHistory = [];
  List<Urun> _tumUrunler = [];
  List<Map<String, String>> _whoWeAreMembers = [
    {'name': 'Ekip Üyesi 1', 'role': 'Mobil Uygulama Geliştirme'},
    {'name': 'Ekip Üyesi 2', 'role': 'Backend ve API Entegrasyonu'},
    {'name': 'Ekip Üyesi 3', 'role': 'UI/UX Tasarım'},
    {'name': 'Ekip Üyesi 4', 'role': 'Sipariş ve Operasyon Akışı'},
    {'name': 'Ekip Üyesi 5', 'role': 'Test ve Kalite Kontrol'},
  ];

  late final TextEditingController _eskiSifreController;
  late final TextEditingController _yeniSifreController;
  late final TextEditingController _yeniSifreTekrarController;

  @override
  void initState() {
    super.initState();
    _eskiSifreController = TextEditingController();
    _yeniSifreController = TextEditingController();
    _yeniSifreTekrarController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _profileScrollController.dispose();
    _eskiSifreController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData({bool fromRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (fromRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final profile = await ApiService.getProfile();
      final addresses = await ApiService.getAddresses();
      final orders = await ApiService.getMyOrders();
      final history = await ApiService.getOrderHistory();
      final urunler = await ApiService.getUrunler();
      final prefs = await SharedPreferences.getInstance();
      final currentUser = await ApiService.getCurrentUser();
      final userId =
          currentUser?['userId']?.toString() ?? profile.uyeId.toString();
      final whoWeAreRaw = prefs.getString('who_we_are_$userId');

      final activeOrders = orders.where((order) {
        final durum = (order['siparisDurumu'] ?? '').toString().toLowerCase();
        return !(durum.contains('teslim') ||
            durum.contains('iptal') ||
            durum.contains('cancel'));
      }).toList();

      if (!mounted) return;
      setState(() {
        _user = profile;
        _addresses = addresses;
        _orders
          ..clear()
          ..addAll(activeOrders);
        _orderHistory
          ..clear()
          ..addAll(history);
        _tumUrunler = urunler;
        _defaultAddressId = prefs.getInt('default_address_$userId');
        _avatarBase64 = prefs.getString('avatar_$userId');
        _emailVerified = prefs.getBool('email_verified_$userId') ?? false;
        _phoneVerified = prefs.getBool('phone_verified_$userId') ?? false;
        if (whoWeAreRaw != null && whoWeAreRaw.isNotEmpty) {
          final decoded = jsonDecode(whoWeAreRaw);
          if (decoded is List) {
            _whoWeAreMembers = decoded
                .whereType<Map>()
                .map(
                  (item) => {
                    'name': item['name']?.toString() ?? '',
                    'role': item['role']?.toString() ?? '',
                  },
                )
                .where((item) => item['name']!.isNotEmpty)
                .toList();
          }
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() => _loadProfileData(fromRefresh: true);

  Future<void> _openAvatarPicker() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      final currentUser = await ApiService.getCurrentUser();
      final userId =
          currentUser?['userId']?.toString() ??
          _user?.uyeId.toString() ??
          'guest';

      await prefs.setString('avatar_$userId', encoded);
      if (!mounted) return;
      setState(() => _avatarBase64 = encoded);
      _showSnackBar('✅ Profil fotoğrafı güncellendi', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Fotoğraf seçilemedi: $e', Colors.red);
    }
  }

  Future<void> _saveBool(String keyPrefix, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = await ApiService.getCurrentUser();
    final userId =
        currentUser?['userId']?.toString() ??
        _user?.uyeId.toString() ??
        'guest';
    await prefs.setBool('$keyPrefix$userId', value);
  }

  Future<void> _saveString(String keyPrefix, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = await ApiService.getCurrentUser();
    final userId =
        currentUser?['userId']?.toString() ??
        _user?.uyeId.toString() ??
        'guest';
    await prefs.setString('$keyPrefix$userId', value);
  }

  Future<void> _saveWhoWeAreMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = await ApiService.getCurrentUser();
    final userId =
        currentUser?['userId']?.toString() ??
        _user?.uyeId.toString() ??
        'guest';
    await prefs.setString('who_we_are_$userId', jsonEncode(_whoWeAreMembers));
  }

  Future<void> _openEditProfilePage() async {
    if (_user == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProfileEditScreen(user: _user!)),
    );

    if (updated == true) {
      await _loadProfileData();
      _showSnackBar('✅ Profil güncellendi', Colors.green);
    }
  }

  Future<void> _openFavoritesPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileFavoritesScreen(products: _tumUrunler),
      ),
    );
  }

  Future<void> _openWhoWeArePage() async {
    final updatedMembers = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileWhoWeAreScreen(initialMembers: _whoWeAreMembers),
      ),
    );

    if (updatedMembers == null) return;

    setState(() {
      _whoWeAreMembers = updatedMembers;
    });
    await _saveWhoWeAreMembers();
  }

  Future<void> _changePassword() async {
    if (_yeniSifreController.text != _yeniSifreTekrarController.text) {
      _showSnackBar('❌ Yeni şifreler eşleşmiyor', Colors.red);
      return;
    }

    if (_eskiSifreController.text.isEmpty ||
        _yeniSifreController.text.isEmpty) {
      _showSnackBar('❌ Lütfen tüm şifre alanlarını doldurun', Colors.orange);
      return;
    }

    try {
      final result = await ApiService.changePassword(
        eskiSifre: _eskiSifreController.text,
        yeniSifre: _yeniSifreController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _showPasswordChange = false;
        });
        _eskiSifreController.clear();
        _yeniSifreController.clear();
        _yeniSifreTekrarController.clear();
        _showSnackBar('✅ Şifre değiştirildi', Colors.green);
      } else {
        _showSnackBar(result['message'] ?? 'Şifre değiştirilemedi', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Şifre değiştirilirken hata oluştu: $e', Colors.red);
    }
  }

  Future<void> _setEmailVerified(bool value) async {
    if (!mounted) return;
    setState(() => _emailVerified = value);
    await _saveBool('email_verified_', value);
  }

  Future<void> _setPhoneVerified(bool value) async {
    if (!mounted) return;
    setState(() => _phoneVerified = value);
    await _saveBool('phone_verified_', value);
  }

  static int _statusStep(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('teslim')) return 3;
    if (s.contains('yolda') || s.contains('dağıtım') || s.contains('dagitim')) {
      return 2;
    }
    if (s.contains('hazır') || s.contains('hazir') || s.contains('piş')) {
      return 1;
    }
    return 0;
  }

  List<OrderItemData> _extractOrderItems(Map<String, dynamic> order) {
    final rawList =
        order['detaylar'] ?? order['siparisDetaylari'] ?? order['items'] ?? [];
    if (rawList is! List) return [];

    return rawList.whereType<Map>().map((raw) {
      final map = raw.map((k, v) => MapEntry(k.toString(), v));
      final qty = (map['adet'] ?? map['quantity'] ?? 1) as num;
      final price = (map['fiyat'] ?? map['price'] ?? 0) as num;
      return OrderItemData(
        urunId: (map['urunId'] ?? map['productId']) is num
            ? (map['urunId'] ?? map['productId']) as int
            : int.tryParse(
                (map['urunId'] ?? map['productId'] ?? '').toString(),
              ),
        ad: (map['urunAdi'] ?? map['name'] ?? 'Ürün').toString(),
        adet: qty.toInt(),
        fiyat: price.toDouble(),
      );
    }).toList();
  }

  Future<void> _openOrderDetail(Map<String, dynamic> order) async {
    try {
      final items = _extractOrderItems(order);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order, items: items),
        ),
      );
    } catch (e) {
      _showSnackBar('❌ Sipariş detayı açılamadı: $e', Colors.red);
    }
  }

  Future<void> _openOrderStatus(Map<String, dynamic> order) async {
    try {
      final items = _extractOrderItems(order)
          .map(
            (item) => SiparisOzetItemData(
              urunAdi: item.ad,
              adet: item.adet,
              birimFiyat: item.fiyat,
            ),
          )
          .toList();

      final siparisTipi = (order['siparisTipi'] ?? 'PAKET_SERVIS').toString();
      final odemeTipi =
          (order['odemeTipi'] ??
                  order['odemeTuru'] ??
                  order['odemeYontemi'] ??
                  'KAPIDA_ODEME')
              .toString();

      final teslimatUcreti =
          (order['teslimatUcreti'] as num?)?.toDouble() ??
          (siparisTipi == 'SALON' ? 0.0 : 9.99);

      final itemsToplam = items.fold<double>(
        0,
        (sum, item) => sum + item.satirToplami,
      );

      final toplamTutar =
          (order['toplamTutar'] as num?)?.toDouble() ??
          (itemsToplam + teslimatUcreti);
      final araToplam = items.isNotEmpty
          ? itemsToplam
          : (toplamTutar - teslimatUcreti).clamp(0.0, double.infinity);

      final fallbackName = '${_user?.uyeAdi ?? ''} ${_user?.uyeSoyadi ?? ''}'
          .trim();
      final defaultAddress = _addresses
          .where((a) => a.adresId == _defaultAddressId)
          .cast<Address?>()
          .firstWhere(
            (a) => a != null,
            orElse: () => _addresses.isNotEmpty ? _addresses.first : null,
          )
          ?.acikAdres;

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SiparisOzetScreen(
            siparisId: (order['siparisId'] as num?)?.toInt(),
            siparisTipi: siparisTipi,
            odemeTipi: odemeTipi,
            initialDurum: order['siparisDurumu']?.toString(),
            musteriAdi:
                (order['musteriAdi']?.toString().trim().isNotEmpty ?? false)
                ? order['musteriAdi'].toString()
                : (fallbackName.isNotEmpty ? fallbackName : 'Müşteri'),
            musteriTelefon:
                (order['musteriTelefon'] ?? _user?.uyeTelefon ?? '-')
                    .toString(),
            musteriAdres: (order['musteriAdres'] ?? defaultAddress ?? '-')
                .toString(),
            urunler: items,
            araToplam: araToplam,
            teslimatUcreti: teslimatUcreti,
            toplamTutar: toplamTutar,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('❌ Sipariş durumu açılamadı: $e', Colors.red);
    }
  }

  Future<void> _repeatOrder(Map<String, dynamic> order) async {
    try {
      final items = _extractOrderItems(order);
      if (items.isEmpty) {
        _showSnackBar(
          'Bu siparişte tekrar eklenecek ürün bulunamadı',
          Colors.orange,
        );
        return;
      }

      final sepetProvider = Provider.of<SepetProvider>(context, listen: false);
      final urunler = await ApiService.getUrunler();

      int added = 0;
      for (final item in items) {
        Urun? urun;

        if (item.urunId != null) {
          for (final u in urunler) {
            if (u.urunId == item.urunId) {
              urun = u;
              break;
            }
          }
        }

        urun ??= urunler.cast<Urun?>().firstWhere(
          (u) => (u?.urunAdi.toLowerCase() ?? '') == item.ad.toLowerCase(),
          orElse: () => null,
        );

        if (urun != null) {
          sepetProvider.sepeteEkle(SepetItem(urun: urun, adet: item.adet));
          added++;
        }
      }

      if (!mounted) return;
      if (added > 0) {
        _showSnackBar('✅ $added ürün sepete yeniden eklendi', Colors.green);
      } else {
        _showSnackBar('❌ Ürünler menüde bulunamadı', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Sipariş tekrar eklenirken hata oluştu: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
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

  void _onBottomNavTap(int index) {
    if (index == 2) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SepetScreen()),
      );
    }
  }

  /// Çıkış yap: onay al, backend'e logout isteği gönder (varsa),
  /// yerel oturum verisini temizle ve login ekranına dön.
  /// Named route ('/login') kayıtlı olmasa bile çalışır çünkü
  /// doğrudan LoginScreen widget'ına yönlendirir.
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    if (!mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      await ApiService.logout();
    } catch (e) {
      // Backend'e ulaşılamasa bile yerel oturumu kapatmaya devam et.
      debugPrint('Logout API hatası (yerel çıkış yine de yapılacak): $e');
    }

    if (!mounted) return;

    setState(() => _isLoggingOut = false);

    // Doğrudan LoginScreen'e yönlendir; '/login' route'u
    // main.dart'ta tanımlı olmasa bile bu her zaman çalışır.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sepetProvider = context.watch<SepetProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      appBar: AppBar(
        title: const Text(
          '👤 Profilim',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing
                ? null
                : () => _loadProfileData(fromRefresh: true),
          ),
        ],
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
          ? _buildError()
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: _primaryColor,
                    child: SingleChildScrollView(
                      controller: _profileScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
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
                          _buildFavoritesSection(isDark, sepetProvider),
                          const SizedBox(height: 16),
                          _buildWhoWeAreSection(isDark),
                          const SizedBox(height: 16),
                          _buildSettingsSection(isDark),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildStickyLogoutButton(isDark),
              ],
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: _onBottomNavTap,
      ),
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
              color: _primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text('Profil yükleniyor...', style: TextStyle(color: Colors.grey)),
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
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 50),
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
              backgroundColor: _primaryColor,
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

  Widget _buildCardShell({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  ImageProvider<Object>? _avatarImageProvider() {
    if (_avatarBase64 == null || _avatarBase64!.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(_avatarBase64!));
    } catch (_) {
      return null;
    }
  }

  Widget _buildProfileCard(bool isDark) {
    return _buildCardShell(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: _openAvatarPicker,
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: _primaryColor.withValues(alpha: 0.14),
                      backgroundImage: _avatarImageProvider(),
                      child: _avatarImageProvider() == null
                          ? Text(
                              _user?.uyeAdi?.substring(0, 1).toUpperCase() ??
                                  '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.tamAdi.isNotEmpty == true
                          ? _user!.tamAdi
                          : 'İsimsiz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _rowInfo(
                      icon: Icons.email_outlined,
                      text: _user?.uyeEmail ?? '-',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 4),
                    _rowInfo(
                      icon: Icons.phone_outlined,
                      text: _user?.uyeTelefon ?? '-',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: _primaryColor,
                    size: 22,
                  ),
                  onPressed: _openEditProfilePage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.lock_outline,
            title: 'Şifre Değiştir',
            status: const _VerificationStatus(
              text: 'Güvenlik',
              color: _primaryColor,
              icon: Icons.shield_outlined,
            ),
            onTap: () {
              setState(() => _showPasswordChange = !_showPasswordChange);
            },
          ),
          const SizedBox(height: 10),
          _buildSecurityTile(
            icon: Icons.mark_email_read_outlined,
            title: 'E-posta Doğrula',
            status: _emailVerified
                ? const _VerificationStatus(
                    text: 'Doğrulandı',
                    color: Colors.green,
                    icon: Icons.check_circle,
                  )
                : const _VerificationStatus(
                    text: 'Doğrulanmadı',
                    color: Colors.orange,
                    icon: Icons.error_outline,
                  ),
            onTap: () async {
              await _setEmailVerified(true);
              _showSnackBar('✅ E-posta doğrulandı', Colors.green);
            },
          ),
          const SizedBox(height: 10),
          _buildSecurityTile(
            icon: Icons.phone_iphone_outlined,
            title: 'Telefon Doğrula',
            status: _phoneVerified
                ? const _VerificationStatus(
                    text: 'Doğrulandı',
                    color: Colors.green,
                    icon: Icons.check_circle,
                  )
                : const _VerificationStatus(
                    text: 'Doğrulanmadı',
                    color: Colors.red,
                    icon: Icons.warning_amber_rounded,
                  ),
            onTap: () async {
              await _setPhoneVerified(true);
              _showSnackBar('✅ Telefon doğrulandı', Colors.green);
            },
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
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _yeniSifreController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_open_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _yeniSifreTekrarController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre Tekrar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_open_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showPasswordChange = false;
                      });
                      _eskiSifreController.clear();
                      _yeniSifreController.clear();
                      _yeniSifreTekrarController.clear();
                    },
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
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
    );
  }

  Widget _rowInfo({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required _VerificationStatus status,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(status.icon, size: 13, color: status.color),
                  const SizedBox(width: 4),
                  Text(
                    status.text,
                    style: TextStyle(
                      color: status.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(bool isDark) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddressListScreen(
              user: _user,
              initialAddresses: _addresses,
              initialSelectedAddressId: _defaultAddressId,
            ),
          ),
        );
        if (mounted) {
          _loadProfileData();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: _buildCardShell(
        isDark: isDark,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: _primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Adreslerim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_addresses.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adreslerini yönetmek için dokun',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSection(bool isDark) {
    return _buildCardShell(
      isDark: isDark,
      child: InkWell(
        onTap: _orders.isEmpty ? null : _openAllActiveOrders,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: _primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Aktif Siparişlerim',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
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
                    const SizedBox(height: 4),
                    Text(
                      _orders.isEmpty
                          ? 'Aktif siparişiniz yok'
                          : 'Sipariş durumlarını görmek için dokun',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAllActiveOrders() async {
    if (_orders.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ActiveOrdersScreen(orders: _orders, onOrderTap: _openOrderStatus),
      ),
    );
  }

  static Widget _buildOrderProgress(int activeStep) {
    const labels = ['Hazırlanıyor', 'Yolda', 'Teslim Edildi'];
    return Column(
      children: [
        Row(
          children: List.generate(labels.length * 2 - 1, (index) {
            if (index.isOdd) {
              final done = activeStep > (index ~/ 2) + 1;
              return Expanded(
                child: Container(
                  height: 3,
                  color: done
                      ? _secondaryColor
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              );
            }

            final step = index ~/ 2 + 1;
            final reached = activeStep >= step;
            return Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: reached
                    ? _primaryColor
                    : Colors.grey.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                reached ? Icons.check : Icons.circle,
                size: 12,
                color: Colors.white,
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (label) => Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildOrderHistorySection(bool isDark) {
    return _buildCardShell(
      isDark: isDark,
      child: InkWell(
        onTap: _orderHistory.isEmpty ? null : _openOrderHistoryScreen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.history_outlined,
                  color: _accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sipariş Geçmişim',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _secondaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_orderHistory.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _orderHistory.isEmpty
                          ? 'Geçmiş siparişiniz yok'
                          : 'Tüm geçmiş siparişleri görmek için dokun',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(bool isDark, SepetProvider sepetProvider) {
    final favoriteIds = sepetProvider.favoriler.toSet();
    final favoriteProducts = _tumUrunler
        .where((urun) => favoriteIds.contains(urun.urunId))
        .toList();

    return _buildCardShell(
      isDark: isDark,
      child: InkWell(
        onTap: _openFavoritesPage,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.favorite, color: _primaryColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Favorilerim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${favoriteProducts.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    favoriteProducts.isEmpty
                        ? 'Favori urununuz yok'
                        : 'Favori urunlerinizi gormek icin dokun',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOrderHistoryScreen() async {
    if (_orderHistory.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderHistoryScreen(
          orders: _orderHistory,
          onOrderDetail: _openOrderDetail,
          onRepeatOrder: _repeatOrder,
        ),
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    return _buildCardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                color: _primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Ayarlar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _primaryColor,
            activeTrackColor: _secondaryColor.withValues(alpha: 0.45),
            title: const Text('Push Bildirimleri'),
            subtitle: const Text('Sipariş güncellemelerini anlık al'),
            value: _pushNotificationsEnabled,
            onChanged: (value) async {
              setState(() => _pushNotificationsEnabled = value);
              await _saveBool('settings_push_', value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _primaryColor,
            activeTrackColor: _secondaryColor.withValues(alpha: 0.45),
            title: const Text('E-posta Bildirimleri'),
            subtitle: const Text('Kampanya ve sipariş bilgilendirmeleri'),
            value: _emailNotificationsEnabled,
            onChanged: (value) async {
              setState(() => _emailNotificationsEnabled = value);
              await _saveBool('settings_email_', value);
            },
          ),
          Row(
            children: [
              const Icon(
                Icons.palette_outlined,
                color: _primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Tema', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              _buildThemeDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhoWeAreSection(bool isDark) {
    return _buildCardShell(
      isDark: isDark,
      child: InkWell(
        onTap: _openWhoWeArePage,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                color: _primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Biz Kimiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_whoWeAreMembers.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ekip detaylarini gormek icin dokun',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeDropdown() {
    final themeProvider = context.watch<ThemeProvider>();
    final selectedTheme = ThemeProvider.labelFromMode(themeProvider.themeMode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _secondaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _secondaryColor.withValues(alpha: 0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTheme,
          items: const [
            DropdownMenuItem(value: 'Açık', child: Text('Açık')),
            DropdownMenuItem(value: 'Koyu', child: Text('Koyu')),
          ],
          onChanged: (value) async {
            if (value == null) return;
            await context.read<ThemeProvider>().setThemeModeByLabel(value);
            await _saveString('settings_theme_', value);
            _showSnackBar('✅ Tema: $value', Colors.green);
          },
        ),
      ),
    );
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildStickyLogoutButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoggingOut ? null : _handleLogout,
          icon: _isLoggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.logout, size: 20),
          label: Text(
            _isLoggingOut ? 'Çıkış Yapılıyor...' : 'Çıkış Yap',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

class ActiveOrdersScreen extends StatelessWidget {
  const ActiveOrdersScreen({
    super.key,
    required this.orders,
    required this.onOrderTap,
  });

  final List<Map<String, dynamic>> orders;
  final void Function(Map<String, dynamic> order) onOrderTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Aktif Siparişlerim'),
        backgroundColor: _ProfileScreenState._primaryColor,
        foregroundColor: Colors.white,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Aktif siparişiniz yok'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final step = _ProfileScreenState._statusStep(
                  order['siparisDurumu']?.toString(),
                );
                return InkWell(
                  onTap: () => onOrderTap(order),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _ProfileScreenState._primaryColor.withValues(
                        alpha: 0.04,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${order['siparisId'] ?? '-'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${order['toplamTutar'] ?? '-'} ₺',
                              style: const TextStyle(
                                color: _ProfileScreenState._primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order['siparisDurumu']?.toString() ??
                              'Durum bekleniyor',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ProfileScreenState._buildOrderProgress(step),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sipariş Durumuna Git',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({
    super.key,
    required this.orders,
    required this.onOrderDetail,
    required this.onRepeatOrder,
  });

  final List<Map<String, dynamic>> orders;
  final void Function(Map<String, dynamic> order) onOrderDetail;
  final void Function(Map<String, dynamic> order) onRepeatOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Sipariş Geçmişim'),
        backgroundColor: _ProfileScreenState._primaryColor,
        foregroundColor: Colors.white,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Geçmiş siparişiniz yok'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return InkWell(
                  onTap: () => onOrderDetail(order),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${order['siparisId'] ?? '-'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${order['toplamTutar'] ?? '-'} ₺',
                              style: const TextStyle(
                                color: _ProfileScreenState._primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order['siparisDurumu']?.toString() ?? '-',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Text(
                              _ProfileScreenState._formatDate(
                                order['siparisTarihi']?.toString(),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => onOrderDetail(order),
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Detay'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      _ProfileScreenState._accentColor,
                                  side: BorderSide(
                                    color: _ProfileScreenState._secondaryColor
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => onRepeatOrder(order),
                                icon: const Icon(Icons.replay, size: 16),
                                label: const Text('Tekrar Sipariş Ver'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _ProfileScreenState._primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.items,
  });

  final Map<String, dynamic> order;
  final List<OrderItemData> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sipariş #${order['siparisId'] ?? '-'}'),
        backgroundColor: _ProfileScreenState._primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _ProfileScreenState._primaryColor.withValues(
                  alpha: 0.07,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durum: ${order['siparisDurumu'] ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Tarih: ${order['siparisTarihi'] ?? '-'}'),
                  const SizedBox(height: 4),
                  Text('Toplam: ${order['toplamTutar'] ?? '-'} ₺'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ürünler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('Bu sipariş için ürün detayı bulunamadı'),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, separatorIndex) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final total = item.fiyat * item.adet;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.ad,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.adet} x ${item.fiyat.toStringAsFixed(2)}',
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${total.toStringAsFixed(2)} ₺',
                                style: const TextStyle(
                                  color: _ProfileScreenState._primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderItemData {
  const OrderItemData({
    this.urunId,
    required this.ad,
    required this.adet,
    required this.fiyat,
  });

  final int? urunId;
  final String ad;
  final int adet;
  final double fiyat;
}

class _VerificationStatus {
  const _VerificationStatus({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;
}
