import '../../models/requirement_model.dart';
import '../../repository/requirements_repository.dart';

/// Encapsulates loading and filtering requirements from the data layer.
class LoadRequirementsUseCase {
  final RequirementsRepository repository;

  const LoadRequirementsUseCase(this.repository);

  Future<List<RequirementModel>> execute({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
    String? listingTypeId,
    bool refreshFromServer = true,
    bool forceRefresh = false,
  }) async {
    return repository.getRequirements(
      search: search,
      configurationId: configurationId,
      propertyTypeId: propertyTypeId,
      status: status,
      listingTypeId: listingTypeId,
      refreshFromServer: refreshFromServer,
      forceRefresh: forceRefresh,
    );
  }
}
