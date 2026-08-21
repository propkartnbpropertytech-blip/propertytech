class CRMDraftRepository {
  static final CRMDraftRepository _instance = CRMDraftRepository._internal();
  factory CRMDraftRepository() => _instance;
  CRMDraftRepository._internal();

  final Map<String, Map<String, dynamic>> _drafts = {};

  void saveDraft(String formKey, Map<String, dynamic> data) {
    _drafts[formKey] = data;
  }

  Map<String, dynamic>? getDraft(String formKey) {
    return _drafts[formKey];
  }

  void clearDraft(String formKey) {
    _drafts.remove(formKey);
  }

  bool hasDraft(String formKey) {
    return _drafts.containsKey(formKey) && _drafts[formKey]!.isNotEmpty;
  }
}
