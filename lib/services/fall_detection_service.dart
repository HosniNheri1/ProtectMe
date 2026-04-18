// Conditional export: use the native implementation on non-web platforms,
// and a lightweight stub on the web so the app can compile and run in Chrome.
export 'fall_detection_service_io.dart'
    if (dart.library.html) 'fall_detection_service_web.dart';
