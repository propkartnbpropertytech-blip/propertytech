import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/budget_formatter.dart';
import '../../properties/models/property_model.dart';

/// Builds one property-details PDF containing all selected matching properties.
class PropertySharePdf {
  static String displayTitle(PropertyModel p) {
    final bhk = p.configurationName ?? '${p.bedrooms} BHK';
    final price = 'Rs ${BudgetFormatter.format(p.price)}';
    return '$bhk in ${p.areaName} - $price (${p.propertyCode})';
  }

  static String fileName(PropertyModel p) {
    final bhk = p.configurationName ?? '${p.bedrooms} BHK';
    final price = 'Rs ${BudgetFormatter.format(p.price)}';
    final raw = '$bhk in ${p.areaName} - $price (${p.propertyCode})';
    final safe = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '$safe.pdf';
  }

  static Future<Uint8List> build(List<PropertyModel> properties) async {
    final doc = pw.Document();
    final dio = Dio();

    // Fetch images in parallel for all properties to speed up execution
    final Map<String, List<Uint8List>> propertyImagesMap = {};
    for (final p in properties) {
      final List<Uint8List> imageBytesList = [];
      if (p.images.isNotEmpty) {
        // Limit to 6 images per property to prevent giant PDF file sizes
        final urls = p.images.take(6).toList();
        final futures = urls.map((url) async {
          try {
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              return null;
            }
            final response = await dio.get<List<int>>(
              url,
              options: Options(responseType: ResponseType.bytes),
            );
            if (response.data != null) {
              return Uint8List.fromList(response.data!);
            }
          } catch (e) {
            debugPrint('Failed to fetch image $url: $e');
          }
          return null;
        });
        
        final results = await Future.wait(futures);
        for (final bytes in results) {
          if (bytes != null) {
            imageBytesList.add(bytes);
          }
        }
      }
      propertyImagesMap[p.id] = imageBytesList;
    }

    for (final p in properties) {
      final title = displayTitle(p);
      final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

      String money(double v) => v > 0 ? currency.format(v) : '-';
      String area(double? v) => v == null || v <= 0 ? '-' : '${v.toStringAsFixed(0)} sq.ft';
      String text(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

      pw.Widget row(String label, String value) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 140,
                child: pw.Text(
                  label,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
              ),
              pw.Expanded(
                child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      }

      final images = propertyImagesMap[p.id] ?? [];

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PropKart Property Details',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
          build: (context) => [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              text(p.title),
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Overview',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            row('Property Code', text(p.propertyCode)),
            row('Listing Type', text(p.listingTypeName)),
            row('Category', text(p.categoryName)),
            row('Property Type', text(p.propertyTypeName)),
            row('Configuration', text(p.configurationName ?? '${p.bedrooms} BHK')),
            row('Status', text(p.propertyStatusName)),
            row('Price', money(p.price)),
            row('Deposit', money(p.deposit)),
            row('Maintenance', money(p.maintenance)),
            pw.SizedBox(height: 12),
            pw.Text(
              'Location',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            row('Area', text(p.areaName)),
            row('City', text(p.cityName)),
            row('Pincode', text(p.pincode)),
            row('Address', text(p.address)),
            row('Landmark', text(p.landmark)),
            row('Block / Wing', text(p.blockWing)),
            row('Flat No', text(p.flatNo)),
            pw.SizedBox(height: 12),
            pw.Text(
              'Specifications',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            row('Bedrooms', '${p.bedrooms}'),
            row('Bathrooms', '${p.bathrooms}'),
            row('Balconies', '${p.balconies}'),
            row('Parking', '${p.parking}'),
            row('Floor', p.floorNo == null ? '-' : '${p.floorNo}${p.totalFloor != null ? ' / ${p.totalFloor}' : ''}'),
            row('Furnishing', text(p.furnishingTypeName)),
            row('Facing', text(p.facingTypeName)),
            row('Ownership', text(p.ownershipTypeName)),
            row('Super Built-up', area(p.superBuiltupArea)),
            row('Carpet Area', area(p.carpetArea)),
            row('Plot Area', area(p.plotArea)),
            row(
              'Age of Property',
              p.ageOfProperty == null ? '-' : '${p.ageOfProperty} years',
            ),
            row(
              'Possession',
              p.possessionDate == null
                  ? '-'
                  : DateFormat('dd MMM yyyy').format(p.possessionDate!),
            ),
            if (p.amenities.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'Amenities',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(p.amenities.join(', '), style: const pw.TextStyle(fontSize: 11)),
            ],
            if ((p.description ?? '').trim().isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'Description',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(p.description!.trim(), style: const pw.TextStyle(fontSize: 11)),
            ],
            if ((p.remarks ?? '').trim().isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'Remarks',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(p.remarks!.trim(), style: const pw.TextStyle(fontSize: 11)),
            ],
            if (images.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Images',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final imgBytes in images)
                    pw.Container(
                      width: 165,
                      height: 110,
                      decoration: const pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                        color: PdfColors.grey200,
                      ),
                      child: pw.Image(
                        pw.MemoryImage(imgBytes),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return doc.save();
  }
}
