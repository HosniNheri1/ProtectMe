// Simple no-op recorder implementation used as a safe fallback.
// This avoids importing web-only or io-only libraries during analysis
// and keeps the API small: hasPermission, start, stop, dispose.

class PlatformRecorder {
  PlatformRecorder();

  Future<bool> hasPermission() async => true;

  Future<void> start({String? path}) async {
    // no-op
  }

  Future<String?> stop() async {
    // No recording available in this stub; return null.
    return null;
  }

  void dispose() {}
}
