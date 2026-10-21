import '../../models/requirement_model.dart';
import '../../repository/requirements_repository.dart';

/// Encapsulates requirement status transition and lead stage updates.
class UpdateRequirementStatusUseCase {
  final RequirementsRepository repository;

  const UpdateRequirementStatusUseCase(this.repository);

  Future<RequirementModel> execute(RequirementModel requirement) async {
    return repository.updateLeadStatus(requirement);
  }

  Future<void> updateFields({
    required String requirementId,
    required Map<String, dynamic> fields,
  }) async {
    return repository.updateRequirementFields(requirementId, fields);
  }
}
