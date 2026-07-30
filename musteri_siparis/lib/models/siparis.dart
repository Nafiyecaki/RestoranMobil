// lib/models/siparis.dart
class Siparis {
  final int siparisId;
  final String siparisDurumu;
  final String siparisTipi;
  final double? toplamTutar;
  final DateTime? siparisTarihi;
  final int? masaId;
  final String? masaNo;
  final List<SiparisDetay> detaylar;

  Siparis({
    required this.siparisId,
    required this.siparisDurumu,
    required this.siparisTipi,
    this.toplamTutar,
    this.siparisTarihi,
    this.masaId,
    this.masaNo,
    this.detaylar = const [],
  });

  factory Siparis.fromJson(Map<String, dynamic> json) {
    return Siparis(
      siparisId: json['siparisId'] ?? 0,
      siparisDurumu: json['siparisDurumu'] ?? 'BEKLEMEDE',
      siparisTipi: json['siparisTipi'] ?? 'SALON',
      toplamTutar: (json['toplamTutar'] ?? 0).toDouble(),
      siparisTarihi: json['siparisTarihi'] != null
          ? DateTime.tryParse(json['siparisTarihi'])
          : null,
      masaId: json['masaId'],
      masaNo: json['masaNo'],
      detaylar: (json['detaylar'] as List?)
              ?.map((e) => SiparisDetay.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SiparisDetay {
  final int siparisDetayId;
  final int urunId;
  final String urunAdi;
  final int adet;
  final double birimFiyat;
  final double satirToplami;
  final String? detayNot;

  SiparisDetay({
    required this.siparisDetayId,
    required this.urunId,
    required this.urunAdi,
    required this.adet,
    required this.birimFiyat,
    required this.satirToplami,
    this.detayNot,
  });

  factory SiparisDetay.fromJson(Map<String, dynamic> json) {
    return SiparisDetay(
      siparisDetayId: json['siparisDetayId'] ?? 0,
      urunId: json['urunId'] ?? 0,
      urunAdi: json['urunAdi'] ?? 'Bilinmiyor',
      adet: json['adet'] ?? 1,
      birimFiyat: (json['birimFiyat'] ?? 0).toDouble(),
      satirToplami: (json['satirToplami'] ?? 0).toDouble(),
      detayNot: json['detayNot'],
    );
  }
}