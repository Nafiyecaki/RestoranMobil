class Urun {
  final int urunId;
  final String urunAdi;
  final double fiyat;
  final int? kategoriId;
  final String? aciklama;

  Urun({
    required this.urunId,
    required this.urunAdi,
    required this.fiyat,
    this.kategoriId,
    this.aciklama,
  });

  factory Urun.fromJson(Map<String, dynamic> json) {
    return Urun(
      urunId: json['urunId'],
      urunAdi: json['urunAdi'] ?? '',
      fiyat: (json['fiyat'] as num).toDouble(),
      kategoriId: json['kategoriId'],
      aciklama: json['aciklama'],
    );
  }
}