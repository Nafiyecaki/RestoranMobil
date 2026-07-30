import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/urun.dart';

class ApiService {
  static String get baseUrl {
    final host = kIsWeb
        ? 'localhost'
        : (Platform.isAndroid ? '10.0.2.2' : 'localhost');
    return 'http://$host:5141/api';
  }

  static String? _userId;

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> logout() async {
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  // 👇 GİRİŞ
  Future<Map<String, dynamic>> login({
    required String kullaniciAdi,
    required String sifre,
  }) async {
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
      return data;
    }

    throw Exception(jsonDecode(response.body)['message'] ?? 'Giriş başarısız');
  }

  // 👇 BACKEND'DEN ÜRÜNLERİ ÇEK (SADECE FİYAT VE BİLGİ İÇİN)
  Future<List<Urun>> getUrunler() async {
    final response = await http.get(
      Uri.parse('$baseUrl/urunler'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      // Test verilerini filtrele (mr b, aa, deneme)
      final filteredData = data.where((item) {
        final ad = (item['urunAdi'] ?? '').toLowerCase();
        return ad != 'mr b' && ad != 'aa' && ad != 'deneme' && ad != 'mrb';
      }).toList();
      return filteredData.map((json) => Urun.fromJson(json)).toList();
    } else {
      throw Exception('Ürünler yüklenemedi: ${response.statusCode}');
    }
  }

  // 👇 SİPARİŞ GÖNDER (BACKEND'E)
  Future<Map<String, dynamic>> siparisOlustur({
    required String siparisTipi,
    String? musteriAdi,
    String? musteriTelefon,
    int? masaId,
    required List<Map<String, dynamic>> detaylar,
  }) async {
    final body = jsonEncode({
      'siparisTipi': siparisTipi,
      'musteriAdi': musteriAdi,
      'musteriTelefon': musteriTelefon,
      'masaId': masaId,
      'detaylar': detaylar,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/siparisler'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Sipariş oluşturulamadı: ${response.body}');
    }
  }
}