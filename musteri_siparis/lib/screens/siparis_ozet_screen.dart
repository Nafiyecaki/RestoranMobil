import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'menu_screen.dart';

class SiparisOzetItemData {
  final String urunAdi;
  final int adet;
  final double birimFiyat;
  final String? not;

  const SiparisOzetItemData({
    required this.urunAdi,
    required this.adet,
    required this.birimFiyat,
    this.not,
  });

  double get satirToplami => birimFiyat * adet;
}

class SiparisOzetScreen extends StatefulWidget {
  final int? siparisId;
  final String siparisTipi;
  final String odemeTipi;
  final String musteriAdi;
  final String musteriTelefon;
  final String? musteriAdres;
  final List<SiparisOzetItemData> urunler;
  final double araToplam;
  final double teslimatUcreti;
  final double toplamTutar;
  final String? initialDurum;

  const SiparisOzetScreen({
    super.key,
    this.siparisId,
    required this.siparisTipi,
    required this.odemeTipi,
    required this.musteriAdi,
    required this.musteriTelefon,
    this.musteriAdres,
    required this.urunler,
    required this.araToplam,
    required this.teslimatUcreti,
    required this.toplamTutar,
    this.initialDurum,
  });

  @override
  State<SiparisOzetScreen> createState() => _SiparisOzetScreenState();
}

class _SiparisOzetScreenState extends State<SiparisOzetScreen> {
  // TODO: Gerçek müşteri hizmetleri numarasıyla değiştirin.
  static const String _musteriHizmetleriTelefon = '08501234567';

  late String _siparisTipi;
  late String _odemeTipi;
  late String _musteriAdi;
  late String _musteriTelefon;
  String? _musteriAdres;
  late List<SiparisOzetItemData> _urunler;
  late double _araToplam;
  late double _teslimatUcreti;
  late double _toplamTutar;

  String _durumMetni = 'Sipariş Alındı';
  String? _rawDurum;
  Timer? _pollTimer;
  bool _isRefreshing = false;
  bool _hasFirstSync = false;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _siparisTipi = widget.siparisTipi;
    _odemeTipi = widget.odemeTipi;
    _musteriAdi = widget.musteriAdi;
    _musteriTelefon = widget.musteriTelefon;
    _musteriAdres = widget.musteriAdres;
    _urunler = List<SiparisOzetItemData>.from(widget.urunler);
    _araToplam = widget.araToplam;
    _teslimatUcreti = widget.teslimatUcreti;
    _toplamTutar = widget.toplamTutar;
    _durumMetni = _friendlyStatusText(widget.initialDurum);
    _rawDurum = widget.initialDurum;

