import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sepet_provider.dart';
import '../services/api_service.dart';

class SepetScreen extends StatefulWidget {
  const SepetScreen({super.key});

  @override
  State<SepetScreen> createState() => _SepetScreenState();
}

class _SepetScreenState extends State<SepetScreen> {
  final ApiService _api = ApiService();
  final _adController = TextEditingController();
  final _telController = TextEditingController();
  bool _gonderiliyor = false;

  Future<void> _siparisVer(SepetProvider sepet) async {
    if (_adController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen adınızı girin')));
      return;
    }

    setState(() => _gonderiliyor = true);

    try {
      final detaylar = sepet.items
          .map(
            (item) => {
              'urunId': item.urun.urunId,
              'adet': item.adet,
              'detayNot': item.not,
            },
          )
          .toList();

      await _api.siparisOlustur(
        siparisTipi: 'GEL-AL',
        musteriAdi: _adController.text.trim(),
        musteriTelefon: _telController.text.trim(),
        detaylar: detaylar,
      );

      sepet.temizle();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Siparişiniz alındı!')));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sepet = context.watch<SepetProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sepetim')),
      body: sepet.items.isEmpty
          ? const Center(child: Text('Sepetiniz boş.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: sepet.items.length,
                    itemBuilder: (context, index) {
                      final item = sepet.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(item.urun.urunAdi),
                          subtitle: Text(
                            '${item.urun.fiyat.toStringAsFixed(2)} ₺ x ${item.adet}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => context
                                    .read<SepetProvider>()
                                    .azalt(item.urun),
                              ),
                              Text('${item.adet}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => context
                                    .read<SepetProvider>()
                                    .ekle(item.urun),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _adController,
                        decoration: const InputDecoration(
                          labelText: 'Adınız',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _telController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toplam: ${sepet.toplamTutar.toStringAsFixed(2)} ₺',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _gonderiliyor
                                ? null
                                : () => _siparisVer(sepet),
                            child: _gonderiliyor
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sipariş Ver'),
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
}
