import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/language_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:protectme/utils/io_helper.dart';
import 'package:protectme/widgets/record_stub.dart'
    if (dart.library.html) 'package:protectme/widgets/record_web.dart';

class ConfirmAlertDialog extends StatefulWidget {
  final bool isWeb;

  const ConfirmAlertDialog({super.key, required this.isWeb});

  @override
  _ConfirmAlertDialogState createState() => _ConfirmAlertDialogState();
}

class _ConfirmAlertDialogState extends State<ConfirmAlertDialog> {
  String _selectedMethod = '';
  bool _attachAudio = true;
  bool _isRecording = false;
  String? _audioFilePath;
  final PlatformRecorder _recorder = PlatformRecorder();

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.isWeb ? 'whatsapp' : 'sms';
  }

  @override
  Widget build(BuildContext context) {
    final magenta = Color(0xFFEA3ECF);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Provider.of<LanguageService>(context).t('confirm_sos'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                Provider.of<LanguageService>(context).t('confirm_sos_message'),
              ),
              SizedBox(height: 16),

              // Méthode d'envoi
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Provider.of<LanguageService>(context).t('send_method'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Option WhatsApp (principal pour le web)
                      Row(
                        children: [
                          Radio<String>(
                            value: 'whatsapp',
                            groupValue: _selectedMethod,
                            onChanged: (v) =>
                                setState(() => _selectedMethod = v ?? ''),
                            activeColor: magenta,
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.chat, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Provider.of<LanguageService>(
                                    context,
                                  ).t('whatsapp'),
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  Provider.of<LanguageService>(
                                    context,
                                  ).t('recommended_on_web'),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Option SMS - envoie un SMS au numéro d'urgence (visible sur web et mobile)
                      Row(
                        children: [
                          Radio<String>(
                            value: 'sms',
                            groupValue: _selectedMethod,
                            onChanged: (v) =>
                                setState(() => _selectedMethod = v ?? ''),
                            activeColor: magenta,
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.sms, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Provider.of<LanguageService>(
                                    context,
                                  ).t('send_sms'),
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  Provider.of<LanguageService>(
                                    context,
                                  ).t('send_sms_note'),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Info box: show context-sensitive note depending on selected method
                      if (_selectedMethod == 'whatsapp')
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Provider.of<LanguageService>(
                                    context,
                                  ).t('whatsapp_web_note'),
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Provider.of<LanguageService>(
                                    context,
                                  ).t('send_sms_note'),
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _attachAudio,
                          onChanged: (v) =>
                              setState(() => _attachAudio = v ?? true),
                        ),
                        Expanded(
                          child: Text(
                            Provider.of<LanguageService>(
                              context,
                            ).t('attach_audio'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: (_attachAudio)
                    ? () async {
                        if (_isRecording) {
                          final path = await _recorder.stop();
                          setState(() {
                            _isRecording = false;
                            if (path != null) _audioFilePath = path;
                          });
                        } else {
                          final hasPerm = await _recorder.hasPermission();
                          if (!hasPerm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  Provider.of<LanguageService>(
                                    context,
                                  ).t('permission_micro_required'),
                                ),
                              ),
                            );
                            return;
                          }

                          if (kIsWeb) {
                            await _recorder.start();
                            setState(() {
                              _isRecording = true;
                              _audioFilePath = null;
                            });
                          } else {
                            final tempDir = await getTemporaryDirectory();
                            final filePath =
                                '${tempDir.path}/alert_${DateTime.now().millisecondsSinceEpoch}.m4a';
                            await _recorder.start(path: filePath);
                            setState(() {
                              _isRecording = true;
                              _audioFilePath = filePath;
                            });
                          }
                        }
                      }
                    : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey[300];
                    }
                    return magenta;
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey[600];
                    }
                    return Colors.white;
                  }),
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(vertical: 12),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(
                  _isRecording
                      ? Provider.of<LanguageService>(context).t('stop')
                      : Provider.of<LanguageService>(context).t('record'),
                ),
              ),

              if (_audioFilePath != null && !_isRecording)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.audiotrack, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Provider.of<LanguageService>(
                            context,
                          ).t('recording_ready'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          // delete recording
                          try {
                            if (_audioFilePath != null) {
                              await deleteFileIfExists(_audioFilePath!);
                            }
                          } catch (_) {}
                          setState(() => _audioFilePath = null);
                        },
                        child: Text(
                          Provider.of<LanguageService>(context).t('delete'),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'confirmed': true,
                          'method': _selectedMethod,
                          'attachAudio': _attachAudio,
                          'audioPath': _attachAudio ? _audioFilePath : null,
                        });
                      },
                      icon: Icon(Icons.send),
                      label: Text(
                        Provider.of<LanguageService>(context).t('send_alert'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: magenta,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop({'confirmed': false}),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: magenta),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 18,
                      ),
                    ),
                    child: Text(
                      Provider.of<LanguageService>(context).t('cancel'),
                      style: TextStyle(color: magenta),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      if (_isRecording) {
        _recorder.stop();
      }
      _recorder.dispose();
    } catch (_) {}
    super.dispose();
  }
}
