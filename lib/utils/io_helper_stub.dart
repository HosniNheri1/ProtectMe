import 'package:firebase_storage/firebase_storage.dart';

Future<void> deleteFileIfExists(String path) async {
  // no-op on web
}

Future<bool> localFileExists(String path) async {
  return false;
}

Future<void> uploadLocalFile(Reference storageRef, String path) async {
  throw UnsupportedError('uploadLocalFile is not supported on web');
}
