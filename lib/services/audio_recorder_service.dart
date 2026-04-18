import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Stub d'enregistrement audio — simule l'enregistrement pour la compilation.
/// Remplacez par une vraie implémentation lorsque vous êtes prêt.
class AudioRecorderService {
  bool _isRecording = false;
  String? _currentPath;

  Future<File> recordEmergencyAudio({int seconds = 10}) async {
    _isRecording = true;
    final path = await _getAudioPath();
    _currentPath = path;

    // Simule l'enregistrement
    await Future.delayed(Duration(seconds: seconds));

    final file = File(path);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsBytes([]);
    }

    _isRecording = false;
    return file;
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    _isRecording = true;
    _currentPath = await _getAudioPath();
  }

  Future<File?> stopRecording() async {
    if (!_isRecording) return null;
    _isRecording = false;
    final path = _currentPath;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsBytes([]);
    }
    return file;
  }

  Future<String> _getAudioPath() async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '${tempDir.path}/urgence_$timestamp.m4a';
  }

  bool get isRecording => _isRecording;
}
