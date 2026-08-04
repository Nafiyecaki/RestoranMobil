import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sepet_item.dart';

class SepetProvider extends ChangeNotifier {
  final List<SepetItem> _sepet = [];
  List<int> _favoriler = [];

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

  Future<String> _resolveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }

    final userRaw = prefs.getString('user');
    if (userRaw != null && userRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(userRaw);
        if (decoded is Map<String, dynamic>) {
          final fallbackId = decoded['id']?.toString();
          if (fallbackId != null && fallbackId.isNotEmpty) {
            await prefs.setString('user_id', fallbackId);
            return fallbackId;
          }
        }
      } catch (_) {
        // Ignore corrupted cached user payload and fallback to guest.
      }
    }

    return 'guest';
  }

  Future<String> _favoriKey() async {
    final userId = await _resolveUserId();
    return 'favoriler_$userId';
  }

  Future<void> loadFavoriler() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _favoriKey();
    final stored = prefs.getStringList(key) ?? const [];
    _favoriler = stored.map((id) => int.tryParse(id)).whereType<int>().toList();
    notifyListeners();
  }

  Future<void> _saveFavoriler() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _favoriKey();
    await prefs.setStringList(
      key,
      _favoriler.map((id) => id.toString()).toList(),
    );
  }

  void favoriEkleCikar(int urunId) {
    if (_favoriler.contains(urunId)) {
      _favoriler.remove(urunId);
    } else {
      _favoriler.add(urunId);
    }
    _saveFavoriler();
    notifyListeners();
  }

  Future<void> reloadFavoriler() => loadFavoriler();

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
