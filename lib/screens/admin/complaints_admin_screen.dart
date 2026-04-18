import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/complaint_service.dart';

class ComplaintsAdminScreen extends StatefulWidget {
  const ComplaintsAdminScreen({super.key});

  @override
  _ComplaintsAdminScreenState createState() => _ComplaintsAdminScreenState();
}

class _ComplaintsAdminScreenState extends State<ComplaintsAdminScreen> {
  @override
  Widget build(BuildContext context) {
    final service = context.read<ComplaintService>();

    return Scaffold(
      appBar: AppBar(title: Text('Admin - Complaints')),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.streamComplaints(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('No complaints found'));
          }

          return ListView.separated(
            padding: EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final subject = data['subject'] ?? '—';
              final desc = data['description'] ?? '';
              final status = data['status'] ?? 'open';
              final email = data['userEmail'] ?? 'unknown';
              final createdAt = data['createdAt_local'] ?? '';

              return Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subject,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 8),
                          Chip(label: Text(status)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(desc),
                      SizedBox(height: 8),
                      Text('De: $email'),
                      SizedBox(height: 8),
                      Text('Créé: $createdAt'),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _changeStatus(d.id, 'open'),
                            child: Text('Open'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _changeStatus(d.id, 'in_progress'),
                            child: Text('In progress'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _changeStatus(d.id, 'closed'),
                            child: Text('Close'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.visibility),
                            tooltip: 'View details',
                            onPressed: () => _showComplaintDetails(data),
                          ),
                          IconButton(
                            icon: Icon(Icons.reply),
                            tooltip: 'Reply',
                            onPressed: () => _showResponseDialog(
                              d.id,
                              data['adminResponse'] ?? '',
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _showDeleteConfirmation(d.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _changeStatus(String docId, String status) async {
    final service = context.read<ComplaintService>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await service.updateComplaintStatus(docId, status);
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text('Status updated')));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(service.lastError ?? 'Error')),
      );
    }
  }

  void _showResponseDialog(String docId, String currentResponse) {
    final controller = TextEditingController(text: currentResponse);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reply to complaint'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = context.read<ComplaintService>();
              final ok = await service.addResponse(
                docId,
                controller.text.trim(),
              );
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              if (ok) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Response saved')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(service.lastError ?? 'Error')),
                );
              }
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['subject'] ?? 'Complaint details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subject: ${data['subject'] ?? '—'}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Description:'),
              Text(data['description'] ?? '—'),
              SizedBox(height: 8),
              Text('Email: ${data['userEmail'] ?? '—'}'),
              SizedBox(height: 8),
              Text('Status: ${data['status'] ?? '—'}'),
              SizedBox(height: 8),
              Text('Created on: ${data['createdAt_local'] ?? '—'}'),
              if (data['adminResponse'] != null &&
                  data['adminResponse'].isNotEmpty) ...[
                SizedBox(height: 8),
                Text('Admin response:'),
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.blue.shade50,
                  child: Text(data['adminResponse']),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm deletion'),
        content: Text(
          'Are you sure you want to delete this complaint? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close confirmation dialog
              await _deleteComplaint(docId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComplaint(String docId) async {
    final service = context.read<ComplaintService>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await service.deleteComplaint(docId);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Complaint deleted successfully')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(service.lastError ?? 'Error deleting complaint'),
        ),
      );
    }
  }
}
