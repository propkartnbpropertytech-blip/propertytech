import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../properties/models/property_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/design_system/crm_design_system.dart';
import '../../../core/design_system/widgets/drawers.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  PropertyModel? _property;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _propertiesSubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProperty();
    _propertiesSubscription =
        RepositoryCoordinator().propertiesStream.listen((_) {
      if (mounted && !_isRefreshing) {
        _loadLocalOnly();
      }
    });
  }

  @override
  void dispose() {
    _propertiesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLocalOnly() async {
    try {
      final local =
          await PropertiesRepository().getPropertyById(widget.propertyId);
      if (local != null && mounted) {
        setState(() {
          _property = local;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProperty() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final repository = PropertiesRepository();

      // 1. Instant local read for first paint
      final local = await repository.getPropertyById(widget.propertyId);
      if (local != null && mounted) {
        setState(() {
          _property = local;
          _isLoading = false;
          _error = null;
        });
      }

      // 2. Refresh only this property — never the full inventory list
      final fresh = await repository.getPropertyById(
        widget.propertyId,
        refreshFromServer: true,
      );

      if (fresh != null && mounted) {
        setState(() {
          _property = fresh;
          _isLoading = false;
          _error = null;
        });
      } else if (_property == null && mounted) {
        setState(() {
          _error = 'Property not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_property == null && mounted) {
        setState(() {
          _error = 'Failed to load details: $e';
          _isLoading = false;
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _property == null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _property == null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: CRMColors.backgroundOf(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: CRMColors.textOf(context),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          title: Text(
            'Property',
            style: CRMTypography.sectionTitle.copyWith(
              color: CRMColors.textOf(context),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: CRMColors.danger,
                  size: 48,
                ),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  _error!,
                  style: CRMTypography.bodyMedium.copyWith(
                    color: CRMColors.textOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CRMSpacing.s),
                Text(
                  'This link is not a property record, or the listing was removed.',
                  style: CRMTypography.body.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CRMSpacing.l),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: CRMSpacing.s,
                  runSpacing: CRMSpacing.s,
                  children: [
                    CRMButton(
                      label: 'Back to dashboard',
                      onPressed: () => context.go('/dashboard'),
                    ),
                    CRMButton(
                      label: 'View properties',
                      variant: CRMButtonVariant.outline,
                      onPressed: () => context.go('/properties'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: BuildPropertyDetailWidget(
        property: _property!,
        showHeaderClose: false,
      ),
    );
  }
}
