// lib/models/user_model.dart
class User {
  final int uyeId;
  final String? uyeAdi;
  final String? uyeSoyadi;
  final String? uyeEmail;
  final String? uyeTelefon;
  final String? cinsiyet;
  final DateTime? kayitTarihi;
  final List<Address>? adresler;

  User({
    required this.uyeId,
    this.uyeAdi,
    this.uyeSoyadi,
    this.uyeEmail,
    this.uyeTelefon,
    this.cinsiyet,
    this.kayitTarihi,
    this.adresler,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uyeId: json['uyeId'] ?? json['id'] ?? 0,
      uyeAdi: json['uyeAdi'] ?? json['ad'] ?? '',
      uyeSoyadi: json['uyeSoyadi'] ?? json['soyad'] ?? '',
      uyeEmail: json['uyeEmail'] ?? json['email'] ?? '',
      uyeTelefon: json['uyeTelefon'] ?? json['telefon'] ?? '',
      cinsiyet: json['cinsiyet'],
      kayitTarihi: json['kayitTarihi'] != null 
          ? DateTime.tryParse(json['kayitTarihi']) 
          : null,
      adresler: (json['adresler'] as List?)
          ?.map((a) => Address.fromJson(a))
          .toList(),
    );
  }

  String get tamAdi => '$uyeAdi $uyeSoyadi'.trim();
}

class Address {
  final int adresId;
  final String adresTipi;
  final String acikAdres;
  final bool? teslimatBolgesindeMi;

  Address({
    required this.adresId,
    required this.adresTipi,
    required this.acikAdres,
    this.teslimatBolgesindeMi,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      adresId: json['adresId'] ?? 0,
      adresTipi: json['adresTipi'] ?? 'Ev',
      acikAdres: json['acikAdres'] ?? '',
      teslimatBolgesindeMi: json['teslimatBolgesindeMi'],
    );
  }
}