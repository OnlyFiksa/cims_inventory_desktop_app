import 'dart:convert';
import 'package:http/http.dart' as http;

class TransaksiService {
  // Ganti dengan IP komputer Anda jika pakai Emulator (misal: 10.0.2.2)
  static const String baseUrl = 'http://localhost/cims_api';

  // ===========================================================================
  // 1. STOK MASUK (STOCK IN)
  // ===========================================================================

  Future<List<dynamic>> getStockIn() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trx_in.php'));

      // [FIX] Cek Body Kosong biar gak Crash
      if (response.body.isEmpty) return [];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error Get Stock In: $e");
      return [];
    }
  }

  Future<Map<String, List<dynamic>>> getDropdowns() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trx_in.php?action=dropdowns'));

      if (response.body.isEmpty) return {};

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return {
          'items': data['items'],
          'owners': data['owners'],
          'manufacturers': data['manufacturers'],
          'suppliers': data['suppliers'],
          'packagings': data['packagings'],
          'units': data['units'],
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> addStockIn(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/trx_in.php'), body: data);

      if (response.body.isEmpty) return {"success": false, "message": "Server tidak merespon (Empty Body)"};

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error Connection: $e"};
    }
  }

  // ===========================================================================
  // 2. STOK KELUAR (STOCK OUT)
  // ===========================================================================

  Future<List<dynamic>> getStockOut() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trx_out.php'));

      if (response.body.isEmpty) return [];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, List<dynamic>>> getStockOutDropdowns() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trx_out.php?action=dropdowns'));

      if (response.body.isEmpty) return {};

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return {
          'owners': data['owners'],
          'items': data['items'],
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> addStockOut(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/trx_out.php'), body: data);

      if (response.body.isEmpty) return {"success": false, "message": "Server tidak merespon"};

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error Connection: $e"};
    }
  }

  // ===========================================================================
  // 3. VERIFIKASI (UPDATED)
  // ===========================================================================

  // [PENTING] Parameter diubah dari String trxId menjadi Map data
  // Agar data revisi (Qty, Harga, dll) ikut terkirim ke backend
  Future<bool> verifyStockIn(Map<String, String> data) async {
    try {
      // Pastikan backend verify_stock.php menangkap $_POST['qty_in'], $_POST['price'], dll
      // selain $_POST['trx_id'] (atau 'id').
      final response = await http.post(
        Uri.parse('$baseUrl/verify_stock.php'),
        body: data,
      );

      if (response.body.isEmpty) {
        print("Verify Error: Empty Body");
        return false;
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] ?? false;
      }
      return false;
    } catch (e) {
      print("Verify Error: $e");
      return false;
    }
  }

  // ===========================================================================
  // 4. INVENTORY & ADJUSTMENT
  // ===========================================================================

  Future<List<dynamic>> getInventory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventory.php'));

      if (response.body.isEmpty) return [];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> adjustStock(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventory.php'),
        body: data,
      );

      if (response.body.isEmpty) return {"success": false, "message": "Server tidak merespon"};

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error Connection: $e"};
    }
  }
}