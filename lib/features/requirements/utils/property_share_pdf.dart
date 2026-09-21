import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/budget_formatter.dart';
import '../../properties/models/property_model.dart';

enum PdfTemplateStyle {
  option1, // Clean, Premium Modern Real-Estate Brochure
  option2, // Executive Portfolio Dossier
  option3, // Architectural Showcase Dossier
}

/// Builds real-estate property brochure PDF dossiers with PropKart branding & icons.
class PropertySharePdf {
  // Session image cache for instant PDF generation speed
  static final Map<String, Uint8List> _imageCache = {};

  @visibleForTesting
  static Map<String, Uint8List> get imageCacheForTest => _imageCache;

  static String displayTitle(PropertyModel p) {
    final bhk = (p.configurationName != null && p.configurationName!.trim().isNotEmpty)
        ? p.configurationName!.trim()
        : '${p.bedrooms} BHK';
    final price = 'Rs ${BudgetFormatter.format(p.price)}';
    final areaName = p.areaName;
    final cityName = p.cityName;
    final address = p.address;
    final landmark = p.landmark ?? '';
    final propCode = p.propertyCode;

    final area = (areaName.isNotEmpty && areaName != 'N/A')
        ? areaName
        : ((landmark.isNotEmpty && landmark != 'N/A')
            ? landmark
            : ((address.isNotEmpty && address != 'N/A')
                ? address
                : (cityName.isNotEmpty && cityName != 'N/A' ? cityName : '')));
    final locationStr = area.isNotEmpty ? ' in $area' : '';
    return '$bhk$locationStr - $price ($propCode)';
  }

  static String fileName(PropertyModel p) {
    final raw = displayTitle(p);
    final safe = raw.replaceAll(RegExp(r'[^\w\s\.-]'), '_').replaceAll(RegExp(r'\s+'), '_').trim();
    return '$safe.pdf';
  }

  /// Cloudinary image URL optimization helper (requests compressed 600x400 JPEG for ultra-fast generation)
  static String _optimizeImageUrl(String url) {
    if (url.contains('cloudinary.com') && url.contains('/upload/')) {
      return url.replaceFirst('/upload/', '/upload/w_600,h_400,c_fill,q_70,f_jpg/');
    }
    return url;
  }

