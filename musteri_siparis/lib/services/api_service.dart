// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/urun.dart';
import '../models/user_model.dart';

class ApiService {
  // ============================================================
  // 📡 BASE URL - Otomatik Ortam Tespiti
  // ============================================================
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  static String? _token;
  static String? _userId;

  // ============================================================
  // 🔐 TOKEN YÖNETİMİ
  // ============================================================
  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> logout() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  // ============================================================
  // 🔐 GİRİŞ YAP
  // ============================================================
  static Future<Map<String, dynamic>> login({
    required String kullaniciAdi,
    required String sifre,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'kullaniciAdi': kullaniciAdi, 'sifre': sifre}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final token = data['token'] ?? data['accessToken'] ?? '';

        if (token.isNotEmpty) {
          await _saveToken(token);
          _userId = data['userId']?.toString() ?? data['id']?.toString();
          if (_userId != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', _userId!);
          }
        }

        return {'success': true, 'data': data, 'message': '✅ Giriş başarılı!'};
      } else {
        return {
          'success': false,
          'message': '❌ Giriş başarısız! Kullanıcı adı veya şifre hatalı.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            '⚠️ Bağlantı hatası! Lütfen internet bağlantınızı kontrol edin.',
      };
    }
  }

  // ============================================================
  // 📦 ÜRÜNLERİ GETİR
  // ============================================================
  static Future<List<Urun>> getUrunler() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/urunler'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        final filteredData = data.where((item) {
          final ad = (item['urunAdi'] ?? '').toLowerCase();
          return ad != 'mr b' && ad != 'aa' && ad != 'deneme' && ad != 'mrb';
        }).toList();
        return filteredData.map((json) => Urun.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Ürünler yüklenirken hata: $e');
      return [];
    }
  }

  // ============================================================
  // 📦 KATEGORİYE GÖRE ÜRÜN GETİR
  // ============================================================
  static Future<List<Urun>> getUrunlerByKategoriId(int kategoriId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/urunler?kategoriId=$kategoriId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final urunler = decoded.map((json) => Urun.fromJson(json)).toList();
          return urunler.where((u) => u.kategoriId == kategoriId).toList();
        }
      }

      // Sorgu endpoint'i desteklenmiyorsa tüm ürünlerden filtrele.
      final tumUrunler = await getUrunler();
      return tumUrunler.where((u) => u.kategoriId == kategoriId).toList();
    } catch (e) {
      debugPrint('Kategoriye göre ürünler yüklenirken hata: $e');
      final tumUrunler = await getUrunler();
      return tumUrunler.where((u) => u.kategoriId == kategoriId).toList();
    }
  }

  // ============================================================
  // 🛒 SİPARİŞ OLUŞTUR
  // ============================================================

static Future<Map<String, dynamic>> siparisOlustur({
  required String siparisTipi,
  String? musteriAdi,
  String? musteriTelefon,
  String? musteriAdres,
  int? masaId,
  int? uyeId,  // ✅ YENİ: UyeId eklendi
  required List<Map<String, dynamic>> detaylar,
}) async {
  try {
    final token = await _getToken();
    final headers = {'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = jsonEncode({
      'siparisTipi': siparisTipi,
      'musteriAdi': musteriAdi,
      'musteriTelefon': musteriTelefon,
      'musteriAdres': musteriAdres,
      'masaId': masaId,
      'uyeId': uyeId,  // ✅ UyeId gönderiliyor
      'detaylar': detaylar,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/siparisler'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': true,
        'data': data,
        'message': '✅ Sipariş başarıyla oluşturuldu!',
      };
    } else {
      return {
        'success': false,
        'message': '❌ Sipariş oluşturulamadı! Lütfen tekrar deneyin.',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': '⚠️ Bağlantı hatası! Lütfen internet bağlantınızı kontrol edin.',
    };
  }
}

  // ============================================================
  // 👤 KULLANICI PROFİLİ
  // ============================================================
  static Future<User> getProfile() async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/uyeler/profil'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return User.fromJson(data);
      } else {
        throw Exception('Profil bilgileri alınamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // 👤 PROFİL GÜNCELLE
  // ============================================================
  static Future<Map<String, dynamic>> updateProfile({
    required String adi,
    required String soyadi,
    required String telefon,
  }) async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.put(
        Uri.parse('$baseUrl/uyeler/profil'),
        headers: headers,
        body: jsonEncode({
          'uyeAdi': adi,
          'uyeSoyadi': soyadi,
          'uyeTelefon': telefon,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': data,
          'message': '✅ Profil başarıyla güncellendi!',
        };
      } else {
        return {'success': false, 'message': '❌ Profil güncellenemedi!'};
      }
    } catch (e) {
      return {'success': false, 'message': '⚠️ Bağlantı hatası!'};
    }
  }

  // ============================================================
  // 🔐 ŞİFRE DEĞİŞTİR
  // ============================================================
  static Future<Map<String, dynamic>> changePassword({
    required String eskiSifre,
    required String yeniSifre,
  }) async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/sifre-degistir'),
        headers: headers,
        body: jsonEncode({'eskiSifre': eskiSifre, 'yeniSifre': yeniSifre}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': data,
          'message': '✅ Şifre başarıyla değiştirildi!',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Şifre değiştirilemedi! Eski şifrenizi kontrol edin.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '⚠️ Bağlantı hatası!'};
    }
  }

  // ============================================================
  // 📍 ADRESLERİ GETİR
  // ============================================================
  static Future<List<Address>> getAddresses() async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/uyeler/adresler'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((a) => Address.fromJson(a)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 📍 ADRES EKLE
  // ============================================================
  static Future<Map<String, dynamic>> addAddress({
    required String adresTipi,
    required String acikAdres,
    bool teslimatBolgesindeMi = false,
  }) async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/uyeler/adresler'),
        headers: headers,
        body: jsonEncode({
          'adresTipi': adresTipi,
          'acikAdres': acikAdres,
          'teslimatBolgesindeMi': teslimatBolgesindeMi,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': data,
          'message': '✅ Adres başarıyla eklendi!',
        };
      } else {
        return {'success': false, 'message': '❌ Adres eklenemedi!'};
      }
    } catch (e) {
      return {'success': false, 'message': '⚠️ Bağlantı hatası!'};
    }
  }

  // ============================================================
  // 📍 ADRES SİL
  // ============================================================
  static Future<Map<String, dynamic>> deleteAddress(int adresId) async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/uyeler/adresler/$adresId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': '✅ Adres başarıyla silindi!'};
      } else {
        return {'success': false, 'message': '❌ Adres silinemedi!'};
      }
    } catch (e) {
      return {'success': false, 'message': '⚠️ Bağlantı hatası!'};
    }
  }

  // ============================================================
  // 📋 KULLANICI SİPARİŞLERİ
  // ============================================================
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/siparisler/benim-siparislerim'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 📋 SİPARİŞ GEÇMİŞİ
  // ============================================================
  static Future<List<Map<String, dynamic>>> getOrderHistory() async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/siparisler/gecmis'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 👤 KULLANICI BİLGİLERİ
  // ============================================================
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return null;
    return {'userId': userId};
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }
}
