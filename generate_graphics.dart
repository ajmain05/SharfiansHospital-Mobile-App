import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('Starting graphic generation...');
  final logoBytes = File('assets/images/logo.png').readAsBytesSync();
  final logo = img.decodeImage(logoBytes);
  if (logo == null) {
    print('Failed to decode logo');
    return;
  }
  
  final desktop = Platform.environment['HOME']! + '/Desktop';

  // 1. Generate App Icon (512x512 with solid WHITE background)
  print('Generating App Icon...');
  final resizedLogoIcon = img.copyResize(logo, width: 400, height: 400); // slightly padded
  final appIcon = img.Image(width: 512, height: 512);
  img.fill(appIcon, color: img.ColorRgb8(255, 255, 255)); // Fill White
  final iconX = (512 - 400) ~/ 2;
  final iconY = (512 - 400) ~/ 2;
  img.compositeImage(appIcon, resizedLogoIcon, dstX: iconX, dstY: iconY);
  
  // Save as JPEG to completely eliminate transparency issues
  File('$desktop/PlayStore_AppIcon.jpeg').writeAsBytesSync(img.encodeJpg(appIcon, quality: 100));
  print('Saved PlayStore_AppIcon.jpeg!');

  // 2. Generate Feature Graphic (1024x500 with solid DARK GREEN background)
  print('Generating Feature Graphic...');
  final resizedLogoFeature = img.copyResize(logo, width: 350, height: 350);
  final featureGraphic = img.Image(width: 1024, height: 500);
  img.fill(featureGraphic, color: img.ColorRgb8(13, 92, 54)); // Fill Dark Green
  final featureX = (1024 - 350) ~/ 2;
  final featureY = (500 - 350) ~/ 2;
  img.compositeImage(featureGraphic, resizedLogoFeature, dstX: featureX, dstY: featureY);
  
  // Save as JPEG
  File('$desktop/PlayStore_FeatureGraphic.jpeg').writeAsBytesSync(img.encodeJpg(featureGraphic, quality: 100));
  print('Saved PlayStore_FeatureGraphic.jpeg!');
  
  print('All done successfully!');
}
