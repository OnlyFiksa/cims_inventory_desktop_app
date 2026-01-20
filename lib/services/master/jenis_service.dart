import 'dart:convert';
import 'package:http/http.dart' as http;

class JenisService {
  static const String baseUrl = 'http://localhost/cims_api';

  // 1. GET ALL
  Future<List<dynamic>> getJenis() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_jenis.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. ADD
  Future<bool> addJenis(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_jenis.php'),
        body: data,
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // 3. UPDATE
  Future<bool> updateJenis(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_jenis.php?action=update'),
        body: data,
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // 4. DELETE
  Future<bool> deleteJenis(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_jenis.php?action=delete'),
        body: {'id': id},
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }
}