// lib/screens/sepet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sepet_provider.dart';
import '../models/sepet_item.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';

class SepetScreen extends StatefulWidget {
  const SepetScreen({super.key});

  @override
  State<SepetScreen> createState() => _SepetScreenState();
}

class _SepetScreenState extends State<SepetScreen> {
  final _adController = TextEditingController();
  final _telController = TextEditingController();
  final _adresController = TextEditingController();
  final _notController = TextEditingController();
  bool _gonderiliyor = false;
  String _seciliSiparisTipi = 'PAKET_SERVIS';
  bool _isLoading = true;

  final List<Map<String, dynamic>> _siparisTipleri = [
    {
      'value': 'PAKET_SERVIS',
      'label': '📦 Paket Servis',
      'icon': Icons.local_shipping,
    },
    {'value': 'GEL_AL', 'label': '🏃 Gel-Al', 'icon': Icons.directions_walk},
    {'value': 'SALON', 'label': '🍽️ Salonda Ye', 'icon': Icons.restaurant},
  ];

  final List<Map<String, dynamic>> _odemeTipleri = [
    {'value': 'NAKIT', 'label': '💵 Nakit', 'icon': Icons.money},
    {
      'value': 'KREDI_KARTI',
      'label': '💳 Kredi Kartı',
      'icon': Icons.credit_card,
    },
    {'value': 'ONLINE', 'label': '📱 Online', 'icon': Icons.qr_code_scanner},
  ];

