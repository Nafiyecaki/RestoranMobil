class Urun {
  final int urunId;
  final String urunAdi;
  final double fiyat;
  final int? stokMiktari;
  final String? aciklama;
  final int kategoriId;
  final bool isActive;

  Urun({
    required this.urunId,
    required this.urunAdi,
    required this.fiyat,
    this.stokMiktari,
    this.aciklama,
    required this.kategoriId,
    this.isActive = true,
  });

  factory Urun.fromJson(Map<String, dynamic> json) {
    return Urun(
      urunId: json['urunId'] ?? 0,
      urunAdi: json['urunAdi'] ?? '',
      fiyat: (json['fiyat'] as num?)?.toDouble() ?? 0.0,
      stokMiktari: json['stokMiktari'],
      aciklama: json['aciklama'],
      kategoriId: json['kategoriId'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}