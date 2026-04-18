import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> deleteFileIfExists(String path) async {
  final f = File(path);
  if (await f.exists()) await f.delete();
}

Future<bool> localFileExists(String path) async {
  final f = File(path);
  return await f.exists();
}

Future<void> uploadLocalFile(Reference storageRef, String path) async {
  final f = File(path);
  await storageRef.putFile(f);
}
