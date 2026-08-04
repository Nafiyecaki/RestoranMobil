import 'package:flutter/material.dart';
import 'screens/siparis_ozet_screen.dart';

void main() {
  runApp(const SiparisOzetPreviewApp());
}

class SiparisOzetPreviewApp extends StatelessWidget {
  const SiparisOzetPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        fontFamily: 'Inter',
      ),
      home: const SiparisOzetScreen(
        siparisId: 4082,
        siparisTipi: 'PAKET_SERVIS',
        odemeTipi: 'KREDI_KARTI',
        musteriAdi: 'Ahmet Yılmaz',
        musteriTelefon: '0555 123 45 67',
        musteriAdres:
            'Atatürk Mah. İstiklal Cad. No:18 D:5, Kadıköy / İstanbul',
        urunler: [
          SiparisOzetItemData(
            urunAdi: 'Mercimek Çorbası',
            adet: 1,
            birimFiyat: 46.0,
          ),
          SiparisOzetItemData(
            urunAdi: 'Adana Kebap',
            adet: 2,
            birimFiyat: 165.0,
          ),
          SiparisOzetItemData(urunAdi: 'Ayran', adet: 2, birimFiyat: 18.0),
        ],
        araToplam: 412.0,
        teslimatUcreti: 24.0,
        toplamTutar: 436.0,
      ),
    );
  }
}
