import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/sepet_provider.dart';
import '../services/api_service.dart';
import 'siparis_ozet_screen.dart';

class OdemeScreen extends StatefulWidget {
  final String siparisTipi;
  final String odemeTipi;
  final String musteriAdi;
  final String musteriTelefon;
  final String? musteriAdres;
  final int? uyeId;
  final double toplamTutar;

  const OdemeScreen({
    super.key,
    required this.siparisTipi,
    required this.odemeTipi,
    required this.musteriAdi,
    required this.musteriTelefon,
    this.musteriAdres,
    this.uyeId,
    required this.toplamTutar,
  });

  @override
  State<OdemeScreen> createState() => _OdemeScreenState();
}

class _OdemeScreenState extends State<OdemeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  // Form Kontrolcüleri
  final _kartIsimController = TextEditingController();
  final _kartNoController = TextEditingController();
  final _sktController = TextEditingController();
  final _cvvController = TextEditingController();

  final FocusNode _cvvFocusNode = FocusNode();
  bool _gonderiliyor = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: pi).animate(_animController);

    // CVV alanına tıklanınca kart 180 derece döner
    _cvvFocusNode.addListener(() {
      if (_cvvFocusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _cvvFocusNode.dispose();
    _kartIsimController.dispose();
    _kartNoController.dispose();
    _sktController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // --- KART TİPİNİ DİNAMİK TESPİT EDEN METOD ---
  String _getCardType(String number) {
    final cleanNumber = number.replaceAll(' ', '');

    if (cleanNumber.startsWith('4')) {
      return 'VISA';
    } else if (RegExp(
      r'^(5[1-5]|222[1-9]|22[3-9]|2[3-6]|27[0-1]|2720)',
    ).hasMatch(cleanNumber)) {
      return 'MASTERCARD';
    } else if (cleanNumber.startsWith('9792') || cleanNumber.startsWith('65')) {
      return 'TROY';
    } else if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return 'AMEX';
    }

    return '';
  }

  // --- KART TİPİNE GÖRE ARKAPLAN RENK GRADIENT'I ---
  LinearGradient _getCardGradient(String cardType) {
    switch (cardType) {
      case 'VISA':
        return const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'MASTERCARD':
        return const LinearGradient(
          colors: [Color(0xFF140505), Color(0xFF8B0000), Color(0xFFFF4500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'TROY':
        return const LinearGradient(
          colors: [Color(0xFF002B49), Color(0xFF005C97), Color(0xFF363795)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'AMEX':
        return const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // Siparişi tamamlama ve API'ye gönderme
  Future<void> _odemeVeSiparisTamamla(SepetProvider sepet) async {
    if (_kartIsimController.text.trim().isEmpty) {
      _showSnackBar('Lütfen kart üzerindeki ismi girin', Colors.orange);
      return;
    }
    if (_kartNoController.text.replaceAll(' ', '').length < 16) {
      _showSnackBar('Geçerli bir kart numarası girin', Colors.orange);
      return;
    }
    if (_sktController.text.length < 5) {
      _showSnackBar(
        'Geçerli bir son kullanma tarihi girin (AA/YY)',
        Colors.orange,
      );
      return;
    }
    if (_cvvController.text.length < 3) {
      _showSnackBar('Lütfen 3 haneli CVV kodunu girin', Colors.orange);
      return;
    }

    setState(() => _gonderiliyor = true);

    try {
      final ozetUrunler = sepet.sepet
          .map(
            (item) => SiparisOzetItemData(
              urunAdi: item.urun.urunAdi,
              adet: item.adet,
              birimFiyat: item.urun.fiyat,
              not: item.not,
            ),
          )
          .toList();
      final araToplam = sepet.toplamFiyat;
      final teslimatUcreti = widget.siparisTipi == 'SALON' ? 0.0 : 9.99;

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
        siparisTipi: widget.siparisTipi,
        odemeTipi: widget.odemeTipi,
        musteriAdi: widget.musteriAdi,
        musteriTelefon: widget.musteriTelefon,
        musteriAdres: widget.musteriAdres,
        uyeId: widget.uyeId,
        detaylar: detaylar,
      );

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final siparisId = (data?['siparisId'] as num?)?.toInt();
        final toplamTutar =
            (data?['toplamTutar'] as num?)?.toDouble() ??
            (araToplam + teslimatUcreti);

        sepet.sepetiTemizle();
        _showSnackBar('🎉 Ödeme Başarılı! Siparişiniz alındı.', Colors.green);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SiparisOzetScreen(
                siparisId: siparisId,
                siparisTipi: widget.siparisTipi,
                odemeTipi: widget.odemeTipi,
                musteriAdi: widget.musteriAdi,
                musteriTelefon: widget.musteriTelefon,
                musteriAdres: widget.musteriAdres,
                urunler: ozetUrunler,
                araToplam: araToplam,
                teslimatUcreti: teslimatUcreti,
                toplamTutar: toplamTutar,
              ),
            ),
          );
        }
      } else {
        _showSnackBar(result['message'] ?? 'Ödeme alınamadı', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    final sepet = context.watch<SepetProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardType = _getCardType(_kartNoController.text);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        title: const Text(
          '💳 Kart ile Ödeme',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // --- GERÇEK ORANLI (1.586) DÖNEN KART WİDGET'I ---
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final angle = _animation.value;
                    final isBack = angle >= (pi / 2);

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Perspektif efekti
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: isBack
                          ? Transform.scale(
                              scaleX: -1,
                              child: _buildCardBack(cardType),
                            )
                          : _buildCardFront(cardType),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- KART FORM ALANLARI ---
                _buildInputField(
                  controller: _kartIsimController,
                  label: 'Kart Üzerindeki İsim',
                  hint: 'MEHMET YILMAZ',
                  icon: Icons.person_outline,
                  capitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 14),
                _buildInputField(
                  controller: _kartNoController,
                  label: 'Kart Numarası',
                  hint: '4535 3453 4534 5435',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _sktController,
                        label: 'Son Kullanma (AA/YY)',
                        hint: '12/28',
                        icon: Icons.date_range,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateFormatter(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildInputField(
                        controller: _cvvController,
                        focusNode: _cvvFocusNode,
                        label: 'CVV / CVC',
                        hint: '123',
                        icon: Icons.lock_outline,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // --- ÖDEME YAP BUTONU ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _gonderiliyor
                        ? null
                        : () => _odemeVeSiparisTamamla(sepet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _gonderiliyor
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'İşlem Yapılıyor...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'ÖDEMEYİ TAMAMLA (${widget.toplamTutar.toStringAsFixed(2)} ₺)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- KART ÖN YÜZÜ ---
  Widget _buildCardFront(String cardType) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: _getCardGradient(cardType),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Çip Görünümü
                Container(
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade600, width: 1),
                  ),
                ),
                const Text(
                  "PLATİN",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _kartNoController.text.isEmpty
                    ? "•••• •••• •••• ••••"
                    : _kartNoController.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  letterSpacing: 2.5,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "KART SAHİBİ",
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _kartIsimController.text.isEmpty
                            ? "AD SOYAD"
                            : _kartIsimController.text.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SON KULLANMA",
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 8,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _sktController.text.isEmpty
                          ? "AA/YY"
                          : _sktController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // --- DİNAMİK VISA / MASTERCARD / TROY LOGO ALANI ---
                SizedBox(
                  height: 24,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      cardType,
                      key: ValueKey(cardType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.5,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- KART ARKA YÜZÜ (CVV) ---
  Widget _buildCardBack(String cardType) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _getCardGradient(cardType),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(width: double.infinity, height: 40, color: Colors.black),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "GÜVENLİK KODU (CVV)",
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 9),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 36,
                    padding: const EdgeInsets.only(right: 12),
                    alignment: Alignment.centerRight,
                    color: Colors.white,
                    child: Text(
                      _cvvController.text.isEmpty ? "•••" : _cvvController.text,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      onChanged: (val) => setState(() {}),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepOrange),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    var newString = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) newString += ' ';
      newString += text[i];
    }
    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');
    var newString = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2) newString += '/';
      newString += text[i];
    }
    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
