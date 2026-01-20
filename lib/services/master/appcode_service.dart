import 'dart:convert';
import 'package:http/http.dart' as http;

class AppCodeService {
  static const String baseUrl = 'http://localhost/cims_api';

  // --- 1. SATUAN (UNITS) ---
  Future<List<dynamic>> getUnits() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_units.php'));
      return (response.statusCode == 200) ? jsonDecode(response.body)['data'] : [];
    } catch (e) { return []; }
  }

  Future<bool> addUnit(Map<String, String> data) async {
    final res = await http.post(Uri.parse('$baseUrl/master_units.php'), body: data);
    return jsonDecode(res.body)['success'];
  }

  Future<bool> updateUnit(Map<String, String> data) async {
    final res = await http.post(Uri.parse('$baseUrl/master_units.php?action=update'), body: data);
    return jsonDecode(res.body)['success'];
  }

  Future<bool> deleteUnit(String id) async {
    final res = await http.post(Uri.parse('$baseUrl/master_units.php?action=delete'), body: {'id': id});
    return jsonDecode(res.body)['success'];
  }

  // --- 2. KEMASAN (PACKAGINGS) ---
  Future<List<dynamic>> getPackagings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_packagings.php'));
      return (response.statusCode == 200) ? jsonDecode(response.body)['data'] : [];
    } catch (e) { return []; }
  }

  Future<bool> addPackaging(Map<String, String> data) async {
    // Data yg dikirim: name, value, unit_id
    final res = await http.post(Uri.parse('$baseUrl/master_packagings.php'), body: data);
    return jsonDecode(res.body)['success'];
  }

  Future<bool> updatePackaging(Map<String, String> data) async {
    final res = await http.post(Uri.parse('$baseUrl/master_packagings.php?action=update'), body: data);
    return jsonDecode(res.body)['success'];
  }

  Future<bool> deletePackaging(String id) async {
    final res = await http.post(Uri.parse('$baseUrl/master_packagings.php?action=delete'), body: {'id': id});
    return jsonDecode(res.body)['success'];
  }
}