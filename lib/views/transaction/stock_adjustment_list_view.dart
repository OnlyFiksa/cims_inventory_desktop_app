import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cims_app/services/transaction/transaksi_service.dart';

class StockAdjustmentListView extends StatefulWidget {
  final String userRole;
  const StockAdjustmentListView({super.key, required this.userRole});

  @override
  State<StockAdjustmentListView> createState() => _StockAdjustmentListViewState();
}

class _StockAdjustmentListViewState extends State<StockAdjustmentListView> {
  // COLORS
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color bgGrey = const Color(0xFFF5F7FA);
  final Color readOnlyColor = const Color(0xFFE0E0E0);
  final Color colorEditable = Colors.white;

  // STATE
  bool _isFormVisible = false;
  Map<String, dynamic>? _selectedItem;

  // CONTROLLERS
  final _namaBarangCtrl = TextEditingController();
  final _stokSistemCtrl = TextEditingController();
  final _stokFisikCtrl = TextEditingController();
  final _selisihCtrl = TextEditingController();
  final _alasanCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  // DATA
  List<dynamic> _stockList = [];
  List<dynamic> _filteredList = [];

  // GUNAKAN TRANSAKSI SERVICE
  final TransaksiService _service = TransaksiService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    final data = await _service.getInventory();
    if (mounted) {
      setState(() {
        _stockList = data;
        _filteredList = data;
      });
    }
  }

  void _filterData(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _stockList;
      } else {
        _filteredList = _stockList.where((item) {
          String name = item['item_name']?.toLowerCase() ?? '';
          String code = item['unique_code']?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || code.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // --- LOGIC ADJUSTMENT ---
  void _openAdjustment(Map<String, dynamic> item) {
    setState(() {
      _selectedItem = item;
      _isFormVisible = true;

      _namaBarangCtrl.text = "${item['item_name']} (${item['unique_code']})";
      _stokSistemCtrl.text = item['qty_current'].toString();
      _stokFisikCtrl.clear();
      _selisihCtrl.text = "0";
      _alasanCtrl.clear();
    });
  }

  void _calculateDiff() {
    if (_stokSistemCtrl.text.isNotEmpty && _stokFisikCtrl.text.isNotEmpty) {
      try {
        // PERBAIKAN: Gunakan tryParse agar lebih aman (anti crash)
        double sistem = double.tryParse(_stokSistemCtrl.text) ?? 0;
        double fisik = double.tryParse(_stokFisikCtrl.text) ?? 0;
        double selisih = fisik - sistem;

        // Format tampilan (+ atau -)
        if (selisih % 1 == 0) {
          _selisihCtrl.text = (selisih > 0 ? "+${selisih.toInt()}" : "${selisih.toInt()}");
        } else {
          _selisihCtrl.text = (selisih > 0 ? "+$selisih" : "$selisih");
        }
      } catch (e) {
        _selisihCtrl.text = "0";
      }
    }
  }

  void _saveAdjustment() async {
    if (_stokFisikCtrl.text.isEmpty || _alasanCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stok Fisik dan Alasan Wajib Diisi!"), backgroundColor: Colors.red));
      return;
    }

    Map<String, String> data = {
      "inventory_id": _selectedItem!['inventory_id'].toString(),
      "qty_system": _stokSistemCtrl.text,
      "qty_actual": _stokFisikCtrl.text,
      "reason": _alasanCtrl.text
    };

    var result = await _service.adjustStock(data);

    if (result['success'] == true) {
      _fetchData();
      setState(() => _isFormVisible = false);
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Gagal menyimpan penyesuaian"), backgroundColor: Colors.red)
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const SizedBox(height: 10),
        const Text("Stok berhasil disesuaikan!"),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup"))
      ]),
    ));
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return _isFormVisible ? _buildAdjustmentForm() : _buildStockTable();
  }

  Widget _buildStockTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text("Stok Barang (Opname)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
            const Spacer(),
            Container(
              width: 250, height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.search, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                    controller: _searchCtrl,
                    onChanged: _filterData,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: "Cari Nama / Kode...", isCollapsed: true)
                ))
              ]),
            ),
          ]),
          const SizedBox(height: 20),

          // Header Tabel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Expanded(flex: 3, child: Text("NAMA BARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text("JENIS / KAT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Text("STOK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text("TGL DATANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text("EXPIRED", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Center(child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              SizedBox(width: 80, child: Center(child: Text("AKSI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            ]),
          ),
          const SizedBox(height: 10),

          // List Data
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredList.length,
            itemBuilder: (context, index) {
              final item = _filteredList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                child: Row(children: [
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['item_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(item['unique_code'] ?? '-', style: TextStyle(fontSize: 11, color: vosenDarkBlue)),
                  ])),
                  Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['type_name'] ?? '-', style: const TextStyle(fontSize: 12)),
                    Text(item['category_name'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ])),
                  Expanded(flex: 1, child: Text(item['qty_current'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text(_formatDate(item['date_in']), style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(_formatDate(item['expired_date']), style: const TextStyle(fontSize: 13))),

                  // PERBAIKAN: Fungsi ini sudah aman dari error String vs Int
                  Expanded(flex: 2, child: _buildStatusBadge(item)),

                  SizedBox(width: 80, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50, foregroundColor: Colors.orange.shade900, elevation: 0, padding: EdgeInsets.zero, minimumSize: const Size(0, 35)),
                    onPressed: () => _openAdjustment(item),
                    child: const Text("Adjust", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  )),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentForm() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isFormVisible = false)),
          const SizedBox(width: 10),
          Text("Penyesuaian Stok (Adjustment)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: vosenDarkBlue)),
        ]),
        const Divider(height: 30),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            _buildInput("Nama Barang (Kode Unik)", _namaBarangCtrl, isReadOnly: true, color: readOnlyColor),
            _buildInput("Stok Tercatat di Sistem", _stokSistemCtrl, isReadOnly: true, color: readOnlyColor),
            _buildInput("Alasan Penyesuaian (Wajib Isi)", _alasanCtrl, maxLines: 3, isMandatory: true),
          ])),
          const SizedBox(width: 30),
          Expanded(child: Column(children: [
            _buildInput("Stok Fisik (Hasil Opname) *", _stokFisikCtrl, isNumber: true, onChanged: (_) => _calculateDiff()),
            _buildInput("Selisih (Adjustment)", _selisihCtrl, isReadOnly: true, color: readOnlyColor),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade200)), child: Row(children: [const Icon(Icons.info_outline, color: Colors.blue), const SizedBox(width: 10), Expanded(child: Text("Selisih negatif (-) = Stok Hilang/Rusak.\nSelisih positif (+) = Stok Bertambah.", style: TextStyle(fontSize: 12, color: vosenDarkBlue)))]))
          ])),
        ]),
        const SizedBox(height: 30),
        Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: vosenDarkBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), onPressed: _saveAdjustment, icon: const Icon(Icons.save_as), label: const Text("Simpan Penyesuaian")))
      ]),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isReadOnly = false, Color? color, bool isNumber = false, Function(String)? onChanged, int maxLines = 1, bool isMandatory = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(text: TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), children: [if (isMandatory) const TextSpan(text: " *", style: TextStyle(color: Colors.red))])),
      const SizedBox(height: 8),
      TextField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(filled: true, fillColor: color ?? Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)))
      )
    ]));
  }

  Widget _buildStatusBadge(Map<String, dynamic> item) {
    // --- PERBAIKAN KRUSIAL DISINI ---
    // Gunakan tryParse untuk mencegah error jika data dari DB berupa string
    int qty = int.tryParse(item['qty_current'].toString()) ?? 0;
    int minStock = int.tryParse(item['min_stock'].toString()) ?? 0;

    DateTime? expDate;
    if (item['expired_date'] != null) {
      expDate = DateTime.tryParse(item['expired_date']);
    }

    String statusText = "Good";
    Color bg = Colors.green.shade100;
    Color text = Colors.green.shade900;

    if (qty == 0) {
      statusText = "Out of Stock"; bg = Colors.black12; text = Colors.black;
    } else if (expDate != null && DateTime.now().isAfter(expDate)) {
      statusText = "Expired"; bg = Colors.red.shade100; text = Colors.red.shade900;
    } else if (qty < minStock) {
      statusText = "Low Stock"; bg = Colors.orange.shade100; text = Colors.orange.shade900;
    }

    return Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)), child: Text(statusText, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold))));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }
}