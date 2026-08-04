import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/urun.dart';
import '../providers/sepet_provider.dart';
import 'urun_detay_screen.dart';

class ProfileFavoritesScreen extends StatelessWidget {
  const ProfileFavoritesScreen({super.key, required this.products});

  final List<Urun> products;

  static const Color _primaryColor = Color(0xFF2E7D32);

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

  IconData _getCategoryIcon(int kategoriId) {
    switch (kategoriId) {
      case 1:
        return Icons.soup_kitchen;
      case 2:
        return Icons.restaurant;
      case 3:
        return Icons.outdoor_grill;
      case 4:
        return Icons.local_pizza;
      case 5:
        return Icons.eco;
      case 6:
        return Icons.cake;
      case 7:
        return Icons.local_cafe;
      case 8:
        return Icons.local_drink;
      default:
        return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favoriteIds = context.watch<SepetProvider>().favoriler.toSet();
    final favoriteProducts = products
        .where((urun) => favoriteIds.contains(urun.urunId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: favoriteProducts.isEmpty
          ? Center(
              child: Text(
                'Henüz favori ürün eklenmedi',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.74,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                final urun = favoriteProducts[index];
                final resimDosyasi = _getResimDosyasi(urun.urunAdi);
                final isFavori = favoriteIds.contains(urun.urunId);

                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UrunDetayScreen(urun: urun),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF171717) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF303030)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: Image.asset(
                                  resimDosyasi,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        _getCategoryIcon(urun.kategoriId),
                                        size: 40,
                                        color: Colors.green[300],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () {
                                  context.read<SepetProvider>().favoriEkleCikar(
                                    urun.urunId,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: isFavori
                                        ? Colors.red
                                        : (isDark
                                              ? const Color(0xFF252525)
                                              : Colors.white),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isFavori
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavori
                                        ? Colors.white
                                        : Colors.grey[500],
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                urun.urunAdi,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                urun.aciklama ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₺${urun.fiyat.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
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
