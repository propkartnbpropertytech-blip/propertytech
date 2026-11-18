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
                          k.showCount
                              ? (reportData.campaignPipelineValues.containsKey(k.type)
                                  ? (reportData.campaignPipelineValues[k.type]?.formattedCount ?? '0')
                                  : (reportData.kpiValues[k.type]?.formattedCount ?? '0'))
                              : '-',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          k.showPercentage
                              ? (reportData.campaignPipelineValues.containsKey(k.type)
                                  ? (reportData.campaignPipelineValues[k.type]?.formattedPercentage ?? '0.0%')
                                  : (reportData.kpiValues[k.type]?.formattedPercentage ?? '0.0%'))
                              : '-',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          (reportData.campaignPipelineValues.containsKey(k.type)
                                  ? reportData.campaignPipelineValues[k.type]?.denominatorLabel
                                  : reportData.kpiValues[k.type]?.denominatorLabel) ??
                              '',
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
      final v = reportData.campaignPipelineValues.containsKey(k.type)
          ? reportData.campaignPipelineValues[k.type]
          : reportData.kpiValues[k.type];
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
    buffer.writeln('"Lead Name","Mobile","Email","Source","Type","Stage / Status","Assigned","Allocation Role","Assigned Salesperson","Call Disposition","Budget Range","Created At","Remarks"');
    for (final l in reportData.filteredLeads) {
      final isDirect = l.isDirectSalesAllocated;
      final stageStatus = isDirect ? 'Direct Allocate to Sales' : l.status;
      final String assignedName;
      final String assignedRole;
      final String salesRep;

      if (isDirect) {
        assignedName = l.assigneeName ?? 'Sales';
        assignedRole = 'Sales';
        salesRep = '-';
      } else if (l.creatorName != null && l.creatorName!.isNotEmpty) {
        if (l.creatorName == 'Propkart Admin') {
          assignedName = 'PropKart Admin';
          assignedRole = 'Admin';
        } else {
          assignedName = l.creatorName!;
          assignedRole = 'Telecaller';
        }
        salesRep = l.assigneeName ?? '-';
      } else if (l.assigneeName != null && l.assigneeName!.isNotEmpty) {
        assignedName = l.assigneeName!;
        assignedRole = 'Sales';
        salesRep = '-';
      } else {
        assignedName = 'Unassigned';
        assignedRole = 'Unassigned';
        salesRep = '-';
      }

      final budgetStr = 'Rs ${l.minBudget.toInt()} - ${l.maxBudget.toInt()}';
      final createdStr = DateFormat('yyyy-MM-dd HH:mm').format(l.createdAt);
      buffer.writeln('"${CsvSanitizer.sanitize(l.clientName)}","${CsvSanitizer.sanitize(l.clientMobile)}","${CsvSanitizer.sanitize(l.creatorEmail ?? '')}","${CsvSanitizer.sanitize(l.leadSource ?? 'Direct')}","${CsvSanitizer.sanitize(l.listingTypeName ?? 'Requirement')}","${CsvSanitizer.sanitize(stageStatus)}","${CsvSanitizer.sanitize(assignedName)}","${CsvSanitizer.sanitize(assignedRole)}","${CsvSanitizer.sanitize(salesRep)}","${CsvSanitizer.sanitize(l.callDisposition)}","${CsvSanitizer.sanitize(budgetStr)}","$createdStr","${CsvSanitizer.sanitize(l.remarks ?? l.notes ?? '')}"');
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

  // ────────────────────────────────────────────────────────────────────────────
  // EXCEL STYLING PALETTE & REUSABLE CELL STYLES
  // ────────────────────────────────────────────────────────────────────────────
  static final ExcelColor _excelNavy = ExcelColor.fromHexString('#1E293B');
  static final ExcelColor _excelSlate = ExcelColor.fromHexString('#334155');
  static final ExcelColor _excelTeal = ExcelColor.fromHexString('#0F766E');
  static final ExcelColor _excelBorderGrey = ExcelColor.fromHexString('#CBD5E1');
  static final ExcelColor _excelZebra = ExcelColor.fromHexString('#F8FAFC');
  static final ExcelColor _excelTotalBg = ExcelColor.fromHexString('#E2E8F0');
  static final ExcelColor _excelDarkText = ExcelColor.fromHexString('#0F172A');

  static CellStyle _excelTitleStyle({int fontSize = 13}) => CellStyle(
        bold: true,
        fontSize: fontSize,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: _excelNavy,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  static CellStyle _excelSubtitleStyle() => CellStyle(
        bold: false,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#E2E8F0'),
        backgroundColorHex: _excelSlate,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  static CellStyle _excelSectionHeaderStyle() => CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: _excelTeal,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelNavy),
        rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelNavy),
        topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelNavy),
        bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelNavy),
      );

  static CellStyle _excelTableHeaderStyle({
    HorizontalAlign horizontalAlign = HorizontalAlign.Center,
  }) =>
      CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: _excelNavy,
        horizontalAlign: horizontalAlign,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#0F172A')),
        rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#0F172A')),
        topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#0F172A')),
        bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#0F172A')),
      );

  static CellStyle _excelDataStyle({
    HorizontalAlign horizontalAlign = HorizontalAlign.Left,
    bool isZebra = false,
    bool isBold = false,
  }) =>
      CellStyle(
        bold: isBold,
        fontSize: 10,
        fontColorHex: _excelDarkText,
        backgroundColorHex: isZebra ? _excelZebra : ExcelColor.white,
        horizontalAlign: horizontalAlign,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
      );

  static CellStyle _excelTotalStyle({
    HorizontalAlign horizontalAlign = HorizontalAlign.Left,
  }) =>
      CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: _excelDarkText,
        backgroundColorHex: _excelTotalBg,
        horizontalAlign: horizontalAlign,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#94A3B8')),
        bottomBorder: Border(borderStyle: BorderStyle.Double, borderColorHex: ExcelColor.fromHexString('#64748B')),
      );

  static CellStyle _excelMetaLabelStyle() => CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: _excelSlate,
        backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
      );

  static CellStyle _excelMetaValueStyle({bool isBold = false}) => CellStyle(
        bold: isBold,
        fontSize: 10,
        fontColorHex: _excelDarkText,
        backgroundColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
        bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _excelBorderGrey),
      );

  static void _appendStyledRow({
    required Sheet sheet,
    required List<CellValue?> values,
    required List<HorizontalAlign> alignments,
    bool isHeader = false,
    bool isZebra = false,
    bool isTotal = false,
    double rowHeight = 22.0,
  }) {
    final rowIndex = sheet.maxRows;
    sheet.appendRow(values);
    sheet.setRowHeight(rowIndex, isHeader ? 28.0 : rowHeight);
    for (var c = 0; c < values.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
      final align = c < alignments.length ? alignments[c] : HorizontalAlign.Left;
      if (isHeader) {
        cell.cellStyle = _excelTableHeaderStyle(horizontalAlign: align);
      } else if (isTotal) {
        cell.cellStyle = _excelTotalStyle(horizontalAlign: align);
      } else {
        cell.cellStyle = _excelDataStyle(horizontalAlign: align, isZebra: isZebra);
      }
    }
  }

  static void _appendBannerRow({
    required Sheet sheet,
    required String text,
    required int colSpan,
    required CellStyle style,
    double rowHeight = 28.0,
  }) {
    final rowIndex = sheet.maxRows;
    final rowValues = <CellValue?>[TextCellValue(text)];
    for (var i = 1; i < colSpan; i++) {
      rowValues.add(TextCellValue(''));
    }
    sheet.appendRow(rowValues);
    sheet.setRowHeight(rowIndex, rowHeight);
    final start = CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex);
    final end = CellIndex.indexByColumnRow(columnIndex: colSpan - 1, rowIndex: rowIndex);
    sheet.cell(start).cellStyle = style;
    if (colSpan > 1) {
      sheet.merge(start, end, customValue: TextCellValue(text));
      try {
        sheet.setMergedCellStyle(start, style);
      } catch (_) {}
    }
  }

  static void _autoFitSheetColumns(
    Sheet sheet, {
    int skipRowsFromTop = 0,
    Map<int, double>? defaultWidths,
    double minWidth = 14.0,
    double maxWidth = 50.0,
  }) {
    final maxCols = sheet.maxColumns;
    final maxRows = sheet.maxRows;
    if (maxCols == 0 || maxRows == 0) return;

    for (var c = 0; c < maxCols; c++) {
      if (defaultWidths != null && defaultWidths.containsKey(c)) {
        sheet.setColumnWidth(c, defaultWidths[c]!);
        continue;
      }
      var maxLen = 0;
      for (var r = skipRowsFromTop; r < maxRows; r++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
        final val = cell.value?.toString() ?? '';
        if (val.startsWith('===') || val.length > 70) continue;
        if (val.length > maxLen) {
          maxLen = val.length;
        }
      }
      final optimalWidth = (maxLen + 4).toDouble().clamp(minWidth, maxWidth);
      sheet.setColumnWidth(c, optimalWidth);
    }
  }

  static String _kpiCategoryName(ReportKpiType type) {
    switch (type) {
      case ReportKpiType.totalLeads:
      case ReportKpiType.propertyListingLeads:
      case ReportKpiType.requirementLeads:
        return 'Acquisition Channel';
      case ReportKpiType.telecallers:
      case ReportKpiType.salesUsers:
        return 'Team Resources';
      case ReportKpiType.newOpenLeads:
      case ReportKpiType.leadsNotStarted:
        return 'Initial Intake';
      case ReportKpiType.leadsContacted:
      case ReportKpiType.cnrLeads:
      case ReportKpiType.callbackLeads:
      case ReportKpiType.campaignFollowupLeads:
      case ReportKpiType.leadsFollowups:
      case ReportKpiType.leadsReFollowups:
      case ReportKpiType.callAttempted:
      case ReportKpiType.callPickedUp:
      case ReportKpiType.callOpen:
      case ReportKpiType.leadsCallAttempted:
        return 'Outreach & Follow-up';
      case ReportKpiType.leadsAssignedToSales:
      case ReportKpiType.leadsAssignedToSalesPickedUp:
        return 'Sales Allocation';
      case ReportKpiType.leadsInterested:
      case ReportKpiType.leadQualificationRate:
        return 'Lead Qualification';
      case ReportKpiType.leadsSiteVisitScheduled:
      case ReportKpiType.leadsSiteVisitDone:
      case ReportKpiType.siteVisitsScheduled:
      case ReportKpiType.siteVisitsDone:
        return 'Site Operations';
      case ReportKpiType.leadsNegotiation:
        return 'Deal Negotiation';
      case ReportKpiType.convertedToWon:
        return 'Closed & Won';
      case ReportKpiType.notInterestedLeads:
      case ReportKpiType.leadsRejected:
      case ReportKpiType.lostUnsuccessful:
        return 'Disqualified / Lost';
    }
  }

  /// Build Genuine Multi-Sheet Excel (.xlsx) Workbook matching Master Template
  static Excel buildExcelDocument({
    required ReportOverallData reportData,
    required ReportConfiguration config,
    String? reportTitle,
    String? subjectLabel,
  }) {
    final excel = Excel.createExcel();
    final title = reportTitle ?? 'PROPKART REAL ESTATE - AUTHORITATIVE EXECUTIVE KPI & INVENTORY DASHBOARD';

    // ────────────────────────────────────────────────────────────────────────────
    // 1. SUMMARY SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final summarySheet = excel['Summary'];

    // Title & Subtitle Banners
    _appendBannerRow(
      sheet: summarySheet,
      text: title,
      colSpan: 6,
      style: _excelTitleStyle(fontSize: 13),
      rowHeight: 32.0,
    );
    _appendBannerRow(
      sheet: summarySheet,
      text: 'Live Production CRM Audit • Master Operational & Analytical Records',
      colSpan: 6,
      style: _excelSubtitleStyle(),
      rowHeight: 22.0,
    );

    // Spacer
    summarySheet.appendRow([]);
    summarySheet.setRowHeight(summarySheet.maxRows - 1, 8.0);

    // Metadata Block
    final metaRow1 = summarySheet.maxRows;
    summarySheet.appendRow([
      TextCellValue('Reporting Period:'),
      TextCellValue(config.dateRange.formattedRange),
      TextCellValue(''),
      TextCellValue('Export Generated:'),
      TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
      TextCellValue(''),
    ]);
    summarySheet.setRowHeight(metaRow1, 20.0);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: metaRow1)).cellStyle = _excelMetaLabelStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: metaRow1)).cellStyle = _excelMetaValueStyle(isBold: true);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: metaRow1)).cellStyle = _excelMetaValueStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: metaRow1)).cellStyle = _excelMetaLabelStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: metaRow1)).cellStyle = _excelMetaValueStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: metaRow1)).cellStyle = _excelMetaValueStyle();
    summarySheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: metaRow1),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: metaRow1),
    );
    summarySheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: metaRow1),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: metaRow1),
    );

    final metaRow2 = summarySheet.maxRows;
    summarySheet.appendRow([
      TextCellValue('Subject Context:'),
      TextCellValue(subjectLabel ?? 'Overall Business Insight / All Campaigns'),
      TextCellValue(''),
      TextCellValue('Active Filters:'),
      TextCellValue(config.filters.hasActiveFilters ? '${config.filters.activeFiltersCount} filters applied' : 'None (All Records)'),
      TextCellValue(''),
    ]);
    summarySheet.setRowHeight(metaRow2, 20.0);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: metaRow2)).cellStyle = _excelMetaLabelStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: metaRow2)).cellStyle = _excelMetaValueStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: metaRow2)).cellStyle = _excelMetaValueStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: metaRow2)).cellStyle = _excelMetaLabelStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: metaRow2)).cellStyle = _excelMetaValueStyle();
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: metaRow2)).cellStyle = _excelMetaValueStyle();
    summarySheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: metaRow2),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: metaRow2),
    );
    summarySheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: metaRow2),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: metaRow2),
    );

    // Spacer
    summarySheet.appendRow([]);
    summarySheet.setRowHeight(summarySheet.maxRows - 1, 12.0);

    // Section 1: Executive KPI Performance Highlights
    final totalLeads = reportData.kpiValues[ReportKpiType.totalLeads]?.count ?? 0;
    final contacted = reportData.kpiValues[ReportKpiType.leadsContacted]?.count ?? 0;
    final won = reportData.kpiValues[ReportKpiType.convertedToWon]?.count ?? 0;
    final convRate = reportData.kpiValues[ReportKpiType.convertedToWon]?.percentage ?? 0.0;
    final availableProps = reportData.availableProperties.where((p) => p.propertyStatusName.toLowerCase() == 'available').length;
    final allocatedSales = reportData.kpiValues[ReportKpiType.leadsAssignedToSales]?.count ??
        reportData.campaignPipelineValues[ReportKpiType.leadsAssignedToSales]?.count ??
        reportData.campaignPipelineValues[ReportKpiType.leadsAssignedToSalesPickedUp]?.count ??
        0;
    final siteVisits = reportData.kpiValues[ReportKpiType.siteVisitsDone]?.count ?? 0;

    _appendBannerRow(
      sheet: summarySheet,
      text: 'EXECUTIVE KEY PERFORMANCE HIGHLIGHTS',
      colSpan: 6,
      style: _excelSectionHeaderStyle(),
      rowHeight: 26.0,
    );
    _appendStyledRow(
      sheet: summarySheet,
      values: [
        TextCellValue('#'),
        TextCellValue('Executive KPI Metric'),
        TextCellValue('Category'),
        TextCellValue('Count / Value'),
        TextCellValue('Benchmark / Ratio'),
        TextCellValue('Operational Status'),
      ],
      alignments: const [
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Left,
        HorizontalAlign.Right,
        HorizontalAlign.Left,
        HorizontalAlign.Center,
      ],
      isHeader: true,
    );

    final execHighlights = [
      [
        IntCellValue(1),
        TextCellValue('Available Inventory'),
        TextCellValue('Property Inventory'),
        IntCellValue(availableProps > 0 ? availableProps : reportData.availableProperties.length),
        TextCellValue('Ready for Rent / Sale'),
        TextCellValue('Active Inventory'),
      ],
      [
        IntCellValue(2),
        TextCellValue('Total Leads'),
        TextCellValue('Lead Acquisition'),
        IntCellValue(totalLeads),
        TextCellValue('100.0% of Period Volume'),
        TextCellValue('Active Leads'),
      ],
      [
        IntCellValue(3),
        TextCellValue('Leads Contacted'),
        TextCellValue('Telecalling & Outreach'),
        IntCellValue(contacted),
        TextCellValue(totalLeads > 0 ? '${((contacted / totalLeads) * 100).toStringAsFixed(1)}% of Total Leads' : '0.0%'),
        TextCellValue(contacted > 0 ? 'Outreach Active' : 'Pending Outreach'),
      ],
      [
        IntCellValue(4),
        TextCellValue('Leads Allocated to Sales'),
        TextCellValue('Sales Pipeline'),
        IntCellValue(allocatedSales),
        TextCellValue(totalLeads > 0 ? '${((allocatedSales / totalLeads) * 100).toStringAsFixed(1)}% Allocated' : '0.0%'),
        TextCellValue(allocatedSales > 0 ? 'Assigned' : 'Unallocated'),
      ],
      [
        IntCellValue(5),
        TextCellValue('Site Visits Completed'),
        TextCellValue('Field Operations'),
        IntCellValue(siteVisits),
        TextCellValue(totalLeads > 0 ? '${((siteVisits / totalLeads) * 100).toStringAsFixed(1)}% of Total Leads' : '0.0%'),
        TextCellValue(siteVisits > 0 ? 'Visits Executed' : 'Pending Field Visits'),
      ],
      [
        IntCellValue(6),
        TextCellValue('Deals Won / Converted'),
        TextCellValue('Closures & Revenue'),
        IntCellValue(won),
        TextCellValue('${convRate.toStringAsFixed(1)}% Conversion Rate'),
        TextCellValue(won > 0 ? 'Closed Won' : 'Pipeline Active'),
      ],
      [
        IntCellValue(7),
        TextCellValue('Overall Conversion Rate'),
        TextCellValue('Performance Efficiency'),
        TextCellValue('${convRate.toStringAsFixed(1)}%'),
        TextCellValue('Deals Won / Assigned Leads'),
        TextCellValue('Benchmark KPI'),
      ],
    ];

    for (var i = 0; i < execHighlights.length; i++) {
      _appendStyledRow(
        sheet: summarySheet,
        values: execHighlights[i],
        alignments: const [
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
        ],
        isZebra: i.isOdd,
      );
    }

    // Spacer
    summarySheet.appendRow([]);
    summarySheet.setRowHeight(summarySheet.maxRows - 1, 12.0);

    // Section 2: Campaign Leads Performance Breakdown
    _appendBannerRow(
      sheet: summarySheet,
      text: 'CAMPAIGN LEADS PERFORMANCE BREAKDOWN',
      colSpan: 6,
      style: _excelSectionHeaderStyle(),
      rowHeight: 26.0,
    );
    _appendStyledRow(
      sheet: summarySheet,
      values: [
        TextCellValue('#'),
        TextCellValue('Campaign Metric'),
        TextCellValue('Metric Category'),
        TextCellValue('Count'),
        TextCellValue('Ratio / Percentage'),
        TextCellValue('Denominator / Basis'),
      ],
      alignments: const [
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Left,
        HorizontalAlign.Right,
        HorizontalAlign.Right,
        HorizontalAlign.Left,
      ],
      isHeader: true,
    );

    for (var i = 0; i < config.sortedEnabledKpis.length; i++) {
      final k = config.sortedEnabledKpis[i];
      final v = reportData.campaignPipelineValues.containsKey(k.type)
          ? reportData.campaignPipelineValues[k.type]
          : reportData.kpiValues[k.type];
      final countVal = k.showCount ? (v?.count ?? 0) : 0;
      final pctVal = k.showPercentage ? (v?.formattedPercentage ?? '0.0%') : '—';
      final basisVal = v?.denominatorLabel ?? '';
      _appendStyledRow(
        sheet: summarySheet,
        values: [
          IntCellValue(i + 1),
          TextCellValue(k.type.displayName),
          TextCellValue(_kpiCategoryName(k.type)),
          IntCellValue(countVal),
          TextCellValue(pctVal),
          TextCellValue(basisVal),
        ],
        alignments: const [
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Left,
        ],
        isZebra: i.isOdd,
      );
    }

    // Apply auto-fit & explicit widths to Summary Sheet
    _autoFitSheetColumns(
      summarySheet,
      skipRowsFromTop: 6,
      defaultWidths: const {
        0: 10.0, // #
        1: 34.0, // Executive KPI Metric / Campaign Metric
        2: 24.0, // Category
        3: 18.0, // Count / Value
        4: 26.0, // Benchmark / Ratio / Share
        5: 28.0, // Status / Basis
      },
    );

    // Also populate Executive Dashboard sheet with identical clean structure
    final dashboardSheet = excel['Executive Dashboard'];
    for (var r = 0; r < summarySheet.maxRows; r++) {
      final rowCells = <CellValue?>[];
      for (var c = 0; c < summarySheet.maxColumns; c++) {
        rowCells.add(summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).value);
      }
      dashboardSheet.appendRow(rowCells);
      dashboardSheet.setRowHeight(r, r == 0 ? 32.0 : 22.0);
      for (var c = 0; c < summarySheet.maxColumns; c++) {
        dashboardSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle =
            summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle;
      }
    }
    dashboardSheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));
    dashboardSheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1), CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1));
    dashboardSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: metaRow1), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: metaRow1));
    dashboardSheet.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: metaRow1), CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: metaRow1));
    dashboardSheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: metaRow2), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: metaRow2));
    dashboardSheet.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: metaRow2), CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: metaRow2));
    _autoFitSheetColumns(
      dashboardSheet,
      skipRowsFromTop: 6,
      defaultWidths: const {
        0: 10.0,
        1: 34.0,
        2: 24.0,
        3: 18.0,
        4: 26.0,
        5: 28.0,
      },
    );

    // ────────────────────────────────────────────────────────────────────────────
    // 2. KPIS SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final kpiSheet = excel['KPIs'];
    _appendStyledRow(
      sheet: kpiSheet,
      values: [
        TextCellValue('Order'),
        TextCellValue('KPI Metric'),
        TextCellValue('Count'),
        TextCellValue('Percentage'),
        TextCellValue('Denominator / Basis'),
      ],
      alignments: const [
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Right,
        HorizontalAlign.Right,
        HorizontalAlign.Left,
      ],
      isHeader: true,
    );
    for (var i = 0; i < config.sortedEnabledKpis.length; i++) {
      final k = config.sortedEnabledKpis[i];
      final v = reportData.campaignPipelineValues.containsKey(k.type)
          ? reportData.campaignPipelineValues[k.type]
          : reportData.kpiValues[k.type];
      _appendStyledRow(
        sheet: kpiSheet,
        values: [
          IntCellValue(i + 1),
          TextCellValue(k.type.displayName),
          k.showCount ? IntCellValue(v?.count ?? 0) : TextCellValue('—'),
          k.showPercentage ? TextCellValue(v?.formattedPercentage ?? '0.0%') : TextCellValue('—'),
          TextCellValue(v?.denominatorLabel ?? ''),
        ],
        alignments: const [
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Left,
        ],
        isZebra: i.isOdd,
      );
    }
    _autoFitSheetColumns(
      kpiSheet,
      defaultWidths: const {
        0: 10.0,
        1: 34.0,
        2: 16.0,
        3: 18.0,
        4: 32.0,
      },
    );

    // ────────────────────────────────────────────────────────────────────────────
    // 3. LEAD STATUS SHEET (conditional)
    // ────────────────────────────────────────────────────────────────────────────
    if (config.showLeadStatusPipeline) {
      final leadStatusSheet = excel['Lead Status'];
      _appendBannerRow(
        sheet: leadStatusSheet,
        text: 'PIPELINE STATUS BREAKDOWN',
        colSpan: 3,
        style: _excelSectionHeaderStyle(),
        rowHeight: 26.0,
      );
      _appendStyledRow(
        sheet: leadStatusSheet,
        values: [
          TextCellValue('Pipeline Stage'),
          TextCellValue('Leads Count'),
          TextCellValue('Share %'),
        ],
        alignments: const [
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
        ],
        isHeader: true,
      );
      for (var i = 0; i < reportData.pipelineStages.length; i++) {
        final s = reportData.pipelineStages[i];
        _appendStyledRow(
          sheet: leadStatusSheet,
          values: [
            TextCellValue(s.displayName),
            IntCellValue(s.count),
            DoubleCellValue(double.parse(s.percentage.toStringAsFixed(2))),
          ],
          alignments: const [
            HorizontalAlign.Left,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
          ],
          isZebra: i.isOdd,
        );
      }
      _autoFitSheetColumns(
        leadStatusSheet,
        skipRowsFromTop: 1,
        defaultWidths: const {
          0: 30.0,
          1: 18.0,
          2: 18.0,
        },
      );
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 4. CONVERSION FUNNEL SHEET (conditional)
    // ────────────────────────────────────────────────────────────────────────────
    if (config.showConversionFunnel) {
      final funnelSheet = excel['Conversion Funnel'];
      _appendBannerRow(
        sheet: funnelSheet,
        text: 'CONVERSION FUNNEL',
        colSpan: 3,
        style: _excelSectionHeaderStyle(),
        rowHeight: 26.0,
      );
      _appendStyledRow(
        sheet: funnelSheet,
        values: [
          TextCellValue('Funnel Stage'),
          TextCellValue('Leads Count'),
          TextCellValue('Step Conversion %'),
        ],
        alignments: const [
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
        ],
        isHeader: true,
      );
      for (var i = 0; i < reportData.funnelStages.length; i++) {
        final s = reportData.funnelStages[i];
        _appendStyledRow(
          sheet: funnelSheet,
          values: [
            TextCellValue(s.stageName),
            IntCellValue(s.count),
            DoubleCellValue(double.parse(s.stageConversionRate.toStringAsFixed(2))),
          ],
          alignments: const [
            HorizontalAlign.Left,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
          ],
          isZebra: i.isOdd,
        );
      }
      _autoFitSheetColumns(
        funnelSheet,
        skipRowsFromTop: 1,
        defaultWidths: const {
          0: 30.0,
          1: 18.0,
          2: 24.0,
        },
      );
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 5. FOLLOW-UPS SHEET (conditional)
    // ────────────────────────────────────────────────────────────────────────────
    if (config.showFollowupAnalysis) {
      final followupSheet = excel['Follow-ups'];
      _appendStyledRow(
        sheet: followupSheet,
        values: [
          TextCellValue('Category'),
          TextCellValue('Client Name'),
          TextCellValue('Mobile'),
          TextCellValue('Assigned Representative'),
          TextCellValue('Follow-up Date'),
          TextCellValue('Next Action'),
          TextCellValue('Current Status'),
        ],
        alignments: const [
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
        ],
        isHeader: true,
      );
      var itemIndex = 0;
      for (final cat in reportData.followupCategories) {
        for (final item in cat.items) {
          _appendStyledRow(
            sheet: followupSheet,
            values: [
              TextCellValue(cat.categoryName),
              TextCellValue(item.leadName),
              TextCellValue(item.clientMobile ?? ''),
              TextCellValue(item.assignedUserName ?? 'Unassigned'),
              TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(item.followupDateTime)),
              TextCellValue(item.nextAction),
              TextCellValue(item.leadStatus),
            ],
            alignments: const [
              HorizontalAlign.Left,
              HorizontalAlign.Left,
              HorizontalAlign.Center,
              HorizontalAlign.Left,
              HorizontalAlign.Center,
              HorizontalAlign.Left,
              HorizontalAlign.Center,
            ],
            isZebra: itemIndex.isOdd,
          );
          itemIndex++;
        }
      }
      _autoFitSheetColumns(
        followupSheet,
        defaultWidths: const {
          0: 22.0,
          1: 24.0,
          2: 18.0,
          3: 26.0,
          4: 22.0,
          5: 28.0,
          6: 20.0,
        },
      );
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 6. TEAM RANKING SHEET (conditional)
    // ────────────────────────────────────────────────────────────────────────────
    if (config.showTeamRanking) {
      final teamSheet = excel['Team Ranking'];
      _appendBannerRow(
        sheet: teamSheet,
        text: 'SALES TEAM PERFORMANCE',
        colSpan: 8,
        style: _excelSectionHeaderStyle(),
        rowHeight: 26.0,
      );
      _appendStyledRow(
        sheet: teamSheet,
        values: [
          TextCellValue('Rank'),
          TextCellValue('Sales Executive'),
          TextCellValue('Leads Assigned'),
          TextCellValue('Contacted'),
          TextCellValue('Qualified'),
          TextCellValue('Site Visits'),
          TextCellValue('Deals Won'),
          TextCellValue('Conversion Rate %'),
        ],
        alignments: const [
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
        ],
        isHeader: true,
      );
      for (var i = 0; i < reportData.salesRankings.length; i++) {
        final s = reportData.salesRankings[i];
        _appendStyledRow(
          sheet: teamSheet,
          values: [
            IntCellValue(s.rank),
            TextCellValue(s.userName),
            IntCellValue(s.leadsCount),
            IntCellValue(s.contactedCount),
            IntCellValue(s.qualifiedCount),
            IntCellValue(s.siteVisitsCount),
            IntCellValue(s.wonCount),
            DoubleCellValue(double.parse(s.conversionRate.toStringAsFixed(2))),
          ],
          alignments: const [
            HorizontalAlign.Center,
            HorizontalAlign.Left,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
          ],
          isZebra: i.isOdd,
        );
      }

      final spRank = teamSheet.maxRows;
      teamSheet.appendRow([]);
      teamSheet.setRowHeight(spRank, 12.0);

      _appendBannerRow(
        sheet: teamSheet,
        text: 'TELECALLER TEAM PERFORMANCE',
        colSpan: 8,
        style: _excelSectionHeaderStyle(),
        rowHeight: 26.0,
      );
      _appendStyledRow(
        sheet: teamSheet,
        values: [
          TextCellValue('Rank'),
          TextCellValue('Telecaller'),
          TextCellValue('Leads Handled'),
          TextCellValue('Contacted'),
          TextCellValue('Qualified'),
          TextCellValue('Site Visits'),
          TextCellValue('Deals Won'),
          TextCellValue('Conversion Rate %'),
        ],
        alignments: const [
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
        ],
        isHeader: true,
      );
      for (var i = 0; i < reportData.telecallerRankings.length; i++) {
        final t = reportData.telecallerRankings[i];
        _appendStyledRow(
          sheet: teamSheet,
          values: [
            IntCellValue(t.rank),
            TextCellValue(t.userName),
            IntCellValue(t.leadsCount),
            IntCellValue(t.contactedCount),
            IntCellValue(t.qualifiedCount),
            IntCellValue(t.siteVisitsCount),
            IntCellValue(t.wonCount),
            DoubleCellValue(double.parse(t.conversionRate.toStringAsFixed(2))),
          ],
          alignments: const [
            HorizontalAlign.Center,
            HorizontalAlign.Left,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
          ],
          isZebra: i.isOdd,
        );
      }
      _autoFitSheetColumns(
        teamSheet,
        skipRowsFromTop: 1,
        defaultWidths: const {
          0: 10.0,
          1: 26.0,
          2: 18.0,
          3: 16.0,
          4: 16.0,
          5: 16.0,
          6: 16.0,
          7: 20.0,
        },
      );
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 7. LEAD SOURCES SHEET (conditional)
    // ────────────────────────────────────────────────────────────────────────────
    if (config.showLeadSourceAnalysis) {
      final sourcesSheet = excel['Lead Sources'];
      _appendBannerRow(
        sheet: sourcesSheet,
        text: 'LEAD SOURCE DISTRIBUTION',
        colSpan: 3,
        style: _excelSectionHeaderStyle(),
        rowHeight: 26.0,
      );
      _appendStyledRow(
        sheet: sourcesSheet,
        values: [
          TextCellValue('Lead Source'),
          TextCellValue('Count'),
          TextCellValue('Share %'),
        ],
        alignments: const [
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
        ],
        isHeader: true,
      );
      for (var i = 0; i < reportData.leadSources.length; i++) {
        final src = reportData.leadSources[i];
        _appendStyledRow(
          sheet: sourcesSheet,
          values: [
            TextCellValue(src.source),
            IntCellValue(src.count),
            DoubleCellValue(double.parse(src.percentage.toStringAsFixed(2))),
          ],
          alignments: const [
            HorizontalAlign.Left,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
          ],
          isZebra: i.isOdd,
        );
      }
      _autoFitSheetColumns(
        sourcesSheet,
        skipRowsFromTop: 1,
        defaultWidths: const {
          0: 28.0,
          1: 16.0,
          2: 16.0,
        },
      );
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 8. GROWTH & COMPARISON SHEET (conditional)
    // ────────────────────────────────────────────────────────────────────────────
    if (config.showGrowthComparison) {
      final growthSheet = excel['Growth & Comparison'];
      _appendBannerRow(
        sheet: growthSheet,
        text: 'GROWTH & COMPARISON ANALYSIS',
        colSpan: 5,
        style: _excelSectionHeaderStyle(),
        rowHeight: 26.0,
      );
      _appendStyledRow(
        sheet: growthSheet,
        values: [
          TextCellValue('Metric'),
          TextCellValue('Current Count'),
          TextCellValue('Previous Count'),
          TextCellValue('Difference'),
          TextCellValue('Growth Rate %'),
        ],
        alignments: const [
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
        ],
        isHeader: true,
      );
      for (var i = 0; i < reportData.growthComparisonItems.length; i++) {
        final item = reportData.growthComparisonItems[i];
        _appendStyledRow(
          sheet: growthSheet,
          values: [
            TextCellValue(item.metricName),
            IntCellValue(item.currentCount.toInt()),
            IntCellValue(item.previousCount.toInt()),
            IntCellValue(item.difference.toInt()),
            TextCellValue('${item.growthPercentage >= 0 ? "+" : ""}${item.growthPercentage.toStringAsFixed(1)}%'),
          ],
          alignments: const [
            HorizontalAlign.Left,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
            HorizontalAlign.Right,
          ],
          isZebra: i.isOdd,
        );
      }
      _autoFitSheetColumns(
        growthSheet,
        skipRowsFromTop: 1,
        defaultWidths: const {
          0: 28.0,
          1: 18.0,
          2: 18.0,
          3: 16.0,
          4: 18.0,
        },
      );
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 9. LEAD DETAILS SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final leadsList = reportData.filteredLeads;
    final detailsSheet = excel['Lead Details'];
    _appendStyledRow(
      sheet: detailsSheet,
      values: [
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
        TextCellValue('Stage / Status'),
        TextCellValue('Assigned'),
        TextCellValue('Allocation Role'),
        TextCellValue('Assigned Salesperson'),
        TextCellValue('Call Disposition'),
        TextCellValue('Remarks / Notes'),
      ],
      alignments: const [
        HorizontalAlign.Center,
        HorizontalAlign.Center,
        HorizontalAlign.Center,
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Left,
        HorizontalAlign.Left,
        HorizontalAlign.Right,
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Center,
        HorizontalAlign.Left,
      ],
      isHeader: true,
    );

    for (var i = 0; i < leadsList.length; i++) {
      final l = leadsList[i];
      final budgetStr = 'Rs ${l.minBudget.toInt()} - ${l.maxBudget.toInt()}';
      final localityStr = l.areaNames.isNotEmpty ? l.areaNames.join(', ') : 'N/A';
      final typeConfigStr = '${l.configurationName ?? "" } ${l.propertyTypeName}'.trim();
      final isDirect = l.isDirectSalesAllocated;
      final stageStatus = isDirect ? 'Direct Allocate to Sales' : l.status;
      final String assignedName;
      final String assignedRole;
      final String salesRep;

      if (isDirect) {
        assignedName = l.assigneeName ?? 'Sales';
        assignedRole = 'Sales';
        salesRep = '-';
      } else if (l.creatorName != null && l.creatorName!.isNotEmpty) {
        if (l.creatorName == 'Propkart Admin') {
          assignedName = 'PropKart Admin';
          assignedRole = 'Admin';
        } else {
          assignedName = l.creatorName!;
          assignedRole = 'Telecaller';
        }
        salesRep = l.assigneeName ?? '-';
      } else if (l.assigneeName != null && l.assigneeName!.isNotEmpty) {
        assignedName = l.assigneeName!;
        assignedRole = 'Sales';
        salesRep = '-';
      } else {
        assignedName = 'Unassigned';
        assignedRole = 'Unassigned';
        salesRep = '-';
      }

      _appendStyledRow(
        sheet: detailsSheet,
        values: [
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
          TextCellValue(stageStatus),
          TextCellValue(assignedName),
          TextCellValue(assignedRole),
          TextCellValue(salesRep),
          TextCellValue(l.callDisposition),
          TextCellValue(l.remarks ?? l.notes ?? ''),
        ],
        alignments: const [
          HorizontalAlign.Center,
          HorizontalAlign.Center,
          HorizontalAlign.Center,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Right,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
        ],
        isZebra: i.isOdd,
      );
    }

    _autoFitSheetColumns(
      detailsSheet,
      defaultWidths: const {
        0: 10.0,
        1: 20.0,
        2: 16.0,
        3: 18.0,
        4: 24.0,
        5: 18.0,
        6: 24.0,
        7: 24.0,
        8: 26.0,
        9: 24.0,
        10: 26.0,
        11: 22.0,
        12: 18.0,
        13: 22.0,
        14: 20.0,
        15: 36.0,
      },
    );

    // Also populate All Leads with styles
    final allLeadsSheet = excel['All Leads'];
    for (var r = 0; r < detailsSheet.maxRows; r++) {
      final rowCells = <CellValue?>[];
      for (var c = 0; c < detailsSheet.maxColumns; c++) {
        rowCells.add(detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).value);
      }
      allLeadsSheet.appendRow(rowCells);
      allLeadsSheet.setRowHeight(r, r == 0 ? 28.0 : 22.0);
      for (var c = 0; c < detailsSheet.maxColumns; c++) {
        allLeadsSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle =
            detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle;
      }
    }
    _autoFitSheetColumns(
      allLeadsSheet,
      defaultWidths: const {
        0: 10.0,
        1: 20.0,
        2: 16.0,
        3: 18.0,
        4: 24.0,
        5: 18.0,
        6: 24.0,
        7: 24.0,
        8: 26.0,
        9: 24.0,
        10: 26.0,
        11: 22.0,
        12: 18.0,
        13: 22.0,
        14: 20.0,
        15: 36.0,
      },
    );

    // ────────────────────────────────────────────────────────────────────────────
    // 10. PROPERTIES SHEET
    // ────────────────────────────────────────────────────────────────────────────
    final propsSheet = excel['Properties'];
    _appendStyledRow(
      sheet: propsSheet,
      values: [
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
      ],
      alignments: const [
        HorizontalAlign.Center,
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Center,
        HorizontalAlign.Center,
        HorizontalAlign.Center,
        HorizontalAlign.Left,
        HorizontalAlign.Left,
        HorizontalAlign.Left,
        HorizontalAlign.Center,
        HorizontalAlign.Right,
        HorizontalAlign.Right,
        HorizontalAlign.Right,
        HorizontalAlign.Right,
        HorizontalAlign.Left,
        HorizontalAlign.Left,
        HorizontalAlign.Left,
        HorizontalAlign.Center,
        HorizontalAlign.Center,
      ],
      isHeader: true,
    );

    for (var i = 0; i < reportData.availableProperties.length; i++) {
      final p = reportData.availableProperties[i];
      _appendStyledRow(
        sheet: propsSheet,
        values: [
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
        ],
        alignments: const [
          HorizontalAlign.Center,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
          HorizontalAlign.Center,
          HorizontalAlign.Center,
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Right,
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Left,
          HorizontalAlign.Center,
          HorizontalAlign.Center,
        ],
        isZebra: i.isOdd,
      );
    }

    _autoFitSheetColumns(
      propsSheet,
      defaultWidths: const {
        0: 10.0,
        1: 18.0,
        2: 34.0,
        3: 18.0,
        4: 24.0,
        5: 18.0,
        6: 20.0,
        7: 18.0,
        8: 18.0,
        9: 18.0,
        10: 20.0,
        11: 18.0,
        12: 24.0,
        13: 20.0,
        14: 24.0,
        15: 18.0,
        16: 22.0,
        17: 18.0,
        18: 16.0,
      },
    );

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
