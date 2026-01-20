import 'dart:convert';
import 'package:http/http.dart' as http;

class ManufakturService {
  static const String baseUrl = 'http://localhost/cims_api';

  // GET
  Future<List<dynamic>> getManufaktur() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_manufaktur.php'));
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
  Future<bool> addManufaktur(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_manufaktur.php'),
        body: data,
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // UPDATE
  Future<bool> updateManufaktur(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_manufaktur.php?action=update'),
        body: data,
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // DELETE
  Future<bool> deleteManufaktur(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_manufaktur.php?action=delete'),
        body: {'id': id},
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }
}