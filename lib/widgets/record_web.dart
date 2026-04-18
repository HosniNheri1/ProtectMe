// Web recorder implementation using DOM event listeners to avoid non-existing getters.
// This file intentionally uses `dart:html` and is only used on web builds.
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

class PlatformRecorder {
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  PlatformRecorder();

  Future<bool> hasPermission() async {
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
      });
      stream.getAudioTracks().forEach((t) => t.stop());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> start({String? path}) async {
    _chunks.clear();
    _stream = await html.window.navigator.mediaDevices!.getUserMedia({
      'audio': true,
    });
    // Create MediaRecorder with preferred mimeType
    try {
      _recorder = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
    } catch (_) {
      _recorder = html.MediaRecorder(_stream!);
    }

    // Use addEventListener to collect blobs
    _recorder!.addEventListener('dataavailable', (html.Event ev) {
      try {
        final be = ev as html.BlobEvent;
        if (be.data != null) _chunks.add(be.data as html.Blob);
      } catch (_) {}
    });

    _recorder!.start();
  }

  Future<String?> stop() async {
    if (_recorder == null) return null;

    final completer = Completer<String?>();

    _recorder!.addEventListener('stop', (html.Event _) async {
      try {
        final blob = html.Blob(_chunks, 'audio/webm');
        final reader = html.FileReader();
        reader.readAsDataUrl(blob);
        await reader.onLoad.first;
        final dataUrl = reader.result as String?;
        _stream?.getAudioTracks().forEach((t) => t.stop());
        _recorder = null;
        _stream = null;
        _chunks.clear();
        completer.complete(dataUrl);
      } catch (e) {
        completer.complete(null);
      }
    });

    try {
      _recorder!.stop();
    } catch (_) {
      // ignore
    }

    return completer.future;
  }

  void dispose() {
    try {
      _stream?.getAudioTracks().forEach((t) => t.stop());
    } catch (_) {}
  }
}
