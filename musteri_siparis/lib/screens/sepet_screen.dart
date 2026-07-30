import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/sepet_provider.dart';
import '../services/api_service.dart';

class SepetScreen extends StatefulWidget {
  const SepetScreen({super.key});

  @override
  State<SepetScreen> createState() => _SepetScreenState();
}

class _SepetScreenState extends State<SepetScreen> {
  // ✅ DÜZELTİLDİ: ApiService _api = ApiService() kaldırıldı
  final _adController = TextEditingController();
  final _telController = TextEditingController();
  final _adresController = TextEditingController();
  final _notController = TextEditingController();
  bool _gonderiliyor = false;
  String _seciliSiparisTipi = 'PAKET_SERVIS';

  final List<Map<String, dynamic>> _siparisTipleri = [
    {'value': 'PAKET_SERVIS', 'label': '📦 Paket Servis', 'icon': Icons.local_shipping},
    {'value': 'GEL_AL', 'label': '🏃 Gel-Al', 'icon': Icons.directions_walk},
    {'value': 'SALON', 'label': '🍽️ Salonda Ye', 'icon': Icons.restaurant},
  ];

  final List<Map<String, dynamic>> _odemeTipleri = [
    {'value': 'NAKIT', 'label': '💵 Nakit', 'icon': Icons.money},
    {'value': 'KREDI_KARTI', 'label': '💳 Kredi Kartı', 'icon': Icons.credit_card},
    {'value': 'ONLINE', 'label': '📱 Online', 'icon': Icons.qr_code_scanner},
  ];

  String _seciliOdemeTipi = 'NAKIT';
  bool _adresGoster = true;

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
      final detaylar = sepet.items.map((item) => {
        'urunId': item.urun.urunId,
        'adet': item.adet,
        'detayNot': item.not,
      }).toList();

      // ✅ DÜZELTİLDİ: _api.siparisOlustur() → ApiService.siparisOlustur()
      final result = await ApiService.siparisOlustur(
        siparisTipi: _seciliSiparisTipi,
        musteriAdi: _adController.text.trim(),
        musteriTelefon: _telController.text.trim(),
        musteriAdres: _adresGoster ? _adresController.text.trim() : null,
        detaylar: detaylar,
      );

      if (result['success'] == true) {
        sepet.temizle();
        _showSnackBar('✅ Siparişiniz başarıyla alındı!', Colors.green);
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        _showSnackBar(result['message'] ?? 'Sipariş oluşturulamadı', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Hata: ${e.toString().replaceFirst('Exception: ', '')}', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    final sepet = context.watch<SepetProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teslimatUcreti = _seciliSiparisTipi == 'SALON' ? 0.0 : 9.99;
    final toplam = sepet.toplamTutar + teslimatUcreti;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        title: const Text(
          '🛒 Sepetim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        centerTitle: true,
        actions: [
          if (sepet.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showClearCartDialog(sepet),
            ),
        ],
      ),
      body: sepet.items.isEmpty
          ? _buildEmptyCart(isDark)
          : _buildCartContent(sepet, isDark, toplam, teslimatUcreti),
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
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: isDark ? Colors.grey[600] : Colors.deepOrange.withValues(alpha: 0.5),
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
              backgroundColor: Colors.deepOrange,
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

  Widget _buildCartContent(SepetProvider sepet, bool isDark, double toplam, double teslimatUcreti) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          child: Row(
            children: [
              const Icon(Icons.local_shipping, size: 20, color: Colors.deepOrange),
              const SizedBox(width: 8),
              const Text(
                'Sipariş Tipi:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _seciliSiparisTipi,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.deepOrange),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    items: _siparisTipleri.map((tip) {
                      return DropdownMenuItem<String>(
                        value: tip['value'],
                        child: Text(tip['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _seciliSiparisTipi = value!;
                        _adresGoster = value != 'SALON';
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sepet.items.length,
            itemBuilder: (context, index) {
              final item = sepet.items[index];
              return _buildCartItem(item, sepet, isDark);
            },
          ),
        ),

        _buildPaymentSection(sepet, isDark, toplam, teslimatUcreti),
      ],
    );
  }

  Widget _buildCartItem(dynamic item, SepetProvider sepet, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
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
                      color: Colors.deepOrange,
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
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onTap: () => sepet.azalt(item.urun),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.adet}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onTap: () => sepet.ekle(item.urun),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Icon(
          icon,
          size: 18,
          color: Colors.deepOrange,
        ),
      ),
    );
  }

  Widget _buildPaymentSection(SepetProvider sepet, bool isDark, double toplam, double teslimatUcreti) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField(
            controller: _adController,
            icon: Icons.person,
            label: 'Adınız Soyadınız',
            hint: 'Ahmet Yılmaz',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _telController,
            icon: Icons.phone,
            label: 'Telefon Numarası',
            hint: '555 123 45 67',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          if (_adresGoster)
            _buildTextField(
              controller: _adresController,
              icon: Icons.location_on,
              label: 'Teslimat Adresi',
              hint: 'Mahalle, Sokak, Apartman No',
              maxLines: 2,
            ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _notController,
            icon: Icons.note,
            label: 'Sipariş Notu (Opsiyonel)',
            hint: 'Kapı zili çalışmıyor, arayın...',
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.deepOrange.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                _buildPriceRow('Ara Toplam', '₺${sepet.toplamTutar.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildPriceRow('Teslimat Ücreti', teslimatUcreti == 0 ? 'Ücretsiz' : '₺${teslimatUcreti.toStringAsFixed(2)}'),
                const Divider(height: 16, color: Colors.deepOrange),
                _buildPriceRow(
                  'Toplam',
                  '₺${toplam.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.payment, color: Colors.deepOrange),
              const SizedBox(width: 8),
              const Text(
                'Ödeme Tipi:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _seciliOdemeTipi,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.deepOrange),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    items: _odemeTipleri.map((tip) {
                      return DropdownMenuItem<String>(
                        value: tip['value'],
                        child: Text(tip['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _seciliOdemeTipi = value!);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _gonderiliyor ? null : () => _siparisVer(sepet),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        prefixIcon: Icon(icon, color: Colors.deepOrange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.04),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: isBold ? Colors.deepOrange : (isDark ? Colors.white : Colors.black87),
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
        content: const Text('Sepetteki tüm ürünler kaldırılacak. Devam etmek istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              sepet.temizle();
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