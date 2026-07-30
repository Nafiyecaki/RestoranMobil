// lib/screens/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sepet_provider.dart';
import '../models/sepet_item.dart';
import '../models/urun.dart';
import '../services/api_service.dart';
import 'sepet_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedKategori = 'Tümü';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Urun> _tumUrunler = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _kategoriler = [
    'Tümü',
    'Çorbalar',
    'Ana Yemekler',
    'Izgaralar',
    'Pide & Lahmacun',
    'Salatalar & Mezeler',
    'Tatlılar',
    'Sıcak İçecekler',
    'İçecekler',
  ];

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
    return resimMap[urunAdi] ?? 'assets/images/brandlogo.jpg';
  }

  @override
  void initState() {
    super.initState();
    _menuleriYukle();
  }

  Future<void> _menuleriYukle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final urunler = await ApiService.getUrunler();
      setState(() {
        _tumUrunler = urunler;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Urun> get _filtrelenmisUrunler {
    var urunler = _tumUrunler;

    if (_selectedKategori != 'Tümü') {
      int kategoriId = _kategoriAdiToId(_selectedKategori);
      urunler = urunler.where((u) => u.kategoriId == kategoriId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      urunler = urunler.where((u) {
        return u.urunAdi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (u.aciklama?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return urunler;
  }

  int _kategoriAdiToId(String kategoriAdi) {
    switch (kategoriAdi) {
      case 'Çorbalar':
        return 1;
      case 'Ana Yemekler':
        return 2;
      case 'Izgaralar':
        return 3;
      case 'Pide & Lahmacun':
        return 4;
      case 'Salatalar & Mezeler':
        return 5;
      case 'Tatlılar':
        return 6;
      case 'Sıcak İçecekler':
        return 7;
      case 'İçecekler':
        return 8;
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text(
          '🍽️ Lezzet Durağı',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<SepetProvider>(
            builder: (context, sepetProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SepetScreen()),
                      );
                    },
                  ),
                  if (sepetProvider.sepet.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${sepetProvider.toplamUrunSayisi}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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
                  Text('Menü yükleniyor...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _menuleriYukle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildCategoryFilter(),
                    Expanded(
                      child: _filtrelenmisUrunler.isEmpty
                          ? const Center(
                              child: Text(
                                'Ürün bulunamadı 😔',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _filtrelenmisUrunler.length,
                              itemBuilder: (context, index) {
                                final urun = _filtrelenmisUrunler[index];
                                return _buildProductCard(urun);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Yemek veya içecek ara...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _kategoriler.length,
        itemBuilder: (context, index) {
          final kategori = _kategoriler[index];
          final isSelected = _selectedKategori == kategori;
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: GestureDetector(
              onTap: () => setState(() => _selectedKategori = kategori),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  kategori,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Urun urun) {
    final sepetProvider = Provider.of<SepetProvider>(context, listen: false);
    final isFavori = sepetProvider.isFavori(urun.urunId);
    final resimDosyasi = _getResimDosyasi(urun.urunAdi);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.green.withOpacity(0.1),
          width: 1,
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
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.green.withOpacity(0.08),
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
                  onTap: () => sepetProvider.favoriEkleCikar(urun.urunId),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavori ? Icons.favorite : Icons.favorite_border,
                      color: isFavori ? Colors.red : Colors.grey[500],
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urun.urunAdi,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  urun.aciklama ?? '',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₺${urun.fiyat.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                          onPressed: () {
                            final mevcut = sepetProvider.sepet.firstWhere(
                              (item) => item.urun.urunId == urun.urunId,
                              orElse: () => SepetItem(urun: urun, adet: 0),
                            );
                            if (mevcut.adet > 0) sepetProvider.sepettenCikar(mevcut);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                        ),
                        const SizedBox(width: 2),
                        Consumer<SepetProvider>(
                          builder: (context, provider, child) {
                            final sepetItem = provider.sepet.firstWhere(
                              (item) => item.urun.urunId == urun.urunId,
                              orElse: () => SepetItem(urun: urun, adet: 0),
                            );
                            return Text(
                              '${sepetItem.adet}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
                          onPressed: () {
                            final sepetItem = SepetItem(urun: urun, adet: 1);
                            sepetProvider.sepeteEkle(sepetItem);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${urun.urunAdi} sepete eklendi ✅'),
                                backgroundColor: const Color(0xFF2E7D32),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(int kategoriId) {
    switch (kategoriId) {
      case 1:
        return Icons.soup_kitchen;
      case 2:
        return Icons.restaurant;
      case 3:
        return Icons.fireplace;
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
}