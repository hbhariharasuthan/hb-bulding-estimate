/// General helpers (Laravel-like `app/Helpers`).
class AppHelpers {
  AppHelpers._();

  static String? trimOrNull(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
