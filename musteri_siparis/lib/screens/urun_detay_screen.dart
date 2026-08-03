import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sepet_item.dart';
import '../models/urun.dart';
import '../providers/sepet_provider.dart';
import '../services/api_service.dart';

class UrunDetayScreen extends StatefulWidget {
  final Urun urun;

  const UrunDetayScreen({super.key, required this.urun});

  @override
  State<UrunDetayScreen> createState() => _UrunDetayScreenState();
}

class _UrunDetayScreenState extends State<UrunDetayScreen> {
  List<Urun> _tatliOnerileri = [];
  List<Urun> _icecekOnerileri = [];
  final Set<int> _seciliTatliIds = <int>{};
  final Set<int> _seciliIcecekIds = <int>{};
  final TextEditingController _notController = TextEditingController();
  bool _tatliTumunuGoster = false;
  bool _icecekTumunuGoster = false;
  int _adet = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _onerileriYukle();
  }

  @override
  void dispose() {
    _notController.dispose();
    super.dispose();
  }

  Future<void> _onerileriYukle() async {
    setState(() => _isLoading = true);
    try {
      final tatlilar = await ApiService.getUrunlerByKategoriId(6);
      final sicakIcecekler = await ApiService.getUrunlerByKategoriId(7);
      final sogukIcecekler = await ApiService.getUrunlerByKategoriId(8);

      final icecekMap = <int, Urun>{
        for (final urun in [...sicakIcecekler, ...sogukIcecekler])
          urun.urunId: urun,
      };

      setState(() {
        _tatliOnerileri = tatlilar
            .where((u) => u.urunId != widget.urun.urunId)
            .take(8)
            .toList();
        _icecekOnerileri = icecekMap.values
            .where((u) => u.urunId != widget.urun.urunId)
            .take(8)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _getResimDosyasi(String urunAdi) {
    final resimMap = {
      'Mercimek Çorbası': 'assets/images/mercimek_corbasi.jpg',
      'Ezogelin Çorbası': 'assets/images/ezogelin_corbasi.jpg',
      'Yayla Çorbası': 'assets/images/yayla_corbasi.jpg',
      'Tavuk Suyu Çorbası': 'assets/images/tavuk_suyu_corbasi.jpg',
      'İşkembe Çorbası': 'assets/images/iskembe_corbasi.jpg',
      'Kuru Fasulye': 'assets/images/kuru_fasulye.jpg',
      'Nohut Yemeği': 'assets/images/nohut.jpg',
      'Tavuk Sote': 'assets/images/tavuk_sote.jpg',
      'Et Sote': 'assets/images/et_sote.jpg',
      'Karnıyarık': 'assets/images/karniyarik.jpg',
      'Mantı': 'assets/images/manti.jpg',
      'İskender': 'assets/images/İskender.jpg',
      'Adana Kebap': 'assets/images/adana_kebab.jpg',
      'Urfa Kebap': 'assets/images/urfa_kebab.jpg',
      'Tavuk Şiş': 'assets/images/tavuk_şiş.jpg',
      'Kuzu Şiş': 'assets/images/kuzu_sis.jpg',
      'Karışık Izgara': 'assets/images/karisik_izgara.jpg',
      'Köfte': 'assets/images/köfte.jpg',
      'Tavuk Kanat': 'assets/images/tavuk_kanat.jpg',
      'Pirzola': 'assets/images/pirzola.jpg',
      'Kıymalı Pide': 'assets/images/kiymali-pide.jpg',
      'Kaşarlı Pide': 'assets/images/kasarlı_pide.jpg',
      'Kuşbaşı Pide': 'assets/images/kusbasi_pide.jpg',
      'Karışık Pide': 'assets/images/karisik_pide.jpg',
      'Lahmacun': 'assets/images/lahmacun.jpg',
      'Fındık Lahmacun': 'assets/images/findik_lahmacun.jpg',
      'Çoban Salata': 'assets/images/coban_salata.jpg',
      'Mevsim Salata': 'assets/images/mevsim_salata.jpg',
      'Gavurdağı Salata': 'assets/images/gavurdaği_salata.jpg',
      'Haydari': 'assets/images/haydari.jpg',
      'Ezme': 'assets/images/ezme.jpg',
      'Cacık': 'assets/images/cacik.jpg',
      'Künefe': 'assets/images/kunefe.jpg',
      'Sütlaç': 'assets/images/sütlaç.jpg',
      'Baklava (porsiyon)': 'assets/images/baklava.jpg',
      'Kazandibi': 'assets/images/kazandibi.jpg',
      'Katmer': 'assets/images/katmer.jpg',
      'Profiterol': 'assets/images/profiterol.jpg',
      'Kuzu Kulağı': 'assets/images/kuzu_kulagi.jpg',
      'Çay': 'assets/images/cey.jpg',
      'Türk Kahvesi': 'assets/images/turk_kahvesi.jpg',
      'Filtre Kahve': 'assets/images/filtre_kahve.jpg',
      'Salep': 'assets/images/salep.jpg',
      'Ayran': 'assets/images/ayran.jpg',
      'Kola': 'assets/images/kola.jpg',
      'Su': 'assets/images/su.jpg',
      'Şalgam Suyu': 'assets/images/salgam_suyu.jpg',
      'Maden Suyu': 'assets/images/maden_suyu.jpg',
    };
    return resimMap[urunAdi] ?? 'assets/images/login_logo_v2.png';
  }

  String _kategoriAdi(int kategoriId) {
    switch (kategoriId) {
      case 1:
        return 'Çorba';
      case 2:
        return 'Ana Yemek';
      case 3:
        return 'Izgara';
      case 4:
        return 'Pide & Lahmacun';
      case 5:
        return 'Salata & Meze';
      case 6:
        return 'Tatlı';
      case 7:
        return 'Sıcak İçecek';
      case 8:
        return 'İçecek';
      default:
        return 'Ürün';
    }
  }

  String _fiyatYaz(double fiyat) {
    return fiyat.toStringAsFixed(2).replaceAll('.', ',');
  }

  List<Urun> get _seciliEkUrunler {
    final seciliTatli = _tatliOnerileri.where(
      (u) => _seciliTatliIds.contains(u.urunId),
    );
    final seciliIcecek = _icecekOnerileri.where(
      (u) => _seciliIcecekIds.contains(u.urunId),
    );
    return [...seciliTatli, ...seciliIcecek];
  }

  double get _toplamTutar {
    final anaUrunToplami = widget.urun.fiyat * _adet;
    final eklerToplami = _seciliEkUrunler.fold<double>(
      0,
      (sum, urun) => sum + urun.fiyat,
    );
    return anaUrunToplami + eklerToplami;
  }

  void _sepeteEkle(Urun urun) {
    final sepetProvider = Provider.of<SepetProvider>(context, listen: false);

    sepetProvider.sepeteEkle(
      SepetItem(
        urun: urun,
        adet: _adet,
        not: _notController.text.trim().isEmpty
            ? null
            : _notController.text.trim(),
      ),
    );

    for (final ekUrun in _seciliEkUrunler) {
      sepetProvider.sepeteEkle(SepetItem(urun: ekUrun, adet: 1));
    }
  }

  Widget _buildOpsiyonBolumu({
    required String baslik,
    required String altBaslik,
    required List<Urun> urunler,
    required Set<int> seciliIds,
    required void Function(int urunId, bool secildi) onDegisti,
    required bool tumunuGoster,
    required VoidCallback onTumunuGosterToggle,
  }) {
    if (urunler.isEmpty) {
      return const SizedBox.shrink();
    }

    final gorunenListe = tumunuGoster ? urunler : urunler.take(5).toList();
    final kalanSayi = urunler.length - gorunenListe.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 34 / 2,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202124),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'İsteğe Bağlı',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            altBaslik,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 10),
          ...gorunenListe.map((ekUrun) {
            final secili = seciliIds.contains(ekUrun.urunId);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      _getResimDosyasi(ekUrun.urunAdi),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.green.withValues(alpha: 0.1),
                        child: const Icon(Icons.fastfood, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ekUrun.urunAdi,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    '+${_fiyatYaz(ekUrun.fiyat)} TL',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: secili,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (value) {
                      onDegisti(ekUrun.urunId, value ?? false);
                    },
                  ),
                ],
              ),
            );
          }),
          if (urunler.length > 5)
            InkWell(
              onTap: onTumunuGosterToggle,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tumunuGoster
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tumunuGoster
                          ? 'Daha az göster'
                          : '$kalanSayi seçeneği gör',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urun = widget.urun;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F2),
      appBar: AppBar(
        title: Text(urun.urunAdi),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 140),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        _getResimDosyasi(urun.urunAdi),
                        height: 210,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 210,
                            color: Colors.green.withValues(alpha: 0.08),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.fastfood,
                              size: 56,
                              color: Color(0xFF2E7D32),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      urun.urunAdi,
                      style: const TextStyle(
                        fontSize: 40 / 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fiyatYaz(urun.fiyat)} TL',
                      style: const TextStyle(
                        fontSize: 28 / 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _kategoriAdi(urun.kategoriId),
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (urun.aciklama?.isNotEmpty ?? false)
                          ? urun.aciklama!
                          : 'Bu ürün için açıklama bulunmuyor.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOpsiyonBolumu(
                      baslik: 'Yanında tatlı ister misiniz?',
                      altBaslik: 'Menümüzdeki tatlılar',
                      urunler: _tatliOnerileri,
                      seciliIds: _seciliTatliIds,
                      tumunuGoster: _tatliTumunuGoster,
                      onDegisti: (urunId, secildi) {
                        setState(() {
                          if (secildi) {
                            _seciliTatliIds.add(urunId);
                          } else {
                            _seciliTatliIds.remove(urunId);
                          }
                        });
                      },
                      onTumunuGosterToggle: () {
                        setState(() {
                          _tatliTumunuGoster = !_tatliTumunuGoster;
                        });
                      },
                    ),
                    _buildOpsiyonBolumu(
                      baslik: 'Yanında içecek ister misiniz?',
                      altBaslik: 'Menümüzdeki içecekler',
                      urunler: _icecekOnerileri,
                      seciliIds: _seciliIcecekIds,
                      tumunuGoster: _icecekTumunuGoster,
                      onDegisti: (urunId, secildi) {
                        setState(() {
                          if (secildi) {
                            _seciliIcecekIds.add(urunId);
                          } else {
                            _seciliIcecekIds.remove(urunId);
                          }
                        });
                      },
                      onTumunuGosterToggle: () {
                        setState(() {
                          _icecekTumunuGoster = !_icecekTumunuGoster;
                        });
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ürün Notu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Örn: Soğansız, acısız, ekstra limon',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (_adet > 1) {
                                      setState(() => _adet--);
                                    }
                                  },
                                  icon: const Icon(Icons.remove),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text(
                                  '$_adet',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _adet++),
                                  icon: const Icon(Icons.add),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _sepeteEkle(urun);
                                Navigator.pop(context, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Sepete Ekle (${_fiyatYaz(_toplamTutar)} TL)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
