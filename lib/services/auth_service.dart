import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Pastikan URL ini benar (jika pakai emulator android ganti localhost jadi 10.0.2.2)
  static const String baseUrl = 'http://localhost/cims_api';

  // 1. LOGIN (Simpan Sesi)
  Future<Map<String, dynamic>> login(String nik, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        body: {
          'nik': nik,         // <--- SUDAH BENAR (Pakai NIK)
          'password': password
        },
      );

      print("Login Response: ${response.body}"); // Debugging

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // PERBAIKAN DISINI:
          // Di PHP key-nya adalah 'user', bukan 'data'
          await _saveUserSession(data['user']);
        }
        return data;
      } else {
        return {'success': false, 'message': 'Error Server: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Gagal: $e'};
    }
  }

  // Simpan ke Memori HP/Laptop
  Future<void> _saveUserSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // Pastikan konversi ke String aman
    await prefs.setString('user_id', userData['id'].toString());
    await prefs.setString('user_name', userData['name'] ?? 'User');
    await prefs.setString('user_role', userData['role'] ?? 'staff');
    await prefs.setString('user_nik', userData['nik'] ?? ''); // Simpan NIK juga

    await prefs.setBool('is_logged_in', true);
  }

  // 2. GET SESSION
  Future<Map<String, String>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('user_id') ?? '',
      'name': prefs.getString('user_name') ?? 'User',
      'role': prefs.getString('user_role') ?? 'staff',
      'nik': prefs.getString('user_nik') ?? '',
    };
  }

  // 3. LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}