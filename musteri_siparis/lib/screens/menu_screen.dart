import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/urun.dart';
import '../services/api_service.dart';
import '../providers/sepet_provider.dart';
import 'sepet_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ApiService _api = ApiService();
  late Future<List<Urun>> _urunlerFuture;

  @override
  void initState() {
    super.initState();
    _urunlerFuture = _api.getUrunler();
  }

  @override
  Widget build(BuildContext context) {
    final sepet = context.watch<SepetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menü'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SepetScreen()),
                  );
                },
              ),
              if (sepet.toplamAdet > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${sepet.toplamAdet}',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Urun>>(
        future: _urunlerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          final urunler = snapshot.data ?? [];
          if (urunler.isEmpty) {
            return const Center(child: Text('Ürün bulunamadı.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: urunler.length,
            itemBuilder: (context, index) {
              final urun = urunler[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(urun.urunAdi),
                  subtitle: Text('${urun.fiyat.toStringAsFixed(2)} ₺'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      context.read<SepetProvider>().ekle(urun);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${urun.urunAdi} sepete eklendi'),
                          duration: const Duration(milliseconds: 800),
                        ),
                      );
                    },
                    child: const Text('Ekle'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
