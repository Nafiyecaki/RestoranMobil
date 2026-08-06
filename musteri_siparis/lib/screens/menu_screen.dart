import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/urun.dart';
import '../providers/sepet_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'profile_screen.dart';
import 'rezervasyon_screen.dart';
import 'sepet_screen.dart';
import 'urun_detay_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _menuleriYukle();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _menuleriYukle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final urunler = await ApiService.getUrunler();
      if (!mounted) return;

      setState(() {
        _tumUrunler = urunler;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ürünler yüklenirken bir hata oluştu';
        _isLoading = false;
      });
    }
  }

  List<Urun> get _filtrelenmisUrunler {
    return _tumUrunler.where((urun) {
      final kategoriId = _kategoriIdFromName(_selectedKategori);
      final kategoriUyumlu =
          kategoriId == null || urun.kategoriId == kategoriId;
      final aramaUyumlu =
          _searchQuery.isEmpty ||
          urun.urunAdi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (urun.aciklama ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return kategoriUyumlu && aramaUyumlu;
    }).toList();
  }

  int? _kategoriIdFromName(String kategori) {
    switch (kategori) {
      case 'Tümü':
        return null;
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
        return null;
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SepetScreen()),
      );
      return;
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RezervasyonScreen()),
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

  IconData _getCategoryIconByName(String kategori) {
    switch (kategori) {
      case 'Çorbalar':
        return Icons.soup_kitchen;
      case 'Ana Yemekler':
        return Icons.restaurant;
      case 'Izgaralar':
        return Icons.outdoor_grill;
      case 'Pide & Lahmacun':
        return Icons.local_pizza;
      case 'Salatalar & Mezeler':
        return Icons.eco;
      case 'Tatlılar':
        return Icons.cake;
      case 'Sıcak İçecekler':
        return Icons.local_cafe;
      case 'İçecekler':
        return Icons.local_drink;
      default:
        return Icons.restaurant_menu;
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
    final screenWidth = MediaQuery.of(context).size.width;
    // 900px eşiği: altında mobil/tablet dikey düzen, üstünde masaüstü
    // (web) yan menülü düzen kullanılır.
    final isWide = screenWidth >= 900;

    final content = _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          )
        : _errorMessage != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[200] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
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
        : _buildMenuContent(isDark);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF4F6F8),
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/Logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Şeker Restoran',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F4B2A),
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: isDark ? Colors.white70 : const Color(0xFF111827),
            ),
            onPressed: () {},
          ),
        ],
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
          : AppBottomNav(currentIndex: 0, onTap: _onBottomNavTap),
    );
  }

  /// Geniş (web/masaüstü) ekranlarda alt gezinme çubuğu yerine kullanılan
  /// yan menü. Aynı _onBottomNavTap mantığını kullanır.
  Widget _buildSideNav(bool isDark) {
    return NavigationRail(
      backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      selectedIndex: 0,
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

  Widget _buildMenuContent(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Çok geniş ekranlarda (masaüstü/web) içeriğin uçtan uca yayılıp
        // dağınık görünmemesi için maksimum genişlik veriyor ve ortalıyoruz.
        const maxContentWidth = 1100.0;
        final contentWidth = constraints.maxWidth > maxContentWidth
            ? maxContentWidth
            : constraints.maxWidth;
        final crossAxisCount = _gridColumnsForWidth(contentWidth);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(isDark),
                  const SizedBox(height: 12),
                  _buildCategoryFilter(isDark),
                  const SizedBox(height: 16),
                  _buildSectionTitle(
                    _selectedKategori == 'Tümü'
                        ? 'Tüm Menü'
                        : '$_selectedKategori Menüsü',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _filtrelenmisUrunler.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Ürün bulunamadı 😔',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.74,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: _filtrelenmisUrunler.length,
                          itemBuilder: (context, index) => _buildProductCard(
                            _filtrelenmisUrunler[index],
                            isDark,
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Kullanılabilir genişliğe göre grid sütun sayısını belirler.
  /// Mobilde 2 sütun kalır; ekran genişledikçe kartlar daha fazla
  /// sütuna yayılarak boşluk bırakmaz.
  int _gridColumnsForWidth(double width) {
    if (width >= 1000) return 5;
    if (width >= 800) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isDark ? Colors.grey[300] : const Color(0xFF111827),
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Yemek veya içecek ara...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : const Color(0xFF6B7280),
                  fontSize: 16,
                ),
              ),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              cursorColor: const Color(0xFF2E7D32),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                size: 18,
                color: isDark ? Colors.grey[300] : const Color(0xFF111827),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            )
          else
            Icon(
              Icons.tune,
              color: isDark ? Colors.grey[500] : const Color(0xFF6B7280),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    required bool isDark,
    String? trailing,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20 / 1.1,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F4B2A),
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Row(
            children: [
              Text(
                trailing,
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF2E7D32),
                size: 18,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _kategoriler.length,
        itemBuilder: (context, index) {
          final kategori = _kategoriler[index];
          final isSelected = _selectedKategori == kategori;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedKategori = kategori),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : (isDark ? const Color(0xFF1B1B1B) : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : (isDark
                              ? const Color(0xFF323232)
                              : const Color(0xFFE5E7EB)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIconByName(kategori),
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? Colors.grey[300]
                                : const Color(0xFF4B5563)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      kategori,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.grey[100]
                                  : const Color(0xFF111827)),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Urun urun, bool isDark) {
    final sepetProvider = context.watch<SepetProvider>();
    final isFavori = sepetProvider.isFavori(urun.urunId);
    final resimDosyasi = _getResimDosyasi(urun.urunAdi);

    return InkWell(
      onTap: () async {
        final added = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => UrunDetayScreen(urun: urun)),
        );
        if (added == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${urun.urunAdi} sepete eklendi ✅'),
              backgroundColor: const Color(0xFF2E7D32),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171717) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF303030) : const Color(0xFFE5E7EB),
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
                      setState(() {
                        sepetProvider.favoriEkleCikar(urun.urunId);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isFavori
                            ? Colors.red
                            : (isDark ? const Color(0xFF252525) : Colors.white),
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
                        isFavori ? Icons.favorite : Icons.favorite_border,
                        color: isFavori ? Colors.white : Colors.grey[500],
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
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₺${urun.fiyat.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final added = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UrunDetayScreen(urun: urun),
                            ),
                          );
                          if (added == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${urun.urunAdi} sepete eklendi ✅',
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text(
                          'Ekle',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(60, 32),
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
    );
  }
}
