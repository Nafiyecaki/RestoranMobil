import 'urun.dart';

class SepetItem {
  final Urun urun;
  int adet;
  String? not;

  SepetItem({required this.urun, this.adet = 1, this.not});

  double get satirToplami => urun.fiyat * adet;
}