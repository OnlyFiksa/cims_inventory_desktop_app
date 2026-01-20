import 'dart:convert';
import 'package:http/http.dart' as http;

class KategoriService {
  static const String baseUrl = 'http://localhost/cims_api';

  // GET
  Future<List<dynamic>> getKategori() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_kategori.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ADD
  Future<bool> addKategori(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_kategori.php'),
        body: data,
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // UPDATE
  Future<bool> updateKategori(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_kategori.php?action=update'),
        body: data,
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // DELETE
  Future<bool> deleteKategori(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_kategori.php?action=delete'),
        body: {'id': id},
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }
}