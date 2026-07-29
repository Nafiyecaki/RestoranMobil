import 'package:flutter/foundation.dart';
import '../models/urun.dart';
import '../models/sepet_item.dart';

class SepetProvider extends ChangeNotifier {
  final List<SepetItem> _items = [];

  List<SepetItem> get items => _items;

  double get toplamTutar =>
      _items.fold(0, (sum, item) => sum + item.satirToplami);

  int get toplamAdet => _items.fold(0, (sum, item) => sum + item.adet);

  void ekle(Urun urun) {
    final mevcut = _items.indexWhere((i) => i.urun.urunId == urun.urunId);
    if (mevcut >= 0) {
      _items[mevcut].adet++;
    } else {
      _items.add(SepetItem(urun: urun));
    }
    notifyListeners();
  }

  void azalt(Urun urun) {
    final mevcut = _items.indexWhere((i) => i.urun.urunId == urun.urunId);
    if (mevcut >= 0) {
      if (_items[mevcut].adet > 1) {
        _items[mevcut].adet--;
      } else {
        _items.removeAt(mevcut);
      }
      notifyListeners();
    }
  }

  void temizle() {
    _items.clear();
    notifyListeners();
  }
}
