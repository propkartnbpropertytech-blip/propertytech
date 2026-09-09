import 'dart:async';
import 'dart:convert';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'crm_map_picker.dart';

class PlatformMapPicker extends StatefulWidget implements CRMMapPicker {
  @override
  final double? initialLatitude;
  @override
  final double? initialLongitude;
  @override
  final Function(double lat, double lng) onLocationPicked;
  @override
  final Function(Map<String, dynamic> place) onPlaceSelected;

  const PlatformMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationPicked,
    required this.onPlaceSelected,
  });

  @override
  State<PlatformMapPicker> createState() => _PlatformMapPickerWebState();
}

class _PlatformMapPickerWebState extends State<PlatformMapPicker> {
  late String _viewId;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    final double lat = widget.initialLatitude ?? 23.0225;
    final double lng = widget.initialLongitude ?? 72.5714;
    _viewId = 'map-picker-${DateTime.now().microsecondsSinceEpoch}';

    _iframe = html.IFrameElement()
      ..src = 'map_picker.html?lat=' + lat.toString() + '&lng=' + lng.toString()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => _iframe!);

    _messageSubscription = html.window.onMessage.listen((event) {
      try {
        final data = jsonDecode(event.data);
        if (data is Map) {
          if (data['type'] == 'google_place_selected') {
            widget.onPlaceSelected(Map<String, dynamic>.from(data));
          } else if (data['type'] == 'map_coordinates') {
            final double? latVal = (data['latitude'] as num?)?.toDouble();
            final double? lngVal = (data['longitude'] as num?)?.toDouble();
            if (latVal != null && lngVal != null) {
              widget.onLocationPicked(latVal, lngVal);
            }
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }
}
