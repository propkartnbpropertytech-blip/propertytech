/// ============================================================================
/// ⚠️ PROPKART MASTER KPI GOVERNANCE RULE:
/// All exported Excel/CSV/PDF reports and operational KPI sheets generated here
/// MUST adhere to the Master KPI Rulebook: lib/core/constants/kpi_rulebook.dart
/// and docs/KPIs.docx.
/// ============================================================================
import '../../../core/constants/kpi_rulebook.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../../../core/utils/file_downloader.dart';
import '../../../core/utils/formatters.dart';
import '../models/report_kpi_type.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';

class ReportExportService {
  static const String defaultReportTitle = 'PropKart CRM - Overall Business Insight';
  static const String defaultCsvTitle = 'PropKart CRM - Overall Business Insight Report';
  static const String defaultFilenamePrefix = 'PropKart_Overall_Business_Insight';

  /// Build PDF Document
  static pw.Document buildPdfDocument({
    required ReportOverallData reportData,
    required ReportConfiguration config,
    String? reportTitle,
    String? subjectLabel,
  }) {
    final pdf = pw.Document();
    final dateStr = config.dateRange.formattedRange.replaceAll('–', '-').replaceAll('—', '-');
    final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final title = reportTitle ?? defaultReportTitle;

    // 1. Gather enabled KPIs
    final enabledKpis = config.sortedEnabledKpis;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('14213D'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Reporting Period: $dateStr',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                    ),
                    if (subjectLabel != null && subjectLabel.isNotEmpty)
                      pw.Text(
                        subjectLabel,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('0284C7'),
                        ),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: $generatedAt',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                    if (config.filters.hasActiveFilters)
                      pw.Text(
                        '${config.filters.activeFiltersCount} Filters Applied',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('0284C7'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Active Filters Summary (if any)
            if (config.filters.hasActiveFilters) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Active Filter Context:',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Wrap(
                      spacing: 8,
                      children: [
                        if (config.filters.leadSource != null)
                          pw.Text('Source: ${config.filters.leadSource}', style: const pw.TextStyle(fontSize: 8)),
                        if (config.filters.leadStatus != null)
                          pw.Text('Status: ${config.filters.leadStatus}', style: const pw.TextStyle(fontSize: 8)),
                        if (config.filters.telecallerName != null)
                          pw.Text('Telecaller: ${config.filters.telecallerName}', style: const pw.TextStyle(fontSize: 8)),
                        if (config.filters.salesUserName != null)
                          pw.Text('Sales: ${config.filters.salesUserName}', style: const pw.TextStyle(fontSize: 8)),
                        if (config.filters.leadType != null)
                          pw.Text('Type: ${config.filters.leadType}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ],

            // Section: Key Performance Indicators
            pw.Text(
              'Key Performance Indicators',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Metric', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Count', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Percentage', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Basis / Denominator', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                for (final k in enabledKpis) ...[
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(k.type.displayName, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          k.showCount ? (reportData.kpiValues[k.type]?.formattedCount ?? '0') : '-',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          k.showPercentage ? (reportData.kpiValues[k.type]?.formattedPercentage ?? '0.0%') : '-',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          reportData.kpiValues[k.type]?.denominatorLabel ?? '',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 16),

            // Section: Pipeline Breakdown (if enabled)
            if (config.showLeadStatusPipeline && reportData.pipelineStages.isNotEmpty) ...[
              pw.Text(
                'Lead Status Pipeline',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Stage / Status', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Leads Count', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('% of Pipeline', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  for (final stage in reportData.pipelineStages) ...[
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(stage.displayName, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(stage.count.toString(), style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${stage.percentage.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Section: Conversion Funnel (if enabled)
            if (config.showConversionFunnel) ...[
              pw.Text(
                'Conversion Funnel',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Funnel Stage', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Volume', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Step Conversion %', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Overall Conversion %', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  for (final f in reportData.funnelStages) ...[
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(f.stageName, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(f.count.toString(), style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${f.stageConversionRate.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${f.totalConversionRate.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Section: Team Ranking (if enabled)
            if (config.showTeamRanking && reportData.salesRankings.isNotEmpty) ...[
              pw.Text(
                'Top Sales Performers',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rank', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Sales Rep', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Leads', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Contacted', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Site Visits', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Won Deals', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Conversion %', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  for (final s in reportData.salesRankings.take(8)) ...[
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('#${s.rank}', style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.userName, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.leadsCount.toString(), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.contactedCount.toString(), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.siteVisitsCount.toString(), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.wonCount.toString(), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${s.conversionRate.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8))),
                      ],
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Section: Lead Source Breakdown (if enabled)
            if (config.showLeadSourceAnalysis && reportData.leadSources.isNotEmpty) ...[
              pw.Text(
                'Lead Sources Analysis',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Source', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Count', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Share %', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  for (final src in reportData.leadSources) ...[
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(src.source, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(src.count.toString(), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${src.percentage.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8))),
                      ],
                    ),
                  ],
                ],
              ),
            ],

            // Section: Growth & Comparison Breakdown (if enabled)
            if (config.showGrowthComparison && reportData.growthComparisonItems.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text(
                'Growth & Comparison (${config.comparisonPeriod.displayName})',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Metric', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Current Period', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Previous Period', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Difference', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Growth %', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  for (final item in reportData.growthComparisonItems) ...[
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.metricName, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.currentCount.toString(), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.previousCount.toString(), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.difference >= 0 ? '+' : ''}${item.difference}', style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.difference >= 0 ? '+' : ''}${item.growthPercentage.toStringAsFixed(2)}%', style: const pw.TextStyle(fontSize: 8))),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ];
        },
      ),
    );
    return pdf;
  }

  /// Export PDF Report
  static Future<void> exportPdf({
    required ReportOverallData reportData,
    required ReportConfiguration config,
    String? reportTitle,
    String? subjectLabel,
    String? filenamePrefix,
  }) async {
    final pdf = buildPdfDocument(
      reportData: reportData,
      config: config,
      reportTitle: reportTitle,
      subjectLabel: subjectLabel,
    );
    final bytes = await pdf.save();
    final prefix = filenamePrefix ?? defaultFilenamePrefix;
    final filename = '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    await FileDownloader.download(bytes, filename);
  }

  /// Generate CSV string content
  static String generateCsvContent({
    required ReportOverallData reportData,
    required ReportConfiguration config,
    String? reportTitle,
    String? subjectLabel,
  }) {
    final buffer = StringBuffer();

    // Title & Context
    buffer.writeln('"${reportTitle ?? defaultCsvTitle}"');
    buffer.writeln('"Period","${config.dateRange.formattedRange}"');
    if (subjectLabel != null && subjectLabel.isNotEmpty) {
      buffer.writeln('"Subject","$subjectLabel"');
    }
    buffer.writeln('"Generated At","${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}"');
    buffer.writeln();

    // 1. KPI Section
    buffer.writeln('"=== KEY PERFORMANCE INDICATORS ==="');
    buffer.writeln('"Order","Metric","Count","Percentage","Denominator"');
    for (var i = 0; i < config.sortedEnabledKpis.length; i++) {
      final k = config.sortedEnabledKpis[i];
      final v = reportData.kpiValues[k.type];
      final countStr = k.showCount ? (v?.count.toString() ?? '0') : '';
      final pctStr = k.showPercentage ? (v?.formattedPercentage ?? '0.0%') : '';
      buffer.writeln('"${i + 1}","${k.type.displayName}","$countStr","$pctStr","${v?.denominatorLabel ?? ''}"');
    }
    buffer.writeln();

    // 2. Pipeline Section
    if (config.showLeadStatusPipeline) {
      buffer.writeln('"=== LEAD STATUS PIPELINE ==="');
      buffer.writeln('"Status","Count","Percentage"');
      for (final p in reportData.pipelineStages) {
        buffer.writeln('"${p.displayName}","${p.count}","${p.percentage.toStringAsFixed(1)}%"');
      }
      buffer.writeln();
    }

    // 3. Conversion Funnel Section
    if (config.showConversionFunnel) {
      buffer.writeln('"=== CONVERSION FUNNEL ==="');
      buffer.writeln('"Stage","Count","Stage Conversion %","Total Conversion %"');
      for (final f in reportData.funnelStages) {
        buffer.writeln('"${f.stageName}","${f.count}","${f.stageConversionRate.toStringAsFixed(1)}%","${f.totalConversionRate.toStringAsFixed(1)}%"');
      }
      buffer.writeln();
    }

    // 4. Team Rankings
    if (config.showTeamRanking) {
      buffer.writeln('"=== SALES TEAM RANKINGS ==="');
      buffer.writeln('"Rank","User","Leads","Contacted","Qualified","Site Visits","Won","Conversion Rate"');
      for (final s in reportData.salesRankings) {
        buffer.writeln('"${s.rank}","${s.userName}","${s.leadsCount}","${s.contactedCount}","${s.qualifiedCount}","${s.siteVisitsCount}","${s.wonCount}","${s.conversionRate.toStringAsFixed(1)}%"');
      }
      buffer.writeln();

      buffer.writeln('"=== TELECALLER TEAM RANKINGS ==="');
      buffer.writeln('"Rank","User","Leads","Contacted","Qualified","Site Visits","Won","Conversion Rate"');
      for (final t in reportData.telecallerRankings) {
        buffer.writeln('"${t.rank}","${t.userName}","${t.leadsCount}","${t.contactedCount}","${t.qualifiedCount}","${t.siteVisitsCount}","${t.wonCount}","${t.conversionRate.toStringAsFixed(1)}%"');
      }
      buffer.writeln();
    }

    // 5. Growth & Comparison Section
    if (config.showGrowthComparison && reportData.growthComparisonItems.isNotEmpty) {
      buffer.writeln('"=== GROWTH & COMPARISON (${config.comparisonPeriod.displayName}) ==="');
      buffer.writeln('"Metric","Current Period","Previous Period","Difference","Growth %"');
      for (final g in reportData.growthComparisonItems) {
        final diffStr = '${g.difference >= 0 ? '+' : ''}${g.difference}';
        final growthStr = '${g.difference >= 0 ? '+' : ''}${g.growthPercentage.toStringAsFixed(2)}%';
        buffer.writeln('"${g.metricName}","${g.currentCount}","${g.previousCount}","$diffStr","$growthStr"');
      }
      buffer.writeln();
    }

    // 6. Lead Sources Section
    if (config.showLeadSourceAnalysis && reportData.leadSources.isNotEmpty) {
      buffer.writeln('"=== LEAD SOURCES ANALYSIS ==="');
      buffer.writeln('"Source","Count","Share %"');
      for (final src in reportData.leadSources) {
        buffer.writeln('"${src.source}","${src.count}","${src.percentage.toStringAsFixed(1)}%"');
      }
      buffer.writeln();
    }

    // 7. Raw Lead Rows for Detailed Auditing
    buffer.writeln('"=== FILTERED LEADS LIST ==="');
    buffer.writeln('"Lead Name","Mobile","Status","Created At","Assigned To","Telecaller / Creator","Budget Range","Category"');
    for (final l in reportData.filteredLeads) {
      final budgetStr = 'Rs ${l.minBudget.toInt()} - ${l.maxBudget.toInt()}';
      final createdStr = DateFormat('yyyy-MM-dd').format(l.createdAt);
      buffer.writeln('"${CsvSanitizer.sanitize(l.clientName)}","${CsvSanitizer.sanitize(l.clientMobile)}","${CsvSanitizer.sanitize(l.status)}","$createdStr","${CsvSanitizer.sanitize(l.assigneeName)}","${CsvSanitizer.sanitize(l.creatorName)}","${CsvSanitizer.sanitize(budgetStr)}","${CsvSanitizer.sanitize(l.categoryName)}"');
    }
    return buffer.toString();
  }

  /// Export CSV
  static Future<void> exportCsv({
    required ReportOverallData reportData,
    required ReportConfiguration config,
    String? reportTitle,
    String? subjectLabel,
    String? filenamePrefix,
  }) async {
    final content = generateCsvContent(
      reportData: reportData,
      config: config,
      reportTitle: reportTitle,
      subjectLabel: subjectLabel,
    );
    final bytes = utf8.encode(content);
    final prefix = filenamePrefix ?? 'PropKart_Business_Insight';
    final filename = '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    await FileDownloader.download(bytes, filename);
  }

  /// Build Genuine Multi-Sheet Excel (.xlsx) Workbook matching Master Template
  static Excel buildExcelDocument({
    required ReportOverallData reportData,
    required ReportConfiguration config,
    String? reportTitle,
    String? subjectLabel,
  }) {
    final excel = Excel.createExcel();

    // ────────────────────────────────────────────────────────────────────────────
    // 1. EXECUTIVE DASHBOARD SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final dashboardSheet = excel['Executive Dashboard'];
    dashboardSheet.appendRow([TextCellValue('PROPKART REAL ESTATE - AUTHORITATIVE EXECUTIVE KPI & INVENTORY DASHBOARD')]);
    dashboardSheet.appendRow([TextCellValue('Live Production CRM Audit • Master Operational & Analytical Records')]);
    dashboardSheet.appendRow([TextCellValue('Reporting Period:'), TextCellValue(config.dateRange.formattedRange)]);
    dashboardSheet.appendRow([TextCellValue('Export Generated:'), TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()))]);
    if (subjectLabel != null && subjectLabel.isNotEmpty) {
      dashboardSheet.appendRow([TextCellValue('Subject Context:'), TextCellValue(subjectLabel)]);
    }
    if (config.filters.hasActiveFilters) {
      dashboardSheet.appendRow([TextCellValue('Active Filters:'), TextCellValue('${config.filters.activeFiltersCount} filters applied')]);
    }
    dashboardSheet.appendRow([]);

    // Headline Metrics
    final totalLeads = reportData.kpiValues[ReportKpiType.totalLeads]?.count ?? 0;
    final contacted = reportData.kpiValues[ReportKpiType.leadsContacted]?.count ?? 0;
    final won = reportData.kpiValues[ReportKpiType.convertedToWon]?.count ?? 0;
    final convRate = reportData.kpiValues[ReportKpiType.convertedToWon]?.percentage ?? 0.0;
    final availableProps = reportData.availableProperties.where((p) => p.propertyStatusName.toLowerCase() == 'available').length;

    dashboardSheet.appendRow([
      TextCellValue('Available Inventory'),
      IntCellValue(availableProps > 0 ? availableProps : reportData.availableProperties.length),
      TextCellValue('Total Leads'),
      IntCellValue(totalLeads),
      TextCellValue('Contacted'),
      IntCellValue(contacted),
      TextCellValue('Deals Won'),
      IntCellValue(won),
      TextCellValue('Conversion Rate %'),
      TextCellValue('${convRate.toStringAsFixed(1)}%'),
    ]);
    dashboardSheet.appendRow([]);

    // Operational KPI Breakdown Table
    dashboardSheet.appendRow([TextCellValue('=== OPERATIONAL KPI BREAKDOWN ===')]);
    dashboardSheet.appendRow([
      TextCellValue('Order'),
      TextCellValue('KPI Metric'),
      TextCellValue('Count'),
      TextCellValue('Percentage'),
      TextCellValue('Denominator / Basis'),
    ]);
    for (var i = 0; i < config.sortedEnabledKpis.length; i++) {
      final k = config.sortedEnabledKpis[i];
      final v = reportData.kpiValues[k.type];
      dashboardSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(k.type.displayName),
        k.showCount ? IntCellValue(v?.count ?? 0) : TextCellValue('—'),
        k.showPercentage ? TextCellValue(v?.formattedPercentage ?? '0.0%') : TextCellValue('—'),
        TextCellValue(v?.denominatorLabel ?? ''),
      ]);
    }
    dashboardSheet.appendRow([]);

    // Lead Sources Table
    if (reportData.leadSources.isNotEmpty) {
      dashboardSheet.appendRow([TextCellValue('=== LEAD SOURCE DISTRIBUTION ===')]);
      dashboardSheet.appendRow([
        TextCellValue('Lead Source'),
        TextCellValue('Count'),
        TextCellValue('Share %'),
      ]);
      for (final src in reportData.leadSources) {
        dashboardSheet.appendRow([
          TextCellValue(src.source),
          IntCellValue(src.count),
          DoubleCellValue(double.parse(src.percentage.toStringAsFixed(2))),
        ]);
      }
      dashboardSheet.appendRow([]);
    }

    // Pipeline Stages Table
    if (reportData.pipelineStages.isNotEmpty) {
      dashboardSheet.appendRow([TextCellValue('=== PIPELINE STATUS BREAKDOWN ===')]);
      dashboardSheet.appendRow([
        TextCellValue('Pipeline Stage'),
        TextCellValue('Leads Count'),
        TextCellValue('Share %'),
      ]);
      for (final s in reportData.pipelineStages) {
        dashboardSheet.appendRow([
          TextCellValue(s.displayName),
          IntCellValue(s.count),
          DoubleCellValue(double.parse(s.percentage.toStringAsFixed(2))),
        ]);
      }
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 2. PROPERTIES (INVENTORY) SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final propsSheet = excel['Properties'];
    propsSheet.appendRow([
      TextCellValue('Sr No'),
      TextCellValue('Property Code'),
      TextCellValue('Property Title'),
      TextCellValue('Property Status'),
      TextCellValue('Listing Type (Rental / Re-sale)'),
      TextCellValue('Added By Role'),
      TextCellValue('Added By Name'),
      TextCellValue('Category'),
      TextCellValue('Property Type'),
      TextCellValue('Configuration'),
      TextCellValue('Price / Rent (INR)'),
      TextCellValue('Deposit (INR)'),
      TextCellValue('Super Builtup Area (Sq.Ft)'),
      TextCellValue('Carpet Area (Sq.Ft)'),
      TextCellValue('Locality / Area'),
      TextCellValue('City'),
      TextCellValue('Owner Name'),
      TextCellValue('Owner Mobile'),
      TextCellValue('Date Added'),
    ]);

    for (var i = 0; i < reportData.availableProperties.length; i++) {
      final p = reportData.availableProperties[i];
      propsSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.propertyCode),
        TextCellValue(p.title),
        TextCellValue(p.propertyStatusName),
        TextCellValue(p.listingTypeName),
        TextCellValue(p.createdByName.isNotEmpty ? 'Staff' : 'Owner'),
        TextCellValue(p.createdByName),
        TextCellValue(p.categoryName),
        TextCellValue(p.propertyTypeName),
        TextCellValue(p.configurationName ?? 'N/A'),
        DoubleCellValue(p.price),
        DoubleCellValue(p.deposit),
        DoubleCellValue(p.superBuiltupArea ?? 0),
        DoubleCellValue(p.carpetArea ?? 0),
        TextCellValue(p.areaName.isNotEmpty ? p.areaName : p.address),
        TextCellValue(p.cityName),
        TextCellValue(p.ownerName),
        TextCellValue(p.ownerMobile),
        TextCellValue(DateFormat('yyyy-MM-dd').format(p.createdAt)),
      ]);
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 3. ALL LEADS SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final leadsList = reportData.allLeads.isNotEmpty ? reportData.allLeads : reportData.filteredLeads;
    final allLeadsSheet = excel['All Leads'];
    allLeadsSheet.appendRow([
      TextCellValue('Sr No'),
      TextCellValue('Lead Date & Time'),
      TextCellValue('Source'),
      TextCellValue('Lead Type'),
      TextCellValue('Customer Name'),
      TextCellValue('Contact Mobile'),
      TextCellValue('Email'),
      TextCellValue('City / Locality'),
      TextCellValue('Property Type & Config'),
      TextCellValue('Budget Range (INR)'),
      TextCellValue('Allocated Telecaller'),
      TextCellValue('Telecaller Status'),
      TextCellValue('Assigned Sales Executive'),
      TextCellValue('Sales CRM Status'),
      TextCellValue('Remarks / Notes'),
    ]);

    for (var i = 0; i < leadsList.length; i++) {
      final l = leadsList[i];
      final budgetStr = 'Rs ${l.minBudget.toInt()} - ${l.maxBudget.toInt()}';
      final localityStr = l.areaNames.isNotEmpty ? l.areaNames.join(', ') : 'N/A';
      final typeConfigStr = '${l.configurationName ?? "" } ${l.propertyTypeName}'.trim();

      allLeadsSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(l.createdAt)),
        TextCellValue(l.leadSource ?? 'Direct'),
        TextCellValue(l.listingTypeName ?? 'Requirement'),
        TextCellValue(l.clientName),
        TextCellValue(l.clientMobile),
        TextCellValue(l.creatorEmail ?? ''),
        TextCellValue(localityStr),
        TextCellValue(typeConfigStr.isNotEmpty ? typeConfigStr : l.categoryName),
        TextCellValue(budgetStr),
        TextCellValue(l.creatorName ?? 'Unassigned'),
        TextCellValue(l.status),
        TextCellValue(l.assigneeName ?? 'Unassigned'),
        TextCellValue(l.assigneeName != null ? l.status : 'Not Assigned to Sales'),
        TextCellValue(l.remarks ?? l.notes ?? ''),
      ]);
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 4. INTERESTED LEADS SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final interestedLeads = leadsList.where((l) {
      final s = l.status.toLowerCase();
      final r = (l.remarks ?? '').toLowerCase();
      final n = (l.notes ?? '').toLowerCase();
      final isDisqualified = s.contains('cnr') || s.contains('not interested') || s.contains('lost') || r.contains('not interested') || n.contains('not interested');
      return !isDisqualified;
    }).toList();

    final interestedSheet = excel['Interested Leads'];
    interestedSheet.appendRow([
      TextCellValue('Sr No'),
      TextCellValue('Lead Date & Time'),
      TextCellValue('Customer Name'),
      TextCellValue('Contact Mobile'),
      TextCellValue('Email Address'),
      TextCellValue('Client Intent / Toggle'),
      TextCellValue('Current Status'),
      TextCellValue('Assigned Telecaller'),
      TextCellValue('Assigned Sales Executive'),
      TextCellValue('Budget / Expected Rent'),
      TextCellValue('Property Type & Config'),
      TextCellValue('Preferred Locality / Address'),
      TextCellValue('Telecaller & Sales Remarks'),
    ]);

    for (var i = 0; i < interestedLeads.length; i++) {
      final l = interestedLeads[i];
      final budgetStr = 'Rs ${l.minBudget.toInt()} - ${l.maxBudget.toInt()}';
      final localityStr = l.areaNames.isNotEmpty ? l.areaNames.join(', ') : 'N/A';
      final typeConfigStr = '${l.configurationName ?? "" } ${l.propertyTypeName}'.trim();
      final intentStr = l.listingTypeName?.toLowerCase().contains('rent') == true
          ? 'Tenant - Looking for Rent'
          : (l.listingTypeName?.toLowerCase().contains('sale') == true ? 'Buyer - Re-sale' : 'Active Inquirer');

      interestedSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(l.createdAt)),
        TextCellValue(l.clientName),
        TextCellValue(l.clientMobile),
        TextCellValue(l.creatorEmail ?? ''),
        TextCellValue(intentStr),
        TextCellValue(l.status),
        TextCellValue(l.creatorName ?? 'Unassigned'),
        TextCellValue(l.assigneeName ?? 'Unassigned'),
        TextCellValue(budgetStr),
        TextCellValue(typeConfigStr.isNotEmpty ? typeConfigStr : l.categoryName),
        TextCellValue(localityStr),
        TextCellValue(l.remarks ?? l.notes ?? ''),
      ]);
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 5. TEAM PERFORMANCE SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final teamSheet = excel['Team Performance'];
    teamSheet.appendRow([TextCellValue('=== SALES TEAM PERFORMANCE ===')]);
    teamSheet.appendRow([
      TextCellValue('Rank'),
      TextCellValue('Sales Executive'),
      TextCellValue('Leads Assigned'),
      TextCellValue('Contacted'),
      TextCellValue('Qualified'),
      TextCellValue('Site Visits'),
      TextCellValue('Deals Won'),
      TextCellValue('Conversion Rate %'),
    ]);
    for (final s in reportData.salesRankings) {
      teamSheet.appendRow([
        IntCellValue(s.rank),
        TextCellValue(s.userName),
        IntCellValue(s.leadsCount),
        IntCellValue(s.contactedCount),
        IntCellValue(s.qualifiedCount),
        IntCellValue(s.siteVisitsCount),
        IntCellValue(s.wonCount),
        DoubleCellValue(double.parse(s.conversionRate.toStringAsFixed(2))),
      ]);
    }

    teamSheet.appendRow([]);
    teamSheet.appendRow([TextCellValue('=== TELECALLER TEAM PERFORMANCE ===')]);
    teamSheet.appendRow([
      TextCellValue('Rank'),
      TextCellValue('Telecaller'),
      TextCellValue('Leads Handled'),
      TextCellValue('Contacted'),
      TextCellValue('Qualified'),
      TextCellValue('Site Visits'),
      TextCellValue('Deals Won'),
      TextCellValue('Conversion Rate %'),
    ]);
    for (final t in reportData.telecallerRankings) {
      teamSheet.appendRow([
        IntCellValue(t.rank),
        TextCellValue(t.userName),
        IntCellValue(t.leadsCount),
        IntCellValue(t.contactedCount),
        IntCellValue(t.qualifiedCount),
        IntCellValue(t.siteVisitsCount),
        IntCellValue(t.wonCount),
        DoubleCellValue(double.parse(t.conversionRate.toStringAsFixed(2))),
      ]);
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 6. FOLLOW-UPS SHEET (if enabled)
    // ────────────────────────────────────────────────────────────────────────────
    if (config.showFollowupAnalysis && reportData.followupCategories.isNotEmpty) {
      final followupSheet = excel['Follow-ups'];
      followupSheet.appendRow([
        TextCellValue('Category'),
        TextCellValue('Client Name'),
        TextCellValue('Mobile'),
        TextCellValue('Assigned Representative'),
        TextCellValue('Follow-up Date'),
        TextCellValue('Next Action'),
        TextCellValue('Current Status'),
      ]);
      for (final cat in reportData.followupCategories) {
        for (final item in cat.items) {
          followupSheet.appendRow([
            TextCellValue(cat.categoryName),
            TextCellValue(item.leadName),
            TextCellValue(item.clientMobile ?? ''),
            TextCellValue(item.assignedUserName ?? 'Unassigned'),
            TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(item.followupDateTime)),
            TextCellValue(item.nextAction),
            TextCellValue(item.leadStatus),
          ]);
        }
      }
    }

    // Remove default Sheet1 if present
    try {
      excel.delete('Sheet1');
    } catch (_) {}

    return excel;
  }

  /// Export Genuine Excel (.xlsx) Workbook
  static Future<void> exportExcel({
    required ReportOverallData reportData,
    required ReportConfiguration config,
    String? reportTitle,
    String? subjectLabel,
    String? filenamePrefix,
  }) async {
    final excel = buildExcelDocument(
      reportData: reportData,
      config: config,
      reportTitle: reportTitle,
      subjectLabel: subjectLabel,
    );
    final bytes = excel.save();
    if (bytes != null) {
      final prefix = filenamePrefix ?? defaultFilenamePrefix;
      final filename = '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      await FileDownloader.download(bytes, filename);
    }
  }

  /// Print Dispatcher
  static Future<void> printReport({
    required ReportOverallData reportData,
    required ReportConfiguration config,
    String? reportTitle,
    String? subjectLabel,
    String? filenamePrefix,
  }) async {
    await exportPdf(
      reportData: reportData,
      config: config,
      reportTitle: reportTitle,
      subjectLabel: subjectLabel,
      filenamePrefix: filenamePrefix,
    );
  }
}
