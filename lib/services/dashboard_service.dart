import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  static const String baseUrl = 'http://localhost/cims_api';

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard.php'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Gagal mengambil data'};
      }
    } catch (e) {
      print("Error Dashboard: $e");
      return {'success': false, 'message': 'Koneksi Error: $e'};
    }
  }
}