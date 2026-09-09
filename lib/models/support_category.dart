/// One Support-query category (id + label), admin-editable from the web
/// dashboard's Settings — see `GET /support/categories`.
class SupportCategory {
  final String id;
  final String label;

  const SupportCategory({required this.id, required this.label});

  factory SupportCategory.fromJson(Map<String, dynamic> json) {
    return SupportCategory(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}
