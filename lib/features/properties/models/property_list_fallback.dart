import 'property_model.dart';

/// A failed server search keeps the cached rows and marks them stale.
class PropertyListFallback {
  final List<PropertyModel> properties;
  final bool stale;

  const PropertyListFallback({required this.properties, required this.stale});

  factory PropertyListFallback.serverFailed(List<PropertyModel> cached) {
    return PropertyListFallback(properties: cached, stale: true);
  }
}
