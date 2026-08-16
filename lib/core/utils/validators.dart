class Validators {
  Validators._();

  static bool isValidBdPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? phone(String? value, String message) {
    if (value == null || !isValidBdPhone(value)) return message;
    return null;
  }
}