  String _seciliOdemeTipi = 'NAKIT';
  bool _adresGoster = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getProfile();
      setState(() {
        _adController.text = user.uyeAdi ?? '';
        _telController.text = user.uyeTelefon ?? '';
        if (user.adresler != null && user.adresler!.isNotEmpty) {
          _adresController.text = user.adresler!.first.acikAdres;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _telController.dispose();
    _adresController.dispose();
    _notController.dispose();
    super.dispose();
  }

  Future<void> _siparisVer(SepetProvider sepet) async {
    if (_adController.text.trim().isEmpty) {
      _showSnackBar('Lütfen adınızı girin', Colors.orange);
      return;
    }
    if (_telController.text.trim().isEmpty) {
      _showSnackBar('Lütfen telefon numaranızı girin', Colors.orange);
      return;
    }
    if (_adresGoster && _adresController.text.trim().isEmpty) {
      _showSnackBar('Lütfen teslimat adresini girin', Colors.orange);
      return;
    }

    setState(() => _gonderiliyor = true);

    try {
      final detaylar = sepet.sepet
          .map(
            (item) => {
              'urunId': item.urun.urunId,
              'adet': item.adet,
              'detayNot': item.not,
            },
          )
          .toList();

      final result = await ApiService.siparisOlustur(
        siparisTipi: _seciliSiparisTipi,
        musteriAdi: _adController.text.trim(),
        musteriTelefon: _telController.text.trim(),
        musteriAdres: _adresGoster ? _adresController.text.trim() : null,
        detaylar: detaylar,
      );

      if (result['success'] == true) {
        sepet.sepetiTemizle();
        _showSnackBar('✅ Siparişiniz başarıyla alındı!', Colors.green);
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showSnackBar(
          result['message'] ?? 'Sipariş oluşturulamadı',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        '❌ Hata: ${e.toString().replaceFirst('Exception: ', '')}',
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
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

  void _onBottomNavTap(int index) {
    if (index == 1) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sepet = context.watch<SepetProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teslimatUcreti = _seciliSiparisTipi == 'SALON' ? 0.0 : 9.99;
    final toplam = sepet.toplamFiyat + teslimatUcreti;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF5F5F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          '🛒 Sepetim',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (sepet.sepet.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _showClearCartDialog(sepet),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
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
            )
          : sepet.sepet.isEmpty
          ? _buildEmptyCart(isDark)
          : _buildCartContent(sepet, isDark, toplam, teslimatUcreti),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildEmptyCart(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: isDark
                  ? Colors.grey[600]
                  : Colors.deepOrange.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sepetiniz Boş',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lezzetli yemekler keşfedin! 🍽️',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Menüye Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
    SepetProvider sepet,
    bool isDark,
    double toplam,
    double teslimatUcreti,
  ) {
    return Column(
      children: [
        // 📋 Ürün Listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sepet.sepet.length,
            itemBuilder: (context, index) {
              final item = sepet.sepet[index];
              return _buildCartItem(item, sepet, isDark);
            },
          ),
        ),

        // 💳 Ödeme Bölümü
        _buildPaymentSection(sepet, isDark, toplam, teslimatUcreti),
      ],
    );
  }

  Widget _buildCartItem(SepetItem item, SepetProvider sepet, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🖼️ Görsel
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
              ),
            ),
            child: const Icon(
              Icons.fastfood,
              size: 32,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(width: 14),

          // 📝 Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.urun.urunAdi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${item.urun.fiyat.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (item.not?.isNotEmpty ?? false)
                  Text(
                    '📝 ${item.not}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // 🔢 Adet Kontrolü
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => sepet.sepettenCikar(item),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Icon(
                      Icons.remove,
                      size: 18,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${item.adet}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () =>
                      sepet.sepeteEkle(SepetItem(urun: item.urun, adet: 1)),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Icon(Icons.add, size: 18, color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(
    SepetProvider sepet,
    bool isDark,
    double toplam,
    double teslimatUcreti,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 🏷️ Sipariş Tipi
          _buildDropdownRow(
            icon: Icons.local_shipping,
            label: 'Sipariş Tipi',
            value: _seciliSiparisTipi,
            items: _siparisTipleri,
            onChanged: (value) {
              setState(() {
                _seciliSiparisTipi = value!;
                _adresGoster = value != 'SALON';
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 👤 Müşteri Bilgileri (Otomatik Dolu)
          _buildTextField(
            controller: _adController,
            icon: Icons.person,
            label: 'Adınız Soyadınız',
            hint: 'Ahmet Yılmaz',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _telController,
            icon: Icons.phone,
            label: 'Telefon Numarası',
            hint: '555 123 45 67',
            keyboardType: TextInputType.phone,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          if (_adresGoster)
            _buildTextField(
              controller: _adresController,
              icon: Icons.location_on,
              label: 'Teslimat Adresi',
              hint: 'Mahalle, Sokak, Apartman No',
              maxLines: 2,
              isDark: isDark,
            ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _notController,
            icon: Icons.note,
            label: 'Sipariş Notu (Opsiyonel)',
            hint: 'Kapı zili çalışmıyor, arayın...',
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 💰 Fiyat Özeti
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                _buildPriceRow(
                  'Ara Toplam',
                  '₺${sepet.toplamFiyat.toStringAsFixed(2)}',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Teslimat Ücreti',
                  teslimatUcreti == 0
                      ? 'Ücretsiz'
                      : '₺${teslimatUcreti.toStringAsFixed(2)}',
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _buildPriceRow(
                  'Toplam',
                  '₺${toplam.toStringAsFixed(2)}',
                  isBold: true,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 💳 Ödeme Tipi
          _buildDropdownRow(
            icon: Icons.payment,
            label: 'Ödeme Tipi',
            value: _seciliOdemeTipi,
            items: _odemeTipleri,
            onChanged: (value) => setState(() => _seciliOdemeTipi = value!),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 🚀 Sipariş Ver Butonu
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _gonderiliyor ? null : () => _siparisVer(sepet),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _gonderiliyor
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sipariş Gönderiliyor...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'SİPARİŞ VER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Siparişiniz onaylandıktan sonra hazırlanacaktır.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🧩 YARDIMCI WIDGET'LAR
  // ============================================================
  Widget _buildDropdownRow({
    required IconData icon,
    required String label,
    required String value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32)),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(item['label']),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.04),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold
                ? const Color(0xFF2E7D32)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  void _showClearCartDialog(SepetProvider sepet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sepeti Temizle'),
        content: const Text(
          'Sepetteki tüm ürünler kaldırılacak. Devam etmek istediğinize emin misiniz?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              sepet.sepetiTemizle();
              Navigator.pop(context);
              _showSnackBar('🗑️ Sepet temizlendi', Colors.orange);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}
