// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/urun.dart';
import '../models/siparis.dart';

class ApiService {
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

  static Future<Map<String, dynamic>> login({
    required String kullaniciAdi,
    required String sifre,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciAdi': kullaniciAdi,
          'sifre': sifre,
        }),
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
        
        return {
          'success': true,
          'data': data,
          'message': '✅ Giriş başarılı!',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Giriş başarısız! Kullanıcı adı veya şifre hatalı.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '⚠️ Bağlantı hatası! Lütfen internet bağlantınızı kontrol edin.',
      };
    }
  }

  static Future<List<Urun>> getUrunler() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/urunler'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Urun.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Ürünler yüklenirken hata: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> siparisOlustur({
    required String siparisTipi,
    String? musteriAdi,
    String? musteriTelefon,
    String? musteriAdres,
    int? masaId,
    required List<Map<String, dynamic>> detaylar,
  }) async {
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({
        'siparisTipi': siparisTipi,
        'musteriAdi': musteriAdi,
        'musteriTelefon': musteriTelefon,
        'musteriAdres': musteriAdres,
        'masaId': masaId,
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