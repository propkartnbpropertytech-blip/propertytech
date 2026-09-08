import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/file_downloader.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';

class ReportExportService {
  /// Export PDF Report
  static Future<void> exportPdf({
    required ReportOverallData reportData,
    required ReportConfiguration config,
  }) async {
    final pdf = pw.Document();
    final dateStr = config.dateRange.formattedRange;
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
                          k.showCount ? (reportData.kpiValues[k.type]?.formattedCount ?? '0') : '—',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          k.showPercentage ? (reportData.kpiValues[k.type]?.formattedPercentage ?? '0.0%') : '—',
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
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final filename = 'PropKart_Overall_Business_Insight_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    await FileDownloader.download(bytes, filename);
  }

  /// Export CSV
  static Future<void> exportCsv({
    required ReportOverallData reportData,
    required ReportConfiguration config,
  }) async {
    final buffer = StringBuffer();

    // Title & Context
    buffer.writeln('"PropKart CRM - Overall Business Insight Report"');
    buffer.writeln('"Period","${config.dateRange.formattedRange}"');
    buffer.writeln('"Generated At","${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}"');
    buffer.writeln();

    // 1. KPI Section
    buffer.writeln('"=== KEY PERFORMANCE INDICATORS ==="');
    buffer.writeln('"Metric","Count","Percentage","Denominator"');
    for (final k in config.sortedEnabledKpis) {
      final v = reportData.kpiValues[k.type];
      final countStr = k.showCount ? (v?.count.toString() ?? '0') : '';
      final pctStr = k.showPercentage ? (v?.formattedPercentage ?? '0.0%') : '';
      buffer.writeln('"${k.type.displayName}","$countStr","$pctStr","${v?.denominatorLabel ?? ''}"');
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
    }

    // 5. Raw Lead Rows for Detailed Auditing
    buffer.writeln('"=== FILTERED LEADS LIST ==="');
    buffer.writeln('"Lead Name","Mobile","Status","Created At","Assigned To","Telecaller / Creator","Budget Range","Category"');
    for (final l in reportData.filteredLeads) {
      final budgetStr = 'Rs ${l.minBudget.toInt()} - ${l.maxBudget.toInt()}';
      final createdStr = DateFormat('yyyy-MM-dd').format(l.createdAt);
      buffer.writeln('"${l.clientName}","${l.clientMobile}","${l.status}","$createdStr","${l.assigneeName ?? ''}","${l.creatorName ?? ''}","$budgetStr","${l.categoryName}"');
    }

    final bytes = utf8.encode(buffer.toString());
    final filename = 'PropKart_Business_Insight_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    await FileDownloader.download(bytes, filename);
  }

  /// Export Excel (Formatted Tabular CSV with Excel compatibility)
  static Future<void> exportExcel({
    required ReportOverallData reportData,
    required ReportConfiguration config,
  }) async {
    // Standard UTF-8 BOM CSV is natively opened by Microsoft Excel with preserved formatting
    final buffer = StringBuffer();
    // Add UTF-8 BOM
    buffer.write('\uFEFF');

    // Title & Context
    buffer.writeln('PropKart CRM - Overall Business Insight Dashboard');
    buffer.writeln('Reporting Period\t${config.dateRange.formattedRange}');
    buffer.writeln('Export Date\t${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln();

    buffer.writeln('METRICS SUMMARY');
    buffer.writeln('KPI Metric\tCount\tPercentage\tDenominator Basis');
    for (final k in config.sortedEnabledKpis) {
      final v = reportData.kpiValues[k.type];
      final c = k.showCount ? (v?.count.toString() ?? '0') : '';
      final p = k.showPercentage ? (v?.formattedPercentage ?? '0.0%') : '';
      buffer.writeln('${k.type.displayName}\t$c\t$p\t${v?.denominatorLabel ?? ''}');
    }
    buffer.writeln();

    buffer.writeln('PIPELINE STAGES');
    buffer.writeln('Stage Name\tLeads Count\tShare of Pipeline');
    for (final s in reportData.pipelineStages) {
      buffer.writeln('${s.displayName}\t${s.count}\t${s.percentage.toStringAsFixed(1)}%');
    }
    buffer.writeln();

    buffer.writeln('LEAD RECORDS');
    buffer.writeln('ID\tClient Name\tMobile\tStatus\tCreated Date\tAssigned Rep\tBudget Min\tBudget Max');
    for (final l in reportData.filteredLeads) {
      buffer.writeln('${l.id}\t${l.clientName}\t${l.clientMobile}\t${l.status}\t${DateFormat('yyyy-MM-dd').format(l.createdAt)}\t${l.assigneeName ?? ''}\t${l.minBudget}\t${l.maxBudget}');
    }

    final bytes = utf8.encode(buffer.toString());
    final filename = 'PropKart_Business_Insight_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xls';
    await FileDownloader.download(bytes, filename);
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
