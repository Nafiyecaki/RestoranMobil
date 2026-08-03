import 'package:flutter/material.dart';
import '../models/sepet_item.dart';

class SepetProvider extends ChangeNotifier {
  final List<SepetItem> _sepet = [];
  final List<int> _favoriler = [];

  List<SepetItem> get sepet => _sepet;
  List<int> get favoriler => _favoriler;

  double get toplamFiyat {
    return _sepet.fold(0.0, (sum, item) => sum + item.satirToplami);
  }

  int get toplamUrunSayisi {
    return _sepet.fold(0, (sum, item) => sum + item.adet);
  }

  bool isFavori(int urunId) {
    return _favoriler.contains(urunId);
  }

  void favoriEkleCikar(int urunId) {
    if (_favoriler.contains(urunId)) {
      _favoriler.remove(urunId);
    } else {
      _favoriler.add(urunId);
    }
    notifyListeners();
  }

  void sepeteEkle(SepetItem sepetItem) {
    final mevcutIndex = _sepet.indexWhere(
      (item) => item.urun.urunId == sepetItem.urun.urunId,
    );
    if (mevcutIndex != -1) {
      _sepet[mevcutIndex].adet += sepetItem.adet;
    } else {
      _sepet.add(sepetItem);
    }
    notifyListeners();
  }

  void sepettenCikar(SepetItem sepetItem) {
    final mevcutIndex = _sepet.indexWhere(
      (item) => item.urun.urunId == sepetItem.urun.urunId,
    );
    if (mevcutIndex != -1) {
      if (_sepet[mevcutIndex].adet > 1) {
        _sepet[mevcutIndex].adet--;
      } else {
        _sepet.removeAt(mevcutIndex);
      }
      notifyListeners();
    }
  }

  void sepetiTemizle() {
    _sepet.clear();
    notifyListeners();
  }

  void urunSil(SepetItem sepetItem) {
    _sepet.removeWhere((item) => item.urun.urunId == sepetItem.urun.urunId);
    notifyListeners();
  }
}
