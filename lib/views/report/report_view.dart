import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cims_app/widgets/custom_sidebar.dart';
import 'package:cims_app/services/report/report_service.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_selector/file_selector.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  final Color vosenDarkBlue = const Color(0xFF0A2A4D);
  final Color bgGrey = const Color(0xFFF5F7FA);

  String _selectedReportType = 'STOK_AKHIR';
  final _searchCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  final Map<String, String?> _activeFilters = {};

  List<dynamic> _reportData = [];
  final ReportService _service = ReportService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    final data = await _service.getReportData(
        _selectedReportType,
        start: _startDate,
        end: _endDate
    );
    if (mounted) setState(() => _reportData = data);
  }

  List<dynamic> get filteredData {
    List<dynamic> source = _reportData;

    if (_searchCtrl.text.isNotEmpty) {
      source = source.where((item) {
        return item.values.any((val) =>
            val.toString().toLowerCase().contains(
                _searchCtrl.text.toLowerCase()));
      }).toList();
    }

    _activeFilters.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        String dbKey = "";
        if (key == "Kategori") dbKey = "category_name";
        if (key == "Status") dbKey = "status";
        if (key == "Manufaktur") dbKey = "manufacturer_name";
        if (key == "Supplier") dbKey = "supplier_name";
        if (key == "Transaksi") dbKey = "type";

        if (dbKey.isNotEmpty) {
          source = source.where((item) {
            return item[dbKey]?.toString().contains(value) ?? false;
          }).toList();
        }
      }
    });

    return source;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomSidebar(activeMenu: "Report"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Laporan & Analisa", style: TextStyle(fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: vosenDarkBlue)),
                      const SizedBox(height: 5),
                      Text(
                          "Rekap data stok, histori masuk/keluar, dan status barang.",
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopToolbar(),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),

                        _buildFilterInputs(),

                        if (_activeFilters.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          _buildActiveFiltersArea(),
                        ],

                        const SizedBox(height: 30),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth),
                                child: _selectedReportType == 'STOK_AKHIR'
                                    ? _buildTableStokAkhir(constraints.maxWidth)
                                    : _buildTableMutasi(constraints.maxWidth),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildTopToolbar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: "Cari data laporan...",
                filled: true,
                fillColor: bgGrey,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 15)),
          ),
        ),
        const Spacer(),
        _buildModernExportButton(),
      ],
    );
  }

  Widget _buildModernExportButton() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) =>
      [
        PopupMenuItem(value: "Excel",
            child: Row(children: const [
              Icon(Icons.table_view, color: Colors.green),
              SizedBox(width: 10),
              Text("Export to Excel")
            ])),
        PopupMenuItem(value: "PDF",
            child: Row(children: const [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 10),
              Text("Export to PDF")
            ])),
      ],
      onSelected: (val) => val == "Excel" ? _exportToExcel() : _exportToPdf(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.download_rounded, size: 20, color: vosenDarkBlue),
          const SizedBox(width: 10),
          Text("Export Data", style: TextStyle(
              fontWeight: FontWeight.bold, color: vosenDarkBlue)),
          const SizedBox(width: 5),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey)
        ]),
      ),
    );
  }

  Widget _buildFilterInputs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tipe Laporan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                height: 45, padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReportType,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    items: const [
                      DropdownMenuItem(value: "STOK_AKHIR",
                          child: Text("Laporan Stok Akhir",
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: "MUTASI",
                          child: Text("Laporan Riwayat Transaksi",
                              overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedReportType = val!;
                        _activeFilters.clear();
                      });
                      _fetchData();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dari Tanggal", style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildDateInput("Pilih Tgl...", _startDateCtrl, true)
                ])),
        const SizedBox(width: 15),
        Expanded(flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sampai Tanggal", style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildDateInput("Pilih Tgl...", _endDateCtrl, false)
                ])),
        const SizedBox(width: 15),
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          itemBuilder: (context) {
            List<String> options = _selectedReportType == 'STOK_AKHIR' ? [
              "Kategori",
              "Status",
              "Manufaktur",
              "Supplier"
            ] : ["Transaksi"];
            return options
                .map((o) => PopupMenuItem(value: o, child: Text(o)))
                .toList();
          },
          onSelected: (val) =>
              setState(() {
                if (!_activeFilters.containsKey(val))
                  _activeFilters[val] = null;
              }),
          child: Container(
            height: 45, padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: vosenDarkBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: vosenDarkBlue.withOpacity(0.2))),
            child: Row(children: [
              Icon(Icons.filter_list, size: 18, color: vosenDarkBlue),
              const SizedBox(width: 8),
              Text("Tambah Filter", style: TextStyle(
                  color: vosenDarkBlue, fontWeight: FontWeight.bold))
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(color: bgGrey,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)),
      child: Wrap(spacing: 15,
          runSpacing: 10,
          children: _activeFilters.entries.map((entry) {
            if (entry.value == null) return _buildInlineDropdown(entry.key);
            return Chip(label: Text("${entry.key}: ${entry.value}",
                style: TextStyle(fontSize: 12,
                    color: vosenDarkBlue,
                    fontWeight: FontWeight.w600)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: vosenDarkBlue.withOpacity(0.2))),
                deleteIcon: const Icon(
                    Icons.close, size: 16, color: Colors.red),
                onDeleted: () =>
                    setState(() => _activeFilters.remove(entry.key)),
                elevation: 1);
          }).toList()),
    );
  }

  Widget _buildInlineDropdown(String key) {
    List<String> items = [];
    if (key == "Kategori") items = ["Reagen", "Media", "Chemical"];
    if (key == "Status") items = ["Active", "Expired", "Low Stock"];
    if (key == "Transaksi") items = ["IN", "OUT", "ADJUSTMENT"];
    if (key == "Manufaktur")
      items = ["PT. Merck", "Sigma Aldrich", "3M", "Smart Lab"];
    if (key == "Supplier")
      items = ["PT. Indofa", "PT. Pancamandiri", "PT. Bratachem"];

    return Container(
      height: 35, padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: null,
          hint: Text("Pilih $key...",
              style: TextStyle(fontSize: 12, color: vosenDarkBlue)),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          items: items
              .map((String item) =>
              DropdownMenuItem<String>(value: item,
                  child: Text(item, style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (val) => setState(() => _activeFilters[key] = val))),
    );
  }

  Widget _buildDateInput(String hint, TextEditingController controller,
      bool isStart) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 15, vertical: 0),
          suffixIcon: const Icon(
              Icons.calendar_today, color: Colors.grey, size: 16)),
      onTap: () async {
        DateTime? p = await showDatePicker(context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030));
        if (p != null) {
          controller.text = DateFormat('dd/MM/yyyy').format(p);
          setState(() {
            if (isStart)
              _startDate = p;
            else
              _endDate = p;
          });
          _fetchData();
        }
      },
    );
  }

  // --- TABLE ---

  Widget _buildTableStokAkhir(double availableWidth) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(bgGrey),
      dataRowColor: MaterialStateProperty.all(Colors.white),
      columnSpacing: availableWidth < 1000 ? 20 : (availableWidth / 15),
      columns: const [
        DataColumn(
            label: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Nama Barang", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Kode Unik", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Kategori", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Manufaktur", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Supplier", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Kemasan", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Sisa Stok", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Tgl Datang", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Pemilik", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Status", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: filteredData
          .asMap()
          .entries
          .map((entry) {
        var item = entry.value;
        return DataRow(cells: [
          DataCell(Text((entry.key + 1).toString())),
          DataCell(Text(item['item_name'] ?? "-")),
          DataCell(Text(item['unique_code'] ?? "-", style: TextStyle(
              color: vosenDarkBlue, fontWeight: FontWeight.bold))),
          DataCell(Text(item['category_name'] ?? "-")),
          DataCell(Text(item['manufacturer_name'] ?? "-")),
          DataCell(Text(item['supplier_name'] ?? "-")),
          DataCell(Text(item['packaging_name'] ?? "-")),
          DataCell(Text(item['qty_current'].toString(), style: TextStyle(
              fontWeight: FontWeight.bold, color: vosenDarkBlue))),
          DataCell(Text(item['date_in'] ?? "-")),
          DataCell(Text(item['owner_name'] ?? "-")),
          DataCell(_buildStatusBadge(item['status'] ?? "Active")),
        ]);
      }).toList(),
    );
  }

  Widget _buildTableMutasi(double availableWidth) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(bgGrey),
      columnSpacing: availableWidth < 800 ? 20 : (availableWidth / 10),
      columns: const [
        DataColumn(
            label: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Tanggal", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "No. Transaksi", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text("Tipe", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Nama Barang", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(
            "Keterangan", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: filteredData
          .asMap()
          .entries
          .map((entry) {
        var item = entry.value;
        // PERBAIKAN ICON: Pastikan string UPPERCASE dan Row tidak memenuhi width
        String type = (item['type'] ?? "-").toString().toUpperCase();
        Color typeColor = Colors.grey;
        Color typeBg = Colors.grey.shade200;
        IconData typeIcon = Icons.help_outline;

        if (type == "IN") {
          typeColor = Colors.green;
          typeBg = Colors.green.shade50;
          typeIcon = Icons.arrow_downward;
        }
        else if (type == "OUT") {
          typeColor = Colors.red;
          typeBg = Colors.red.shade50;
          typeIcon = Icons.arrow_upward;
        }
        else if (type == "ADJUSTMENT") {
          typeColor = Colors.blue;
          typeBg = Colors.blue.shade50;
          typeIcon = Icons.tune;
        }

        return DataRow(cells: [
          DataCell(Text((entry.key + 1).toString())),
          DataCell(Text(item['trans_date'] ?? "-")),
          DataCell(Text(item['trans_no'] ?? "-")),
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: typeBg, borderRadius: BorderRadius.circular(4)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // WAJIB AGAR ICON MUNCUL DI DATACELL
              children: [
                Icon(typeIcon, size: 16, color: typeColor),
                const SizedBox(width: 5),
                Text(type, style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: typeColor)),
              ],
            ),
          )),
          DataCell(Text(item['item_name'] ?? "-")),
          DataCell(Text(item['qty'].toString())),
          DataCell(Text(item['ket'] ?? "-")),
        ]);
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade200;
    Color text = Colors.grey.shade800;
    if (status == "Active") {
      bg = const Color(0xFFE8F5E9);
      text = Colors.green;
    }
    else if (status == "Expired") {
      bg = const Color(0xFFFFEBEE);
      text = Colors.red;
    }
    else if (status == "Low Stock") {
      bg = const Color(0xFFFFFDE7);
      text = Colors.orange;
    }
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(status, style: TextStyle(
            color: text, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  // ===========================================================================
  // FUNGSI EXPORT LANGSUNG KE DOWNLOADS (SOLUSI ANTI ERROR)
  // ===========================================================================

  Future<String> _getDownloadsPath() async {
    // Logic khusus Windows untuk mencari folder Downloads
    if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Downloads';
    }
    // Default fallback (meski kita tahu ini Windows)
    return Directory.current.path;
  }

// ===========================================================================
  // FUNGSI EXPORT LENGKAP (SESUAI TABEL UI)
  // ===========================================================================

  // 1. EXCEL
  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      // HEADER LENGKAP
      List<String> headers = [];
      if (_selectedReportType == 'STOK_AKHIR') {
        headers = [
          "No",
          "Nama Barang",
          "Kode Unik",
          "Kategori",
          "Manufaktur",
          "Supplier",
          "Kemasan",
          "Sisa Stok",
          "Tgl Datang",
          "Pemilik",
          "Status"
        ];
      } else {
        headers = [
          "No",
          "Tanggal",
          "No. Transaksi",
          "Tipe",
          "Nama Barang",
          "Qty",
          "Keterangan"
        ];
      }

      // Style Header (Bold) - Opsional, Excel package defaultnya plain
      sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // BODY LENGKAP
      for (int i = 0; i < filteredData.length; i++) {
        var item = filteredData[i];
        if (_selectedReportType == 'STOK_AKHIR') {
          sheet.appendRow([
            TextCellValue((i + 1).toString()),
            TextCellValue(item['item_name'] ?? "-"),
            TextCellValue(item['unique_code'] ?? "-"),
            TextCellValue(item['category_name'] ?? "-"),
            TextCellValue(item['manufacturer_name'] ?? "-"),
            TextCellValue(item['supplier_name'] ?? "-"),
            TextCellValue(item['packaging_name'] ?? "-"),
            IntCellValue(int.tryParse(item['qty_current'].toString()) ?? 0),
            // Format Angka
            TextCellValue(item['date_in'] ?? "-"),
            TextCellValue(item['owner_name'] ?? "-"),
            TextCellValue(item['status'] ?? "-"),
          ]);
        } else {
          sheet.appendRow([
            TextCellValue((i + 1).toString()),
            TextCellValue(item['trans_date'] ?? "-"),
            TextCellValue(item['trans_no'] ?? "-"),
            TextCellValue(item['type'] ?? "-"),
            TextCellValue(item['item_name'] ?? "-"),
            IntCellValue(int.tryParse(item['qty'].toString()) ?? 0),
            // Format Angka
            TextCellValue(item['ket'] ?? "-"),
          ]);
        }
      }

      // SIMPAN KE DOWNLOADS
      String downloadsPath = await _getDownloadsPath();
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = "Laporan_${_selectedReportType}_$timestamp.xlsx";
      String fullPath = "$downloadsPath\\$fileName";

      final file = File(fullPath);
      await file.writeAsBytes(excel.save()!, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Berhasil! File di: Downloads\\$fileName"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal Export: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // 2. EXPORT PDF (PORTRAIT - FONT KECIL - MUAT SEMUA)
  Future<void> _exportToPdf() async {
    try {
      final doc = pw.Document();

      final headers = _selectedReportType == 'STOK_AKHIR'
          ? [
        "No",
        "Nama",
        "Kode",
        "Kategori",
        "Manufaktur",
        "Supplier",
        "Kemasan",
        "Stok",
        "Tgl Masuk",
        "Pemilik",
        "Status"
      ]
          : ["No", "Tgl", "No. Trans", "Tipe", "Nama Barang", "Qty", "Ket"];

      final data = filteredData
          .asMap()
          .entries
          .map((entry) {
        var i = entry.value;
        if (_selectedReportType == 'STOK_AKHIR') {
          return [
            (entry.key + 1).toString(),
            i['item_name'] ?? "-",
            i['unique_code'] ?? "-",
            i['category_name'] ?? "-",
            i['manufacturer_name'] ?? "-", // Nama Manufaktur (biasanya panjang)
            i['supplier_name'] ?? "-",
            i['packaging_name'] ?? "-",
            i['qty_current'].toString(),
            i['date_in'] ?? "-",
            i['owner_name'] ?? "-",
            i['status'] ?? "-"
          ];
        } else {
          return [
            (entry.key + 1).toString(),
            i['trans_date'] ?? "-",
            i['trans_no'] ?? "-",
            i['type'] ?? "-",
            i['item_name'] ?? "-",
            i['qty'].toString(),
            i['ket'] ?? "-"
          ];
        }
      }).toList();

      doc.addPage(pw.Page(
        // KEMBALI KE PORTRAIT
          pageFormat: PdfPageFormat.a4,

          // Margin Tipis (1.5 cm) agar area tabel luas
          margin: const pw.EdgeInsets.all(15),

          build: (pw.Context context) {
            return pw.Column(children: [
              pw.Header(level: 0,
                  child: pw.Text("Laporan $_selectedReportType",
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                  context: context,
                  data: [headers, ...data],

                  // FONT KECIL AGAR MUAT 11 KOLOM DI PORTRAIT
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 7),
                  cellStyle: const pw.TextStyle(fontSize: 6),

                  headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft, // No
                    7: pw.Alignment.centerRight, // Stok (Angka)
                  }
              ),
            ]);
          }
      ));

      final bytes = await doc.save();

      // SIMPAN KE DOWNLOADS
      String downloadsPath = await _getDownloadsPath();
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = "Laporan_${_selectedReportType}_$timestamp.pdf";
      String fullPath = "$downloadsPath\\$fileName";

      final file = File(fullPath);
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                "Berhasil! PDF Portrait di: Downloads\\$fileName"),
                backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal Export: $e"), backgroundColor: Colors.red));
      }
    }
  }
}