import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sepet_provider.dart';
import '../models/sepet_item.dart';
import '../models/urun.dart';
import '../services/api_service.dart';

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

  // 👇 ÜRÜN ADINA GÖRE LOCAL RESİM EŞLEŞTİRME (Backend'den resim gelmiyor)
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
      final apiService = ApiService();
      final urunler = await apiService.getUrunler();

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
                      _showSepetDialog(context);
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
    // 👇 RESİM LOCAL'DEN
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
                    // 👇 FİYAT BACKEND'DEN
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

  // 👇 SİPARİŞ GÖNDER (BACKEND'E)
  Future<void> _siparisGonder(BuildContext context) async {
    final sepetProvider = Provider.of<SepetProvider>(context, listen: false);

    if (sepetProvider.sepet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sepetiniz boş!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final apiService = ApiService();
      final detaylar = sepetProvider.sepet.map((item) {
        return {
          'urunId': item.urun.urunId,
          'urunAdi': item.urun.urunAdi,
          'fiyat': item.urun.fiyat,
          'adet': item.adet,
          'aciklama': item.urun.aciklama ?? '',
        };
      }).toList();

      final response = await apiService.siparisOlustur(
        siparisTipi: 'Masa',
        musteriAdi: 'Müşteri',
        masaId: 1,
        detaylar: detaylar,
      );

      if (context.mounted) {
        sepetProvider.sepetiTemizle();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Siparişiniz başarıyla gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sipariş gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSepetDialog(BuildContext context) {
    final sepetProvider = Provider.of<SepetProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 35,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '🛒 Sepetim',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: sepetProvider.sepet.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 50, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Sepetiniz boş', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: sepetProvider.sepet.length,
                          itemBuilder: (context, index) {
                            final item = sepetProvider.sepet[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(item.urun.kategoriId),
                                      color: const Color(0xFF2E7D32),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.urun.urunAdi,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '₺${item.urun.fiyat.toStringAsFixed(2)} x ${item.adet}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () => sepetProvider.sepettenCikar(item),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 22,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${item.adet}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 2),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
                                        onPressed: () => sepetProvider.sepeteEkle(
                                          SepetItem(urun: item.urun, adet: 1),
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 22,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (sepetProvider.sepet.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Toplam:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₺${sepetProvider.toplamFiyat.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    sepetProvider.sepetiTemizle();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🗑️ Sepet temizlendi'),
                                        backgroundColor: Colors.grey,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text(
                                    'Temizle',
                                    style: TextStyle(color: Colors.red, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // 👇 SİPARİŞ GÖNDER
                                    _siparisGonder(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text(
                                    'Sipariş Ver',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}