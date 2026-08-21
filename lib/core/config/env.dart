class Env {
  Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.sharfianshospital.com/api',
  );

  /// Must match the backend's `FRONTEND_URL` — the bKash callback URL the
  /// backend requests is `$frontendBaseUrl/events/bkash-callback`, and the
  /// checkout webview intercepts navigation to that prefix.
  static const frontendBaseUrl = String.fromEnvironment(
    'FRONTEND_BASE_URL',
    defaultValue: 'https://sharfianshospital.com',
  );

  static const cloudinaryCloudName = 'dt9tzzora';
}
