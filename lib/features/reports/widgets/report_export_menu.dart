import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';
import '../services/report_export_service.dart';

class ReportExportMenu extends StatefulWidget {
  final ReportOverallData reportData;
  final ReportConfiguration config;

  const ReportExportMenu({
    super.key,
    required this.reportData,
    required this.config,
  });

  @override
  State<ReportExportMenu> createState() => _ReportExportMenuState();
}

class _ReportExportMenuState extends State<ReportExportMenu> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = CRMColors.primary;

    if (_isExporting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<String>(
      onSelected: _handleExport,
      tooltip: 'Export Business Report',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626), size: 18),
              SizedBox(width: 10),
              Text('Export as PDF Document', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, color: Color(0xFF16A34A), size: 18),
              SizedBox(width: 10),
              Text('Export for Excel (.xls)', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF0284C7), size: 18),
              SizedBox(width: 10),
              Text('Export as CSV Spreadsheet', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print_outlined, color: Color(0xFF64748B), size: 18),
              SizedBox(width: 10),
              Text('Print Document', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download_outlined, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Export',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(String type) async {
    setState(() => _isExporting = true);
    try {
      switch (type) {
        case 'pdf':
          await ReportExportService.exportPdf(reportData: widget.reportData, config: widget.config);
          _showSnackbar('PDF Report generated and downloaded.');
          break;
        case 'excel':
          await ReportExportService.exportExcel(reportData: widget.reportData, config: widget.config);
          _showSnackbar('Excel Report generated and downloaded.');
          break;
        case 'csv':
          await ReportExportService.exportCsv(reportData: widget.reportData, config: widget.config);
          _showSnackbar('CSV Report generated and downloaded.');
          break;
        case 'print':
          await ReportExportService.printReport(reportData: widget.reportData, config: widget.config);
          _showSnackbar('Print document prepared.');
          break;
      }
    } catch (e) {
      _showSnackbar('Export error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
