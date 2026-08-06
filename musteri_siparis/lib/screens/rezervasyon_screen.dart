import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';
import 'sepet_screen.dart';

class RezervasyonScreen extends StatefulWidget {
  const RezervasyonScreen({super.key});

  @override
  State<RezervasyonScreen> createState() => _RezervasyonScreenState();
}

class _RezervasyonScreenState extends State<RezervasyonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _kisiSayisiController = TextEditingController(text: '2');
  final _notController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 30);
  final List<_RezervasyonKaydi> _rezervasyonlar = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _telefonController.dispose();
    _kisiSayisiController.dispose();
    _notController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked == null) return;
    setState(() => _selectedTime = picked);
  }

  Future<void> _rezervasyonOlustur() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final kisiSayisi = int.tryParse(_kisiSayisiController.text.trim()) ?? 0;
    if (kisiSayisi <= 0) {
      _showSnackBar('Lütfen geçerli kişi sayısı girin', Colors.orange);
      return;
    }

    final tarihSaat = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (tarihSaat.isBefore(DateTime.now())) {
      _showSnackBar('Rezervasyon zamanı geçmişte olamaz', Colors.orange);
      return;
    }

    // Ad Soyad tek alan; backend MusteriAdi/MusteriSoyadi ayrımı bekliyor.
    final adSoyad = _adSoyadController.text.trim();
    final parcalar = adSoyad.split(RegExp(r'\s+'));
    final musteriAdi = parcalar.first;
    final musteriSoyadi = parcalar.length > 1
        ? parcalar.sublist(1).join(' ')
        : '';

    setState(() => _isSubmitting = true);

    final sonuc = await ApiService.rezervasyonOlustur(
      musteriAdi: musteriAdi,
      musteriSoyadi: musteriSoyadi,
      telefon: _telefonController.text.trim(),
      kisiSayisi: kisiSayisi,
      tarihSaat: tarihSaat,
      aciklama: _notController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (sonuc['success'] != true) {
      _showSnackBar(
        (sonuc['message'] ?? 'Rezervasyon oluşturulamadı').toString(),
        Colors.red,
      );
      return;
    }

    final kayit = _RezervasyonKaydi(
      adSoyad: adSoyad,
      telefon: _telefonController.text.trim(),
      kisiSayisi: kisiSayisi,
      tarihSaat: tarihSaat,
      not: _notController.text.trim(),
    );

    setState(() {
      _rezervasyonlar.insert(0, kayit);
      _notController.clear();
    });

    _showSnackBar('✅ Rezervasyon talebiniz alındı', Colors.green);
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
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileScreen(geriDonusHedefi: ProfileBackTarget.menu),
        ),
      );
    }
  }

  void _navigateBackSafely() {
    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MenuScreen()));
  }

  /// Geniş (web/masaüstü) ekranlarda alt gezinme çubuğu yerine kullanılan
  /// yan menü. Menü sayfasındaki _buildSideNav ile aynı mantığı kullanır.
  Widget _buildSideNav(bool isDark) {
    return NavigationRail(
      backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      selectedIndex: 2,
      onDestinationSelected: _onBottomNavTap,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
      selectedLabelTextStyle: const TextStyle(
        color: Color(0xFF2E7D32),
        fontWeight: FontWeight.w700,
      ),
      unselectedIconTheme: IconThemeData(
        color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: Text('Menü'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: Text('Sepet'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available),
          label: Text('Rezervasyon'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profil'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    // 900px eşiği: altında mobil/tablet dikey düzen, üstünde masaüstü
    // (web) yan menülü düzen kullanılır.
    final isWide = screenWidth >= 900;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(isDark),
              const SizedBox(height: 16),
              _buildReservationsHeader(isDark),
              const SizedBox(height: 10),
              if (_rezervasyonlar.isEmpty)
                _buildEmptyState(isDark)
              else
                ..._rezervasyonlar.map(
                  (kayit) => _buildRezervasyonCard(kayit, isDark),
                ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          '🍽️ Rezervasyon',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: _navigateBackSafely,
        ),
      ),
      body: isWide
          ? Row(
              children: [
                _buildSideNav(isDark),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: isWide
          ? null
          : AppBottomNav(currentIndex: 2, onTap: _onBottomNavTap),
    );
  }

  Widget _buildFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masa ayırtmak için bilgileri doldurun',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            _textField(
              controller: _adSoyadController,
              label: 'Ad Soyad',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad Soyad zorunlu';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            _textField(
              controller: _telefonController,
              label: 'Telefon',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon zorunlu';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            _textField(
              controller: _kisiSayisiController,
              label: 'Kişi Sayısı',
              icon: Icons.groups,
              keyboardType: TextInputType.number,
              validator: (value) {
                final v = int.tryParse((value ?? '').trim());
                if (v == null || v <= 0) {
                  return 'Geçerli kişi sayısı girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _selectorTile(
                    icon: Icons.calendar_today,
                    title: _formatDate(_selectedDate),
                    subtitle: 'Tarih',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _selectorTile(
                    icon: Icons.access_time,
                    title: _formatTime(_selectedTime),
                    subtitle: 'Saat',
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _textField(
              controller: _notController,
              label: 'Not (Opsiyonel)',
              icon: Icons.note,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _rezervasyonOlustur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isSubmitting ? 'Gönderiliyor...' : 'Rezervasyon Oluştur',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsHeader(bool isDark) {
    return Text(
      'Son Rezervasyon Taleplerin',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Henüz rezervasyon talebi yok. Formu doldurarak ilk rezervasyonunu oluşturabilirsin.',
        style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
      ),
    );
  }

  Widget _buildRezervasyonCard(_RezervasyonKaydi kayit, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kayit.adSoyad,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '📞 ${kayit.telefon}',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '👥 ${kayit.kisiSayisi} kişi  •  🗓️ ${_formatDate(kayit.tarihSaat)}  •  🕒 ${_formatDateTimeHour(kayit.tarihSaat)}',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          if (kayit.not.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '📝 ${kayit.not}',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.7),
        ),
      ),
    );
  }

  Widget _selectorTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.26)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateTimeHour(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _RezervasyonKaydi {
  const _RezervasyonKaydi({
    required this.adSoyad,
    required this.telefon,
    required this.kisiSayisi,
    required this.tarihSaat,
    required this.not,
  });

  final String adSoyad;
  final String telefon;
  final int kisiSayisi;
  final DateTime tarihSaat;
  final String not;
}