    if (widget.siparisId != null) {
      _refreshOrderStatus();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 7),
        (_) => _refreshOrderStatus(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatSiparisTipi(String value) {
    switch (value) {
      case 'PAKET_SERVIS':
        return 'Paket Servis';
      case 'GEL_AL':
        return 'Gel-Al';
      case 'SALON':
        return 'Salonda Ye';
      default:
        return value;
    }
  }

  String _formatOdemeTipi(String value) {
    switch (value) {
      case 'KAPIDA_ODEME':
        return 'Kapıda Ödeme (Kurye)';
      case 'NAKIT':
        return 'Kapıda Ödeme (Kurye)';
      case 'KREDI_KARTI':
        return 'Kredi Kartı';
      case 'ONLINE':
        return 'Online Ödeme';
      default:
        return value;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Sipariş Alındı':
        return Icons.receipt_long_rounded;
      case 'Hazırlanıyor':
        return Icons.restaurant_menu_rounded;
      case 'Kuryeye Verildi':
        return Icons.inventory_2_rounded;
      case 'Kurye Yolda':
        return Icons.delivery_dining_rounded;
      case 'Teslim Edildi':
        return Icons.home_rounded;
      default:
        return Icons.circle;
    }
  }

  IconData _infoIcon(String label) {
    switch (label) {
      case 'Sipariş No':
        return Icons.tag_rounded;
      case 'Müşteri':
        return Icons.person_rounded;
      case 'Telefon':
        return Icons.phone_rounded;
      case 'Adres':
        return Icons.location_on_rounded;
      case 'Sipariş Tipi':
        return Icons.local_shipping_rounded;
      case 'Ödeme Tipi':
        return Icons.payments_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  int _statusStepFromRaw(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('teslim')) return 4;
    // Sadece gerçekten yola çıkınca (YOLDA / dagitim) "Kurye Yolda" gösterilir.
    if (s.contains('yolda') || s.contains('dagitim') || s.contains('dağıtım')) {
      return 3;
    }
    // "KURYEDE" durumu kuryenin siparişi teslim aldığı ama henüz yola
    // çıkmadığı anı temsil eder; ayrı bir adım olarak gösterilir.
    if (s.contains('kuryede')) {
      return 2;
    }
    if (s.contains('hazır') || s.contains('hazir') || s.contains('piş')) {
      return 1;
    }
    return 0;
  }

  String _friendlyStatusText(String? raw) {
    final step = _statusStepFromRaw(raw);
    if (step == 4) return 'Teslim Edildi';
    if (step == 3) return 'Kurye Yolda';
    if (step == 2) return 'Kuryeye Verildi';
    if (step == 1) return 'Hazırlanıyor';
    return 'Sipariş Alındı';
  }

  List<SiparisOzetItemData> _extractItems(Map<String, dynamic> order) {
    final rawList =
        order['detaylar'] ?? order['siparisDetaylari'] ?? order['items'] ?? [];
    if (rawList is! List) return _urunler;

    final parsed = rawList.whereType<Map>().map((raw) {
      final map = raw.map((k, v) => MapEntry(k.toString(), v));
      final qty = (map['adet'] ?? map['quantity'] ?? 1) as num;
      final unitPrice =
          (map['birimFiyat'] ?? map['fiyat'] ?? map['price'] ?? 0) as num;
      return SiparisOzetItemData(
        urunAdi: (map['urunAdi'] ?? map['name'] ?? 'Ürün').toString(),
        adet: qty.toInt(),
        birimFiyat: unitPrice.toDouble(),
        not: map['detayNot']?.toString(),
      );
    }).toList();

    return parsed.isEmpty ? _urunler : parsed;
  }

  Future<void> _refreshOrderStatus() async {
    if (_isRefreshing || widget.siparisId == null) return;
    _isRefreshing = true;

    try {
      final activeOrders = await ApiService.getMyOrders();
      Map<String, dynamic>? order;

      for (final o in activeOrders) {
        final id = (o['siparisId'] as num?)?.toInt();
        if (id == widget.siparisId) {
          order = o;
          break;
        }
      }

      if (order == null) {
        final historyOrders = await ApiService.getOrderHistory();
        for (final o in historyOrders) {
          final id = (o['siparisId'] as num?)?.toInt();
          if (id == widget.siparisId) {
            order = o;
            break;
          }
        }
      }

      if (order == null || !mounted) return;
      final currentOrder = order;

      final previousStatus = _durumMetni;
      final rawStatus = currentOrder['siparisDurumu']?.toString();
      final newStatus = _friendlyStatusText(rawStatus);

      final newSiparisTipi = (currentOrder['siparisTipi'] ?? _siparisTipi)
          .toString();
      final newOdemeTipi =
          (currentOrder['odemeTipi'] ??
                  currentOrder['odemeTuru'] ??
                  currentOrder['odemeYontemi'] ??
                  _odemeTipi)
              .toString();
      final newUrunler = _extractItems(currentOrder);
      final newTeslimat =
          (currentOrder['teslimatUcreti'] as num?)?.toDouble() ??
          (newSiparisTipi == 'SALON' ? 0.0 : _teslimatUcreti);

      final itemsToplam = newUrunler.fold<double>(
        0,
        (sum, item) => sum + item.satirToplami,
      );
      final newToplam =
          (currentOrder['toplamTutar'] as num?)?.toDouble() ??
          (itemsToplam + newTeslimat);
      final newAraToplam = itemsToplam > 0
          ? itemsToplam
          : (newToplam - newTeslimat).clamp(0.0, double.infinity);

      setState(() {
        _durumMetni = newStatus;
        _rawDurum = rawStatus;
        _siparisTipi = newSiparisTipi;
        _odemeTipi = newOdemeTipi;
        _musteriAdi =
            (currentOrder['musteriAdi']?.toString().trim().isNotEmpty ?? false)
            ? currentOrder['musteriAdi'].toString()
            : _musteriAdi;
        _musteriTelefon =
            (currentOrder['musteriTelefon']?.toString().trim().isNotEmpty ??
                false)
            ? currentOrder['musteriTelefon'].toString()
            : _musteriTelefon;
        _musteriAdres =
            (currentOrder['musteriAdres']?.toString().trim().isNotEmpty ??
                false)
            ? currentOrder['musteriAdres'].toString()
            : _musteriAdres;
        _urunler = newUrunler;
        _teslimatUcreti = newTeslimat;
        _araToplam = newAraToplam;
        _toplamTutar = newToplam;
      });

      final statusChanged = previousStatus != _durumMetni;
      if (_hasFirstSync && statusChanged && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş durumu güncellendi: $_durumMetni'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
      _hasFirstSync = true;
    } catch (_) {
      // Sessizce geç: otomatik yenileme bir sonraki döngüde tekrar deneyecek.
    } finally {
      _isRefreshing = false;
    }
  }

  bool get _iptalEdildi => (_rawDurum ?? '').toUpperCase().contains('IPTAL');

  /// Kurye siparişi teslim aldıysa (kuryede/yolda/dagitimda) artık
  /// uygulama üzerinden doğrudan iptal/iade yapılamaz.
  bool get _kuryeTeslimAldiMi {
    final s = (_rawDurum ?? '').toLowerCase();
    return s.contains('kuryede') ||
        s.contains('yolda') ||
        s.contains('dagitim') ||
        s.contains('dağıtım');
  }

  bool get _siparisTamamlanmisMi {
    final s = (_rawDurum ?? '').toUpperCase();
    const bittiDurumlar = [
      'TAMAMLANDI',
      'ODENDI',
      'IPTAL',
      'TESLIM EDILDI',
      'IADE',
      'KISMI_IADE',
    ];
    return bittiDurumlar.any((d) => s.contains(d));
  }

  bool get _siparisIptalEdilebilir {
    if (widget.siparisId == null) return false;
    if (_kuryeTeslimAldiMi) return false;
    return !_siparisTamamlanmisMi;
  }

  /// Kurye teslim aldığı için uygulamadan iptal edilemeyen ama sipariş
  /// henüz tamamlanmamış (teslim edilmemiş) durumlarda müşteri
  /// hizmetlerine yönlendirme butonu gösterilir.
  bool get _musteriHizmetleriGerekli {
    if (widget.siparisId == null) return false;
    if (_siparisTamamlanmisMi) return false;
    return _kuryeTeslimAldiMi;
  }

  Future<void> _musteriHizmetleriniAra() async {
    final uri = Uri(scheme: 'tel', path: _musteriHizmetleriTelefon);
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        _telefonNumarasiniKopyala();
      }
    } catch (_) {
      if (mounted) {
        _telefonNumarasiniKopyala();
      }
    }
  }

  void _telefonNumarasiniKopyala() {
    Clipboard.setData(const ClipboardData(text: _musteriHizmetleriTelefon));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Arama başlatılamadı. Numara kopyalandı: $_musteriHizmetleriTelefon',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _musteriHizmetleriDialogGoster() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kurye Siparişi Teslim Aldı'),
        content: const Text(
          'Kurye siparişinizi teslim aldığı için bu aşamada uygulama '
          'üzerinden iptal veya iade işlemi yapılamıyor. İptal/iade '
          'talebiniz için lütfen müşteri hizmetlerimizle iletişime geçin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _musteriHizmetleriniAra();
            },
            child: const Text('Müşteri Hizmetlerini Ara'),
          ),
        ],
      ),
    );
  }

  Future<void> _siparisiIptalEt() async {
    if (widget.siparisId == null || _isCanceling) return;

    // Kurye teslim aldıysa doğrudan iptale izin verme, müşteri
    // hizmetlerine yönlendir.
    if (_kuryeTeslimAldiMi) {
      await _musteriHizmetleriDialogGoster();
      return;
    }

    final sebepController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Siparişi İptal Et'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu siparişi iptal etmek istediğinize emin misiniz? '
                'Bu işlem geri alınamaz.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: sebepController,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'İptal nedeni',
                  hintText: 'Lütfen iptal nedeninizi yazın',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'İptal nedeni zorunludur';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Evet, İptal Et'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    final sebep = sebepController.text.trim();

    setState(() => _isCanceling = true);

    // NOT: ApiService.siparisIptalEt metodunun `sebep` parametresini kabul
    // edip backend'e iletmesi gerekiyor. Eğer metod imzanız farklıysa
    // (örn. sadece siparisId alıyorsa) api_service.dart içindeki
    // siparisIptalEt metodunu buna göre güncelleyin.
    final sonuc = await ApiService.siparisIptalEt(
      widget.siparisId!,
      sebep: sebep,
    );

    if (!mounted) return;
    setState(() => _isCanceling = false);

    if (sonuc['success'] == true) {
      _pollTimer?.cancel();
      setState(() {
        _rawDurum = 'IPTAL';
        _durumMetni = 'Sipariş Alındı';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (sonuc['message'] ?? '✅ Sipariş iptal edildi').toString(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (sonuc['message'] ?? '❌ Sipariş iptal edilemedi').toString(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2E7D32);
    const bg = Color(0xFFFAFAFA);
    const primaryText = Color(0xFF111827);
    const secondaryText = Color(0xFF6B7280);
    final teslimSuresi = '25–35 dk';
    final indirim = 0.0;

    final currentStep = _statusStepFromRaw(_rawDurum);

    final statusItems = [
      ('Sipariş Alındı', currentStep >= 0),
      ('Hazırlanıyor', currentStep >= 1),
      ('Kuryeye Verildi', currentStep >= 2),
      ('Kurye Yolda', currentStep >= 3),
      ('Teslim Edildi', currentStep >= 4),
    ];

    String musteriAdresText = (_musteriAdres ?? '').trim();
    if (musteriAdresText.isEmpty) {
      musteriAdresText = 'Belirtilmedi';
    }

    final infoRows = [
      ('Sipariş No', widget.siparisId != null ? '#${widget.siparisId}' : '-'),
      ('Müşteri', _musteriAdi),
      ('Telefon', _musteriTelefon),
      ('Adres', musteriAdresText),
      ('Sipariş Tipi', _formatSiparisTipi(_siparisTipi)),
      ('Ödeme Tipi', _formatOdemeTipi(_odemeTipi)),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryText,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Sipariş Durumu',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: _iptalEdildi ? Colors.red : primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iptalEdildi
                                ? Icons.close_rounded
                                : Icons.check_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _iptalEdildi
                            ? 'Siparişiniz İptal Edildi'
                            : 'Siparişiniz Başarıyla Alındı',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _iptalEdildi
                            ? 'Bu sipariş talebiniz üzerine iptal edildi.'
                            : 'Restoran siparişinizi onayladı.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _card(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tahmini Teslimat',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    teslimSuresi,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.siparisId == null ? 'Statik' : 'Canlı',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sipariş Durumu',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Anlık Durum: $_durumMetni',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(statusItems.length, (index) {
                              final isDone = statusItems[index].$2;
                              final isLast = index == statusItems.length - 1;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? primary
                                                : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDone
                                                  ? primary
                                                  : const Color(0xFFD1D5DB),
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            isDone
                                                ? Icons.check_rounded
                                                : _statusIcon(
                                                    statusItems[index].$1,
                                                  ),
                                            size: isDone ? 15 : 12,
                                            color: isDone
                                                ? Colors.white
                                                : secondaryText,
                                          ),
                                        ),
                                        if (!isLast)
                                          Container(
                                            width: 2,
                                            height: 34,
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            color: isDone
                                                ? primary
                                                : const Color(0xFFE5E7EB),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      statusItems[index].$1,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: isDone
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isDone
                                            ? primaryText
                                            : secondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.badge_rounded, color: primary),
                                SizedBox(width: 8),
                                Text(
                                  'Müşteri Bilgileri',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: primaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...infoRows.map((row) {
                              final isAddress = row.$1 == 'Adres';
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isAddress ? 14 : 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Icon(
                                        _infoIcon(row.$1),
                                        size: 16,
                                        color: secondaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            row.$1,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: secondaryText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            row.$2,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: primaryText,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.fastfood_rounded, color: primary),
                                SizedBox(width: 8),
                                Text(
                                  'Sipariş Ürünleri',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: primaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ..._urunler.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFEDEDED),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.ramen_dining_rounded,
                                        color: Color(0xFF6B7280),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.urunAdi,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: primaryText,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${item.adet} x',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: secondaryText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.satirToplami.toStringAsFixed(2)} ₺',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: primaryText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.summarize_rounded, color: primary),
                                SizedBox(width: 8),
                                Text(
                                  'Ödeme Özeti',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: primaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _priceRow('Ara Toplam', _araToplam),
                            _priceRow('Teslimat', _teslimatUcreti),
                            _priceRow('İndirim', indirim),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFE8E8E8),
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Toplam',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: primaryText,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(_toplamTutar - indirim).toStringAsFixed(2)} ₺',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      if (_siparisIptalEdilebilir)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isCanceling ? null : _siparisiIptalEt,
                            icon: _isCanceling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cancel_outlined, size: 20),
                            label: Text(
                              _isCanceling
                                  ? 'İptal Ediliyor...'
                                  : 'Siparişi İptal Et',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              disabledBackgroundColor: Colors.red.withValues(
                                alpha: 0.6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      if (_siparisIptalEdilebilir) const SizedBox(height: 12),
                      if (_musteriHizmetleriGerekli)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _musteriHizmetleriDialogGoster,
                            icon: const Icon(
                              Icons.support_agent_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'Müşteri Hizmetlerine Bağlan',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF6C00),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      if (_musteriHizmetleriGerekli) const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                              return;
                            }
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const MenuScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home_rounded, size: 20),
                          label: const Text(
                            'Ana Sayfaya Dön',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryText,
                            side: const BorderSide(color: Color(0xFFE8E8E8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String title, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              color: const Color(0xFF6B7280),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            '${amount.toStringAsFixed(2)} ₺',
            style: TextStyle(
              fontFamily: 'Inter',
              color: const Color(0xFF111827),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
