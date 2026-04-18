import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/complaint_service.dart';
import 'package:protectme/screens/reclamation/my_complaints_screen.dart';

class ReclamationScreen extends StatefulWidget {
  const ReclamationScreen({super.key});

  @override
  _ReclamationScreenState createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complaint')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'If you want to file a complaint, describe the issue below. We will get back to you.',
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.history),
              label: Text('View my complaints'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyComplaintsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 6,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please describe your complaint';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text('Submit complaint'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final service = context.read<ComplaintService>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await service.submitComplaint(
      subject: _subjectController.text.trim(),
      description: _descController.text.trim(),
    );

    if (success) {
      final id = service.lastDocId ?? 'unknown';
      messenger.showSnackBar(
        SnackBar(content: Text('Complaint submitted. ID: $id')),
      );
      print('Debug: complaint created with id=$id');
      Navigator.of(context).pop();
    } else {
      final err = service.lastError ?? 'Error sending. Try again.';
      messenger.showSnackBar(SnackBar(content: Text(err)));
      print('Debug: submitComplaint failed: $err');
    }

    setState(() => _isLoading = false);
  }
}
