import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:protectme/services/audio_recorder_service.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final AudioRecorderService _audioService = AudioRecorderService();
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Audio')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                setState(() => _isRecording = true);
                File? audioFile;
                try {
                  audioFile = await _audioService.recordEmergencyAudio();
                } catch (e) {
                  audioFile = null;
                }
                setState(() => _isRecording = false);
                if (audioFile != null) {
                  await Share.shareFiles([audioFile.path]);
                }
              },
              child: _isRecording
                  ? const Text('Enregistrement en cours... (10s)')
                  : const Text('📞 Enregistrer message (10s)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (!_isRecording) {
                  await _audioService.startRecording();
                  setState(() => _isRecording = true);
                } else {
                  File? audioFile = await _audioService.stopRecording();
                  setState(() => _isRecording = false);
                  if (audioFile != null) {
                    await Share.shareFiles([audioFile.path]);
                  }
                }
              },
              child: _isRecording
                  ? const Text('⏹️ Arrêter l\'enregistrement')
                  : const Text('🎤 Démarrer l\'enregistrement'),
            ),
          ],
        ),
      ),
    );
  }
}