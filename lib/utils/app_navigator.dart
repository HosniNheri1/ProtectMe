import 'package:flutter/widgets.dart';

/// Global navigator key to allow services to open dialogs when the app is
/// in the foreground without needing to pass a BuildContext everywhere.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
