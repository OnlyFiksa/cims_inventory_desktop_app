import 'dart:convert';
import 'package:http/http.dart' as http;

class PemilikService {
  // Pastikan URL ini sesuai dengan settingan XAMPP Bapak
  static const String baseUrl = 'http://localhost/cims_api';

  // 1. GET ALL
  Future<List<dynamic>> getPemilik() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_pemilik.php'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Mengembalikan List Data
      }
      return [];
    } catch (e) {
      print("Error Get Pemilik: $e");
      return [];
    }
  }

  // 2. ADD
  Future<bool> addPemilik(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_pemilik.php'),
        body: data,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'];
      }
      return false;
    } catch (e) {
      print("Error Add Pemilik: $e");
      return false;
    }
  }

  // 3. UPDATE
  Future<bool> updatePemilik(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_pemilik.php?action=update'),
        body: data,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'];
      }
      return false;
    } catch (e) {
      print("Error Update Pemilik: $e");
      return false;
    }
  }

  // 4. DELETE
  Future<bool> deletePemilik(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_pemilik.php?action=delete'),
        body: {'id': id},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'];
      }
      return false;
    } catch (e) {
      print("Error Delete Pemilik: $e");
      return false;
    }
  }
}