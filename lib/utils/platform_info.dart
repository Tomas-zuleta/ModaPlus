import 'package:flutter/foundation.dart';

/// True cuando se ejecuta en escritorio o en el navegador (es decir, "en
/// el computador"), a diferencia de un dispositivo móvil (Android / iOS).
bool get isDesktopPlatform {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}