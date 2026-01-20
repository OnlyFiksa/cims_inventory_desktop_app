import 'dart:convert';
import 'package:http/http.dart' as http;

class ItemService {
  // Ganti IP sesuai konfigurasi Bapak
  static const String baseUrl = 'http://localhost/cims_api';

  // 1. GET ITEMS
  Future<List<dynamic>> getItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/item_master.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      print("Error Get Items: $e");
      return [];
    }
  }

  // 2. [BARU] GET NEXT SEQUENCE (Untuk Auto Number)
  Future<int> getNextSequence() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/item_master.php?action=get_sequence'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['sequence'] ?? 1;
      }
      return 1;
    } catch (e) {
      print("Error Sequence: $e");
      return 1;
    }
  }

  // 3. GET DROPDOWNS
  Future<Map<String, List<dynamic>>> getDropdowns() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/item_master.php?action=dropdowns'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return {
          'categories': data['categories'],
          'owners': data['owners'],
          'types': data['types'],
          'manufacturers': data['manufacturers'],
          'suppliers': data['suppliers'],
          'packagings': data['packagings'],
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // 4. ADD
  Future<bool> addItem(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/item_master.php'), body: data);
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // 5. UPDATE
  Future<bool> updateItem(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/item_master.php?action=update'), body: data);
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }

  // 6. DELETE
  Future<bool> deleteItem(String id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/item_master.php?action=delete'), body: {'id': id});
      final result = jsonDecode(response.body);
      return result['success'];
    } catch (e) {
      return false;
    }
  }
}