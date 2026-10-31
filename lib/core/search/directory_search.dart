bool _contains(String? value, String query) {
  return (value ?? '').toLowerCase().contains(query.toLowerCase());
}

bool clientSearchMatches({
  required String name,
  required String email,
  required String mobile,
  String? remarks,
  required String query,
}) {
  return _contains(name, query) ||
      _contains(email, query) ||
      _contains(mobile, query) ||
      _contains(remarks, query);
}

bool ownerSearchMatches({
  required String name,
  String? mobile,
  String? email,
  String? address,
  String? remarks,
  required String query,
}) {
  return _contains(name, query) ||
      _contains(mobile, query) ||
      _contains(email, query) ||
      _contains(address, query) ||
      _contains(remarks, query);
}

bool builderSearchMatches({
  required String companyName,
  String? contactPerson,
  String? mobile,
  String? email,
  List<String> activeProjects = const [],
  String? remarks,
  required String query,
}) {
  return _contains(companyName, query) ||
      _contains(contactPerson, query) ||
      _contains(mobile, query) ||
      _contains(email, query) ||
      activeProjects.any((project) => _contains(project, query)) ||
      _contains(remarks, query);
}

const clientSearchFields = ['name', 'email', 'mobile', 'remarks'];
const ownerSearchFields = ['name', 'mobile', 'email', 'address', 'remarks'];
const builderSearchFields = ['company_name', 'contact_person', 'mobile', 'email', 'active_projects', 'remarks'];
