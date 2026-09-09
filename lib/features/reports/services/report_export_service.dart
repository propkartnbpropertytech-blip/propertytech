import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../../../core/utils/file_downloader.dart';
import '../models/report_kpi_type.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';

class ReportExportService {
  /// Build PDF Document
  static pw.Document buildPdfDocument({
    required ReportOverallData reportData,
    required ReportConfiguration config,
  }) {
    final pdf = pw.Document();
    final dateStr = config.dateRange.formattedRange.replaceAll('–', '-').replaceAll('—', '-');
    final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

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
                      'PropKart CRM - Overall Business Insight',
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
  }) async {
    final pdf = buildPdfDocument(reportData: reportData, config: config);
    final bytes = await pdf.save();
    final filename = 'PropKart_Overall_Business_Insight_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    await FileDownloader.download(bytes, filename);
  }

  /// Generate CSV string content
  static String generateCsvContent({
    required ReportOverallData reportData,
    required ReportConfiguration config,
  }) {
    final buffer = StringBuffer();

    // Title & Context
    buffer.writeln('"PropKart CRM - Overall Business Insight Report"');
    buffer.writeln('"Period","${config.dateRange.formattedRange}"');
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
      buffer.writeln('"${l.clientName}","${l.clientMobile}","${l.status}","$createdStr","${l.assigneeName ?? ''}","${l.creatorName ?? ''}","$budgetStr","${l.categoryName}"');
    }
    return buffer.toString();
  }

  /// Export CSV
  static Future<void> exportCsv({
    required ReportOverallData reportData,
    required ReportConfiguration config,
  }) async {
    final content = generateCsvContent(reportData: reportData, config: config);
    final bytes = utf8.encode(content);
    final filename = 'PropKart_Business_Insight_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    await FileDownloader.download(bytes, filename);
  }

  /// Build Genuine Excel (.xlsx) Workbook
  static Excel buildExcelDocument({
    required ReportOverallData reportData,
    required ReportConfiguration config,
  }) {
    final excel = Excel.createExcel();

    // 1. Summary Sheet
    final summarySheet = excel['Summary'];
    summarySheet.appendRow([TextCellValue('PropKart CRM - Overall Business Insight Report')]);
    summarySheet.appendRow([TextCellValue('Reporting Period:'), TextCellValue(config.dateRange.formattedRange)]);
    summarySheet.appendRow([TextCellValue('Export Generated:'), TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()))]);
    if (config.filters.hasActiveFilters) {
      summarySheet.appendRow([TextCellValue('Active Filters:'), TextCellValue('${config.filters.activeFiltersCount} filters applied')]);
    }
    summarySheet.appendRow([]);
    final totalLeads = reportData.kpiValues[ReportKpiType.totalLeads]?.count ?? 0;
    final contacted = reportData.kpiValues[ReportKpiType.leadsContacted]?.count ?? 0;
    final won = reportData.kpiValues[ReportKpiType.convertedToWon]?.count ?? 0;
    final convRate = reportData.kpiValues[ReportKpiType.convertedToWon]?.percentage ?? 0.0;

    summarySheet.appendRow([
      TextCellValue('Total Leads'),
      IntCellValue(totalLeads),
      TextCellValue('Contacted'),
      IntCellValue(contacted),
      TextCellValue('Won'),
      IntCellValue(won),
      TextCellValue('Conversion %'),
      TextCellValue('${convRate.toStringAsFixed(1)}%'),
    ]);

    // 2. KPIs Sheet (Filtered and Ordered by live configuration)
    final kpiSheet = excel['KPIs'];
    kpiSheet.appendRow([
      TextCellValue('Order'),
      TextCellValue('KPI Metric'),
      TextCellValue('Count'),
      TextCellValue('Percentage'),
      TextCellValue('Denominator / Basis'),
    ]);
    for (var i = 0; i < config.sortedEnabledKpis.length; i++) {
      final k = config.sortedEnabledKpis[i];
      final v = reportData.kpiValues[k.type];
      kpiSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(k.type.displayName),
        k.showCount ? IntCellValue(v?.count ?? 0) : TextCellValue('—'),
        k.showPercentage ? TextCellValue(v?.formattedPercentage ?? '0.0%') : TextCellValue('—'),
        TextCellValue(v?.denominatorLabel ?? ''),
      ]);
    }

    // 3. Lead Status Sheet (if enabled)
    if (config.showLeadStatusPipeline && reportData.pipelineStages.isNotEmpty) {
      final statusSheet = excel['Lead Status'];
      statusSheet.appendRow([
        TextCellValue('Stage Name'),
        TextCellValue('Leads Count'),
        TextCellValue('Share of Pipeline %'),
      ]);
      for (final s in reportData.pipelineStages) {
        statusSheet.appendRow([
          TextCellValue(s.displayName),
          IntCellValue(s.count),
          DoubleCellValue(double.parse(s.percentage.toStringAsFixed(2))),
        ]);
      }
    }

    // 4. Conversion Funnel Sheet (if enabled)
    if (config.showConversionFunnel && reportData.funnelStages.isNotEmpty) {
      final funnelSheet = excel['Conversion Funnel'];
      funnelSheet.appendRow([
        TextCellValue('Funnel Stage'),
        TextCellValue('Count'),
        TextCellValue('Step-to-Step Conversion %'),
        TextCellValue('Overall Conversion %'),
      ]);
      for (final f in reportData.funnelStages) {
        funnelSheet.appendRow([
          TextCellValue(f.stageName),
          IntCellValue(f.count),
          DoubleCellValue(double.parse(f.stageConversionRate.toStringAsFixed(2))),
          DoubleCellValue(double.parse(f.totalConversionRate.toStringAsFixed(2))),
        ]);
      }
    }

    // 5. Follow-ups Sheet (if enabled)
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

    // 6. Team Ranking Sheet (if enabled)
    if (config.showTeamRanking && (reportData.salesRankings.isNotEmpty || reportData.telecallerRankings.isNotEmpty)) {
      final teamSheet = excel['Team Ranking'];
      teamSheet.appendRow([TextCellValue('=== SALES TEAM RANKING ===')]);
      teamSheet.appendRow([
        TextCellValue('Rank'),
        TextCellValue('Representative'),
        TextCellValue('Leads Assigned'),
        TextCellValue('Contacted'),
        TextCellValue('Qualified'),
        TextCellValue('Site Visits'),
        TextCellValue('Won Deals'),
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
      teamSheet.appendRow([TextCellValue('=== TELECALLER TEAM RANKING ===')]);
      teamSheet.appendRow([
        TextCellValue('Rank'),
        TextCellValue('Telecaller'),
        TextCellValue('Leads Assigned'),
        TextCellValue('Contacted'),
        TextCellValue('Qualified'),
        TextCellValue('Site Visits'),
        TextCellValue('Won Deals'),
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
    }

    // 7. Lead Sources Sheet (if enabled)
    if (config.showLeadSourceAnalysis && reportData.leadSources.isNotEmpty) {
      final sourceSheet = excel['Lead Sources'];
      sourceSheet.appendRow([
        TextCellValue('Lead Source'),
        TextCellValue('Count'),
        TextCellValue('Share %'),
      ]);
      for (final src in reportData.leadSources) {
        sourceSheet.appendRow([
          TextCellValue(src.source),
          IntCellValue(src.count),
          DoubleCellValue(double.parse(src.percentage.toStringAsFixed(2))),
        ]);
      }
    }

    // 8. Growth & Comparison Sheet (if enabled)
    if (config.showGrowthComparison && reportData.growthComparisonItems.isNotEmpty) {
      final growthSheet = excel['Growth & Comparison'];
      growthSheet.appendRow([TextCellValue('Comparison Mode: ${config.comparisonPeriod.displayName}')]);
      growthSheet.appendRow([
        TextCellValue('Metric'),
        TextCellValue('Current Period'),
        TextCellValue('Previous Period'),
        TextCellValue('Difference'),
        TextCellValue('Growth %'),
      ]);
      for (final g in reportData.growthComparisonItems) {
        growthSheet.appendRow([
          TextCellValue(g.metricName),
          IntCellValue(g.currentCount.toInt()),
          IntCellValue(g.previousCount.toInt()),
          IntCellValue(g.difference.toInt()),
          DoubleCellValue(double.parse(g.growthPercentage.toStringAsFixed(2))),
        ]);
      }
    }

    // 9. Lead Details Sheet
    if (reportData.filteredLeads.isNotEmpty) {
      final detailsSheet = excel['Lead Details'];
      detailsSheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Client Name'),
        TextCellValue('Mobile'),
        TextCellValue('Status'),
        TextCellValue('Category'),
        TextCellValue('Min Budget'),
        TextCellValue('Max Budget'),
        TextCellValue('Assigned Rep'),
        TextCellValue('Created By'),
        TextCellValue('Created Date'),
      ]);
      for (final l in reportData.filteredLeads) {
        detailsSheet.appendRow([
          TextCellValue(l.id),
          TextCellValue(l.clientName),
          TextCellValue(l.clientMobile),
          TextCellValue(l.status),
          TextCellValue(l.categoryName),
          DoubleCellValue(l.minBudget),
          DoubleCellValue(l.maxBudget),
          TextCellValue(l.assigneeName ?? ''),
          TextCellValue(l.creatorName ?? ''),
          TextCellValue(DateFormat('yyyy-MM-dd').format(l.createdAt)),
        ]);
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
  }) async {
    final excel = buildExcelDocument(reportData: reportData, config: config);
    final bytes = excel.save();
    if (bytes != null) {
      final filename = 'PropKart_Overall_Business_Insight_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      await FileDownloader.download(bytes, filename);
    }
  }

  /// Print Dispatcher
  static Future<void> printReport({
    required ReportOverallData reportData,
    required ReportConfiguration config,
  }) async {
    // Generate high-resolution PDF document and invoke browser or platform printing
    await exportPdf(reportData: reportData, config: config);
  }
}
