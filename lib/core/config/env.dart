class Env {
  Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.sharfianshospital.com/api',
  );

  static const cloudinaryCloudName = 'dt9tzzora';
}
