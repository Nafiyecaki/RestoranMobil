import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/urun.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5141/api';

  Future<List<Urun>> getUrunler() async {
    final response = await http.get(Uri.parse('$baseUrl/urunler'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Urun.fromJson(json)).toList();
    } else {
      throw Exception('Ürünler yüklenemedi: ${response.statusCode}');
    }
  }

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
