import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ReportService {
  static const String baseUrl = 'http://localhost/cims_api';

  // Get Report Data
  Future<List<dynamic>> getReportData(String type, {DateTime? start, DateTime? end}) async {
    try {
      String url = '$baseUrl/report.php?type=$type';

      if (start != null && end != null) {
        String sDate = DateFormat('yyyy-MM-dd').format(start);
        String eDate = DateFormat('yyyy-MM-dd').format(end);
        url += '&start_date=$sDate&end_date=$eDate';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error Report: $e");
      return [];
    }
  }
}