  static bool _isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 100) return false;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true; // JPEG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true; // PNG
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true; // GIF
    if (bytes.length > 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) return true; // WEBP/RIFF
    return false;
  }

  static Uint8List? _toJpegOrPngBytes(Uint8List bytes) {
    if (bytes.length < 100) return null;
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return bytes;
    // PNG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return bytes;

    // Convert WebP / GIF / BMP to PNG using image package
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        return Uint8List.fromList(img.encodePng(decoded));
      }
    } catch (e) {
      debugPrint('Failed to convert image to PNG for PDF: $e');
    }
    return null;
  }

  static pw.MemoryImage? _safeMemoryImage(Uint8List bytes) {
    if (!_isValidImageBytes(bytes)) return null;
    final validBytes = _toJpegOrPngBytes(bytes);
    if (validBytes == null) return null;
    try {
      return pw.MemoryImage(validBytes);
    } catch (e) {
      debugPrint('Failed to decode image bytes for PDF: $e');
      return null;
    }
  }

  /// Preloads property images into memory cache as soon as share dialog opens
  static Future<void> preloadImages(List<PropertyModel> properties) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 1500),
        receiveTimeout: const Duration(milliseconds: 2000),
      ),
    );

    final List<String> urlsToFetch = [];
    for (final p in properties) {
      for (final rawUrl in p.images) {
        final url = _optimizeImageUrl(rawUrl);
        if ((url.startsWith('http://') || url.startsWith('https://')) && !_imageCache.containsKey(url)) {
          urlsToFetch.add(url);
        }
      }
    }

    if (urlsToFetch.isEmpty) return;

    final futures = urlsToFetch.map((url) async {
      try {
        final response = await dio.get(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            validateStatus: (status) => status != null && status < 400,
          ),
        );
        if (response.data != null) {
          List<int>? rawBytes;
          if (response.data is List<int>) {
            rawBytes = response.data as List<int>;
          } else if (response.data is Uint8List) {
            rawBytes = response.data as Uint8List;
          }
          if (rawBytes != null && rawBytes.isNotEmpty) {
            final bytes = Uint8List.fromList(rawBytes);
            if (_isValidImageBytes(bytes)) {
              _imageCache[url] = bytes;
            }
          }
        }
      } catch (e) {
        debugPrint('Preload image failed for $url: $e');
      }
    });

    try {
      await Future.wait(futures).timeout(const Duration(seconds: 3), onTimeout: () => []);
    } catch (_) {}
  }

  static Future<Uint8List> build(
    List<PropertyModel> properties, {
    PdfTemplateStyle templateStyle = PdfTemplateStyle.option1,
  }) async {
    final doc = pw.Document();

    // Load PropKart brand logo asset
    Uint8List? logoBytes;
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      logoBytes = logoData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to load logo asset: $e');
    }

    // Fetch or reuse cached bytes for ALL property images concurrently
    final Map<String, List<Uint8List>> propertyImagesMap = {};
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: 1500),
        receiveTimeout: const Duration(milliseconds: 2000),
      ),
    );

    for (final p in properties) {
      final List<Uint8List> imageBytesList = [];
      if (p.images.isNotEmpty) {
        final List<Future<Uint8List?>> futures = [];
        for (final rawUrl in p.images) {
          final url = _optimizeImageUrl(rawUrl);
          if (_imageCache.containsKey(url) && _isValidImageBytes(_imageCache[url]!)) {
            imageBytesList.add(_imageCache[url]!);
          } else if (url.startsWith('http://') || url.startsWith('https://')) {
            futures.add(() async {
              try {
                final response = await dio.get(
                  url,
                  options: Options(
                    responseType: ResponseType.bytes,
                    validateStatus: (status) => status != null && status < 400,
                  ),
                );
                if (response.data != null) {
                  List<int>? rawBytes;
                  if (response.data is List<int>) {
                    rawBytes = response.data as List<int>;
                  } else if (response.data is Uint8List) {
                    rawBytes = response.data as Uint8List;
                  }
                  if (rawBytes != null && rawBytes.isNotEmpty) {
                    final bytes = Uint8List.fromList(rawBytes);
                    if (_isValidImageBytes(bytes)) {
                      _imageCache[url] = bytes;
                      return bytes;
                    }
                  }
                }
              } catch (e) {
                debugPrint('Failed to fetch image $url: $e');
              }
              return null;
            }());
          }
        }

        if (futures.isNotEmpty) {
          try {
            final results = await Future.wait(futures).timeout(
              const Duration(seconds: 4),
              onTimeout: () => [],
            );
            for (final b in results) {
              if (b != null && _isValidImageBytes(b)) imageBytesList.add(b);
            }
          } catch (e) {
            debugPrint('Image futures error: $e');
          }
        }
      }
      propertyImagesMap[p.id] = imageBytesList;
    }

    for (int idx = 0; idx < properties.length; idx++) {
      final p = properties[idx];
      final images = propertyImagesMap[p.id] ?? [];
      final headerSubtitle = properties.length > 1
          ? 'PROPERTY ${idx + 1} OF ${properties.length} (${p.propertyCode})'
          : 'PROPERTY ID: ${p.propertyCode}';
      switch (templateStyle) {
        case PdfTemplateStyle.option1:
          _buildOption1Page(doc, p, images, logoBytes, headerSubtitle);
          break;
        case PdfTemplateStyle.option2:
          _buildOption2Page(doc, p, images, logoBytes, headerSubtitle);
          break;
        case PdfTemplateStyle.option3:
          _buildOption3Page(doc, p, images, logoBytes, headerSubtitle);
          break;
      }
    }

    return doc.save();
  }

  // Helper formatting routines
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);
  static String _money(double? v) => (v != null && v > 0) ? _currency.format(v) : '-';
  static String _area(double? v) => (v == null || v <= 0) ? '-' : '${v.toStringAsFixed(0)} sq.ft';
  static String _text(dynamic v) => (v == null || v.toString().trim().isEmpty || v.toString().trim() == 'null') ? '-' : v.toString().trim();
  static String _date(DateTime? d) => d == null ? '-' : DateFormat('dd MMM yyyy').format(d);

  // Vector SVG Icons
  static const String _svgBed = '<svg viewBox="0 0 24 24"><path fill="COLOR" d="M19 7h-8v8H3V5H1v15h2v-3h18v3h2v-9c0-2.21-1.79-4-4-4zm-2 6h-6V9h6v4z"/></svg>';
  static const String _svgBath = '<svg viewBox="0 0 24 24"><path fill="COLOR" d="M21 11H3c-.55 0-1 .45-1 1v2c0 2.76 2.24 5 5 5h10c2.76 0 5-2.24 5-5v-2c0-.55-.45-1-1-1zm-9-8c-1.66 0-3 1.34-3 3v2h2V6c0-.55.45-1 1-1s1 .45 1 1v4h2V6c0-1.66-1.34-3-3-3z"/></svg>';
  static const String _svgArea = '<svg viewBox="0 0 24 24"><path fill="COLOR" d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 10h-4v4h-2v-4H7v-2h4V7h2v4h4v2z"/></svg>';
  static const String _svgLocation = '<svg viewBox="0 0 24 24"><path fill="COLOR" d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>';
  static const String _svgPrice = '<svg viewBox="0 0 24 24"><path fill="COLOR" d="M21.41 11.58l-9-9C12.05 2.22 11.55 2 11 2H4c-1.1 0-2 .9-2 2v7c0 .55.22 1.05.59 1.42l9 9c.36.36.86.58 1.41.58.55 0 1.05-.22 1.41-.59l7-7c.37-.36.59-.86.59-1.41 0-.55-.23-1.06-.59-1.42zM5.5 7C4.67 7 4 6.33 4 5.5S4.67 4 5.5 4 7 4.67 7 5.5 6.33 7 5.5 7z"/></svg>';
  static const String _svgFurnishing = '<svg viewBox="0 0 24 24"><path fill="COLOR" d="M20 10V7c0-1.1-.9-2-2-2H6c-1.1 0-2 .9-2 2v3c-1.1 0-2 .9-2 2v5h2v-2h16v2h2v-5c0-1.1-.9-2-2-2zm-14-3h12v3H6V7z"/></svg>';
  static const String _svgParking = '<svg viewBox="0 0 24 24"><path fill="COLOR" d="M13.2 11H10V7h3.2c1.1 0 2 .9 2 2s-.9 2-2 2zM19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-3.8 8c0 2.2-1.8 4-4 4H10v4H8V5h5.2c2.2 0 4 1.8 4 4z"/></svg>';
  static const String _svgBuilding = '<svg viewBox="0 0 24 24"><path fill="COLOR" d="M12 7V3H2v18h20V7H12zM6 19H4v-2h2v2zm0-4H4v-2h2v2zm0-4H4V9h2v2zm0-4H4V5h2v2zm4 12H8v-2h2v2zm0-4H8v-2h2v2zm0-4H8V9h2v2zm0-4H8V5h2v2zm10 12h-8v-2h2v-2h-2v-2h2v-2h-2V9h8v10zm-2-8h-2v2h2v-2zm0 4h-2v2h2v-2z"/></svg>';

  static pw.Widget _svgIcon(String rawSvg, {double width = 11, double height = 11, required String colorHex}) {
    String cleanHex = colorHex.trim();
    while (cleanHex.startsWith('#')) {
      cleanHex = cleanHex.substring(1);
    }
    final hex = '#$cleanHex';
    final filledSvg = rawSvg.replaceAll('COLOR', hex);
    return pw.SvgImage(svg: filledSvg, width: width, height: height);
  }

  // Header Brand Widget showing Logo + "PropKart" text directly to the right!
  static pw.Widget _buildBrandHeader({
    required Uint8List? logoBytes,
    required PdfColor primaryColor,
    required String themeTitle,
    required String headerSubtitle,
  }) {
    final hexStr = primaryColor.toHex();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Logo + PropKart text directly to its right!
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoBytes != null)
                  pw.Container(
                    height: 36,
                    width: 36,
                    margin: const pw.EdgeInsets.only(right: 8),
                    child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    margin: const pw.EdgeInsets.only(right: 8),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'PK',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ),
                pw.Text(
                  'PropKart',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  themeTitle.toUpperCase(),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
                pw.SizedBox(height: 2),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      _svgIcon(_svgBuilding, width: 9, height: 9, colorHex: hexStr),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        headerSubtitle,
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: primaryColor),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // Footer Widget
  static pw.Widget _buildBrandFooter(pw.Context context, PdfColor primaryColor) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('PropKart Realty Platform | Verified Property Dossier', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _imageCardWithOverlay({
    required Uint8List bytes,
    required int index,
    required double height,
    required PdfColor borderAccent,
    PdfColor? badgeBgColor,
  }) {
    final memoryImg = _safeMemoryImage(bytes);
    if (memoryImg == null) return pw.SizedBox();

    final badgeColor = badgeBgColor ?? PdfColor(0, 0, 0, 0.65);
    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderAccent, width: 0.9),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 6,
        verticalRadius: 6,
        child: pw.Stack(
          alignment: pw.Alignment.bottomLeft,
          children: [
            pw.Container(
              width: double.infinity,
              height: height,
              alignment: pw.Alignment.center,
              child: pw.Image(memoryImg, fit: pw.BoxFit.contain, height: height),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: badgeColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Text(
                  '${(index + 1).toString().padLeft(2, '0')} Photo',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<pw.Widget> _buildGridGalleryElements(
    List<Uint8List> images,
    PdfColor accentColor, {
    PdfColor? badgeBgColor,
  }) {
    if (images.isEmpty) return [];

    // 1st image: Big hero section at top
    final mainImage = images[0];
    final List<pw.Widget> elements = [
      _imageCardWithOverlay(
        bytes: mainImage,
        index: 0,
        height: 180,
        borderAccent: accentColor,
        badgeBgColor: badgeBgColor,
      ),
      pw.SizedBox(height: 6),
    ];

    if (images.length == 1) return elements;

    // Remaining images in 2-by-2 grid (2 per row)
    final remainingImages = images.sublist(1);
    final List<MapEntry<int, Uint8List>> indexedRemaining = [];
    for (int i = 0; i < remainingImages.length; i++) {
      indexedRemaining.add(MapEntry(i + 1, remainingImages[i]));
    }

    for (int i = 0; i < indexedRemaining.length; i += 2) {
      final rowItems = indexedRemaining.sublist(
        i,
        (i + 2 > indexedRemaining.length) ? indexedRemaining.length : i + 2,
      );

      elements.add(
        pw.Row(
          children: [
            for (int j = 0; j < rowItems.length; j++) ...[
              if (j > 0) pw.SizedBox(width: 6),
              pw.Expanded(
                child: _imageCardWithOverlay(
                  bytes: rowItems[j].value,
                  index: rowItems[j].key,
                  height: 125,
                  borderAccent: PdfColors.grey400,
                  badgeBgColor: badgeBgColor,
                ),
              ),
            ],
            if (rowItems.length == 1) ...[
              pw.SizedBox(width: 6),
              pw.Expanded(child: pw.SizedBox()),
            ],
          ],
        ),
      );
      elements.add(pw.SizedBox(height: 6));
    }

    return elements;
  }

  static List<pw.Widget> _buildOption1GalleryElements(List<Uint8List> images, PdfColor accentColor) {
    return _buildGridGalleryElements(images, accentColor);
  }

  static List<pw.Widget> _buildOption2GalleryElements(List<Uint8List> images, PdfColor accentColor) {
    final goldAccent = PdfColor.fromHex('#D97706');
    return _buildGridGalleryElements(images, goldAccent, badgeBgColor: goldAccent);
  }

  static List<pw.Widget> _buildOption3GalleryElements(List<Uint8List> images, PdfColor accentColor) {
    final cyanColor = PdfColor.fromHex('#06B6D4');
    return _buildGridGalleryElements(images, accentColor, badgeBgColor: cyanColor);
  }

  // =========================================================================
  // OPTION 1: Clean, Premium Modern Real-Estate Brochure
  // =========================================================================
  static void _buildOption1Page(
    pw.Document doc,
    PropertyModel p,
    List<Uint8List> images,
    Uint8List? logoBytes,
    String headerSubtitle,
  ) {
    final title = displayTitle(p);
    final primaryTeal = PdfColor.fromHex('#0D9488');
    final darkText = PdfColor.fromHex('#1E293B');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final tealHex = '#0D9488';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(left: 26, right: 26, top: 40, bottom: 26),
        header: (context) => _buildBrandHeader(
          logoBytes: logoBytes,
          primaryColor: primaryTeal,
          themeTitle: 'Premium Real Estate Brochure',
          headerSubtitle: headerSubtitle,
        ),
        footer: (context) => _buildBrandFooter(context, primaryTeal),
        build: (context) => [
          if (images.isNotEmpty) ...[
            ..._buildOption1GalleryElements(images, primaryTeal),
            pw.SizedBox(height: 10),
          ],

          // Title & Price Banner Box
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: darkText),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          _svgIcon(_svgLocation, width: 10, height: 10, colorHex: tealHex),
                          pw.SizedBox(width: 4),
                          pw.Expanded(
                            child: pw.Text(
                              '${_text(p.address)}, ${_text(p.areaName)}, ${_text(p.cityName)}',
                              style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: primaryTeal,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      _svgIcon(_svgPrice, width: 11, height: 11, colorHex: '#FFFFFF'),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _money(p.price),
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // 3 CATEGORIZED DETAIL SECTIONS (Overview, Location, Specifications)
          _buildOverviewSection(p, primaryTeal, tealHex),
          pw.SizedBox(height: 10),
          _buildLocationSection(p, primaryTeal, tealHex),
          pw.SizedBox(height: 10),
          _buildSpecificationsSection(p, primaryTeal, tealHex),

          if (p.amenities.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildAmenitiesSection(p.amenities, primaryTeal),
          ],

          if ((p.description ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border(left: pw.BorderSide(color: primaryTeal, width: 3)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PROPERTY DESCRIPTION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryTeal)),
                  pw.SizedBox(height: 4),
                  pw.Text(p.description!.trim(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // OPTION 2: Executive Portfolio Dossier Layout
  // =========================================================================
  static void _buildOption2Page(
    pw.Document doc,
    PropertyModel p,
    List<Uint8List> images,
    Uint8List? logoBytes,
    String headerSubtitle,
  ) {
    final title = displayTitle(p);
    final navyColor = PdfColor.fromHex('#1E3A8A');
    final goldAccent = PdfColor.fromHex('#D97706');
    final navyHex = '#1E3A8A';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(left: 26, right: 26, top: 40, bottom: 26),
        header: (context) => _buildBrandHeader(
          logoBytes: logoBytes,
          primaryColor: navyColor,
          themeTitle: 'Executive Portfolio Dossier',
          headerSubtitle: headerSubtitle,
        ),
        footer: (context) => _buildBrandFooter(context, navyColor),
        build: (context) => [
          // Header Summary Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: navyColor),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      children: [
                        _svgIcon(_svgLocation, width: 10, height: 10, colorHex: navyHex),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Text(
                            '${_text(p.address)}, ${_text(p.areaName)}',
                            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _money(p.price),
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: goldAccent),
                  ),
                  pw.Text('Listing: ${_text(p.listingTypeName)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // ALL PROPERTY IMAGES AT TOP
          if (images.isNotEmpty) ...[
            ..._buildOption2GalleryElements(images, navyColor),
            pw.SizedBox(height: 10),
          ],

          // 3 CATEGORIZED DETAIL SECTIONS
          _buildOverviewSection(p, navyColor, navyHex),
          pw.SizedBox(height: 10),
          _buildLocationSection(p, navyColor, navyHex),
          pw.SizedBox(height: 10),
          _buildSpecificationsSection(p, navyColor, navyHex),

          if (p.amenities.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildAmenitiesSection(p.amenities, navyColor),
          ],

          if ((p.description ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(left: pw.BorderSide(color: navyColor, width: 3)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DOSSIER REMARKS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: navyColor)),
                  pw.SizedBox(height: 4),
                  pw.Text(p.description!.trim(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // OPTION 3: Architectural Showcase Dossier Layout
  // =========================================================================
  static void _buildOption3Page(
    pw.Document doc,
    PropertyModel p,
    List<Uint8List> images,
    Uint8List? logoBytes,
    String headerSubtitle,
  ) {
    final title = displayTitle(p);
    final darkSlate = PdfColor.fromHex('#0F172A');
    final cyanAccent = PdfColor.fromHex('#06B6D4');
    final cyanHex = '#06B6D4';
    final slateHex = '#0F172A';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(left: 26, right: 26, top: 40, bottom: 26),
        header: (context) => _buildBrandHeader(
          logoBytes: logoBytes,
          primaryColor: darkSlate,
          themeTitle: 'Architectural Dossier Series',
          headerSubtitle: headerSubtitle,
        ),
        footer: (context) => _buildBrandFooter(context, darkSlate),
        build: (context) => [
          // ALL PROPERTY IMAGES AT TOP
          if (images.isNotEmpty) ...[
            ..._buildOption3GalleryElements(images, darkSlate),
            pw.SizedBox(height: 10),
          ],

          // Title Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkSlate),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      children: [
                        _svgIcon(_svgLocation, width: 10, height: 10, colorHex: cyanHex),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Text(
                            '${_text(p.address)}, ${_text(p.areaName)}, ${_text(p.cityName)}',
                            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: darkSlate,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  _money(p.price),
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: cyanAccent),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // 3 CATEGORIZED DETAIL SECTIONS
          _buildOverviewSection(p, darkSlate, slateHex),
          pw.SizedBox(height: 10),
          _buildLocationSection(p, darkSlate, slateHex),
          pw.SizedBox(height: 10),
          _buildSpecificationsSection(p, darkSlate, slateHex),

          if (p.amenities.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildAmenitiesSection(p.amenities, darkSlate),
          ],

          if ((p.description ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'OVERVIEW & HIGHLIGHTS',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkSlate),
            ),
            pw.SizedBox(height: 4),
            pw.Text(p.description!.trim(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // CATEGORIZED SECTION BUILDERS (Overview, Location, Specifications)
  // All 29 specified property details explicitly fetched and formatted!
  // =========================================================================

  // 1. OVERVIEW SECTION
  static pw.Widget _buildOverviewSection(PropertyModel p, PdfColor primaryColor, String iconHex) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: primaryColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _svgIcon(_svgBuilding, width: 11, height: 11, colorHex: iconHex),
              pw.SizedBox(width: 5),
              pw.Text('Overview', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            ],
          ),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Property Code', _text(p.propertyCode), _svgBuilding, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Listing Type', _text(p.listingTypeName), _svgPrice, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Category', _text(p.categoryName), _svgBuilding, iconHex)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Property Type', _text(p.propertyTypeName), _svgBuilding, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Configuration', _text(p.configurationName ?? '${p.bedrooms} BHK'), _svgBed, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Status', _text(p.propertyStatusName), _svgBuilding, iconHex)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Price', _money(p.price), _svgPrice, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Deposit', _money(p.deposit), _svgPrice, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Maintenance', _money(p.maintenance), _svgPrice, iconHex)),
            ],
          ),
        ],
      ),
    );
  }

  // 2. LOCATION SECTION
  static pw.Widget _buildLocationSection(PropertyModel p, PdfColor primaryColor, String iconHex) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: primaryColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _svgIcon(_svgLocation, width: 11, height: 11, colorHex: iconHex),
              pw.SizedBox(width: 5),
              pw.Text('Location Details', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            ],
          ),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Area', _text(p.areaName), _svgLocation, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('City', _text(p.cityName), _svgLocation, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Pincode', _text(p.pincode), _svgLocation, iconHex)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(flex: 2, child: _detailRow('Address', _text(p.address), _svgLocation, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Landmark', _text(p.landmark), _svgLocation, iconHex)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Block / Wing', _text(p.blockWing), _svgBuilding, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Flat No.', _text(p.flatNo), _svgBuilding, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  // 3. SPECIFICATIONS SECTION
  static pw.Widget _buildSpecificationsSection(PropertyModel p, PdfColor primaryColor, String iconHex) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: primaryColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _svgIcon(_svgArea, width: 11, height: 11, colorHex: iconHex),
              pw.SizedBox(width: 5),
              pw.Text('Specifications', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            ],
          ),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Bedrooms', '${p.bedrooms}', _svgBed, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Bathrooms', '${p.bathrooms}', _svgBath, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Balconies', '${p.balconies}', _svgBed, iconHex)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Parking', '${p.parking}', _svgParking, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Floor', p.floorNo == null ? '-' : '${p.floorNo}${p.totalFloor != null ? ' / ${p.totalFloor}' : ''}', _svgBuilding, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Furnishing', _text(p.furnishingTypeName), _svgFurnishing, iconHex)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Facing', _text(p.facingTypeName), _svgLocation, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Ownership', _text(p.ownershipTypeName), _svgBuilding, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Super Built-up Area', _area(p.superBuiltupArea), _svgArea, iconHex)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Carpet Area', _area(p.carpetArea), _svgArea, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Plot Area', _area(p.plotArea), _svgArea, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _detailRow('Age of Property', p.ageOfProperty == null ? '-' : '${p.ageOfProperty} years', _svgBuilding, iconHex)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _detailRow('Possession', _date(p.possessionDate), _svgBuilding, iconHex)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.SizedBox()),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  // 4. AMENITIES SECTION (Clean, modern button/chip-style elements with visible text!)
  static pw.Widget _buildAmenitiesSection(List<String> amenities, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('AMENITIES & FEATURES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
        pw.SizedBox(height: 4),
        pw.Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            for (final item in amenities)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F1F5F9'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
                  border: pw.Border.all(color: primaryColor, width: 0.6),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      decoration: pw.BoxDecoration(color: primaryColor, shape: pw.BoxShape.circle),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(
                      item,
                      style: pw.TextStyle(fontSize: 9, color: primaryColor, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Compact Detail Row Helper
  static pw.Widget _detailRow(String label, String value, String svgRaw, String iconHex) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _svgIcon(svgRaw, width: 8, height: 8, colorHex: iconHex),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
