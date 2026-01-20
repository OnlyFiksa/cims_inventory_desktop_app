import 'dart:convert';
import 'package:http/http.dart' as http;

class SupplierService {
  static const String baseUrl = 'http://localhost/cims_api';

  // GET
  Future<List<dynamic>> getSupplier() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_supplier.php'));
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
  Future<bool> addSupplier(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_supplier.php'),
        body: data,
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // UPDATE
  Future<bool> updateSupplier(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_supplier.php?action=update'),
        body: data,
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // DELETE
  Future<bool> deleteSupplier(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/master_supplier.php?action=delete'),
        body: {'id': id},
      );
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }
}