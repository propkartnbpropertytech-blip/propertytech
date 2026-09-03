import 'dart:async';
import 'local_repositories.dart';

class RepositoryCoordinator {
  static final RepositoryCoordinator _instance = RepositoryCoordinator._internal();
  factory RepositoryCoordinator() => _instance;
  RepositoryCoordinator._internal();

  final PropertyLocalRepository propertyLocal = PropertyLocalRepository();
  final RequirementLocalRepository requirementLocal = RequirementLocalRepository();
  final FollowupLocalRepository followupLocal = FollowupLocalRepository();
  final BuilderLocalRepository builderLocal = BuilderLocalRepository();
  final OwnerLocalRepository ownerLocal = OwnerLocalRepository();
  final ClientLocalRepository clientLocal = ClientLocalRepository();
  final LookupLocalRepository lookupLocal = LookupLocalRepository();
  final OutboxLocalRepository outboxLocal = OutboxLocalRepository();
  final DashboardLocalRepository dashboardLocal = DashboardLocalRepository();

  // Typed Stream Controllers
  final _propertiesController = StreamController<void>.broadcast();
  final _requirementsController = StreamController<void>.broadcast();
  final _dashboardController = StreamController<void>.broadcast();
  final _buildersController = StreamController<void>.broadcast();
  final _ownersController = StreamController<void>.broadcast();
  final _clientsController = StreamController<void>.broadcast();
  final _lookupsController = StreamController<void>.broadcast();

  // Exposed Selectable Streams
  Stream<void> get propertiesStream => _propertiesController.stream;
  Stream<void> get requirementsStream => _requirementsController.stream;
  Stream<void> get dashboardStream => _dashboardController.stream;
  Stream<void> get buildersStream => _buildersController.stream;
  Stream<void> get ownersStream => _ownersController.stream;
  Stream<void> get clientsStream => _clientsController.stream;
  Stream<void> get lookupsStream => _lookupsController.stream;

  // Debouncing Timers
  Timer? _propertiesTimer;
  Timer? _requirementsTimer;
  Timer? _dashboardTimer;
  Timer? _buildersTimer;
  Timer? _ownersTimer;
  Timer? _clientsTimer;
  Timer? _lookupsTimer;

  // Typed Debounced Broadcasters
  void refreshProperties() {
    _propertiesTimer?.cancel();
    _propertiesTimer = Timer(const Duration(milliseconds: 300), () {
      _propertiesController.add(null);
      refreshDashboard();
    });
  }

  void refreshRequirements() {
    _requirementsTimer?.cancel();
    _requirementsTimer = Timer(const Duration(milliseconds: 300), () {
      _requirementsController.add(null);
      refreshDashboard();
    });
  }

  void refreshDashboard() {
    _dashboardTimer?.cancel();
    _dashboardTimer = Timer(const Duration(milliseconds: 300), () {
      _dashboardController.add(null);
    });
  }

  void refreshBuilders() {
    _buildersTimer?.cancel();
    _buildersTimer = Timer(const Duration(milliseconds: 300), () {
      _buildersController.add(null);
    });
  }

  void refreshOwners() {
    _ownersTimer?.cancel();
    _ownersTimer = Timer(const Duration(milliseconds: 300), () {
      _ownersController.add(null);
    });
  }

  void refreshClients() {
    _clientsTimer?.cancel();
    _clientsTimer = Timer(const Duration(milliseconds: 300), () {
      _clientsController.add(null);
    });
  }

  void refreshLookups() {
    _lookupsTimer?.cancel();
    _lookupsTimer = Timer(const Duration(milliseconds: 300), () {
      _lookupsController.add(null);
    });
  }
}
