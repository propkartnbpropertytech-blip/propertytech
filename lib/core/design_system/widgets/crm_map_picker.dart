import 'package:flutter/material.dart';
import 'crm_map_picker_web.dart' if (dart.library.io) 'crm_map_picker_mobile.dart';

abstract class CRMMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double lat, double lng) onLocationPicked;
  final Function(Map<String, dynamic> place) onPlaceSelected;

  const CRMMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationPicked,
    required this.onPlaceSelected,
  });

  factory CRMMapPicker.platform({
    Key? key,
    double? initialLatitude,
    double? initialLongitude,
    required Function(double lat, double lng) onLocationPicked,
    required Function(Map<String, dynamic> place) onPlaceSelected,
  }) = PlatformMapPicker;
}
