import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // Pastikan URL ini benar. Jika pakai Android Emulator gunakan 10.0.2.2
  static const String baseUrl = 'http://localhost/cims_api';

  // 1. Get All Users
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Pastikan backend mengembalikan format { "data": [...] }
        // Jika backend langsung return array, ganti jadi: return data;
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error Get Users: $e");
      return [];
    }
  }

  // 2. Add User
  Future<Map<String, dynamic>> addUser(Map<String, String> data) async {
    try {
      final response = await http.post(
          Uri.parse('$baseUrl/users.php'), body: data);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  // 3. Update User
  Future<bool> updateUser(Map<String, String> data) async {
    try {
      // Pastikan backend support ?action=update
      final response = await http.post(
          Uri.parse('$baseUrl/users.php?action=update'), body: data);
      final result = jsonDecode(response.body);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // 4. Delete User (Update Parameter)
  Future<Map<String, dynamic>> deleteUser(String targetId,
      String adminId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_user.php'), // Pastikan path benar
        body: {
          'id': targetId, // Orang yang mau dihapus
          'admin_id': adminId // Orang yang menghapus (Proteksi di PHP)
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
}