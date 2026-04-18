import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/complaint_service.dart';
import 'package:protectme/services/user_service.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  _MyComplaintsScreenState createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userService = context.read<UserService>();
    final user = await userService.getCurrentUser();
    print('🔍 MyComplaintsScreen - User ID: ${user?.id}');
    print('🔍 MyComplaintsScreen - User Email: ${user?.email}');
    setState(() => _userId = user?.id);
  }

  @override
  Widget build(BuildContext context) {
    final complaintService = context.read<ComplaintService>();

    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Mes réclamations')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Mes réclamations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: complaintService.streamUserComplaints(_userId!),
        builder: (context, snapshot) {
          print(
            '🔍 MyComplaintsScreen - StreamBuilder state: ${snapshot.connectionState}',
          );

          if (snapshot.hasError) {
            print('❌ MyComplaintsScreen - Error: ${snapshot.error}');
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            print('🔄 MyComplaintsScreen - Loading...');
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          print('📋 MyComplaintsScreen - Found ${docs.length} complaints');

          if (docs.isEmpty) {
            print('📭 MyComplaintsScreen - No complaints found');
            return Center(child: Text('Aucune réclamation trouvée'));
          }

          return ListView.separated(
            padding: EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final subject = data['subject'] ?? '—';
              final status = data['status'] ?? 'open';
              final created = data['createdAt_local'] ?? '';
              final hasNewResponse =
                  data['adminResponse'] != null &&
                  data['adminResponse'].isNotEmpty &&
                  !(data['responseViewed'] ?? false);

              return ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(subject)),
                    if (hasNewResponse) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'NOUVEAU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text('Status: $status\n$created'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer',
                      onPressed: () => _confirmDelete(d.id),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
                tileColor: hasNewResponse ? Colors.blue.shade50 : null,
                onTap: () => _showDetails(d.id, data),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetails(String id, Map<String, dynamic> data) {
    // Marquer la réponse comme vue si elle existe
    if (data['adminResponse'] != null && data['adminResponse'].isNotEmpty) {
      _markResponseAsViewed(id);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['subject'] ?? 'Détails'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description:\n${data['description'] ?? ''}'),
              SizedBox(height: 8),
              Text('Status: ${data['status'] ?? ''}'),
              SizedBox(height: 8),
              Text('Créé le: ${data['createdAt_local'] ?? ''}'),
              if (data['adminResponse'] != null &&
                  data['adminResponse'].isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Réponse de l\'administrateur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(data['adminResponse']),
                      if (data['respondedAt'] != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Répondu le: ${_formatTimestamp(data['respondedAt'])}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      return timestamp.toString();
    } catch (e) {
      return '';
    }
  }

  Future<void> _markResponseAsViewed(String complaintId) async {
    final complaintService = context.read<ComplaintService>();
    await complaintService.markResponseAsViewed(complaintId);
  }

  Future<void> _confirmDelete(String complaintId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cette réclamation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteComplaint(complaintId);
    }
  }

  Future<void> _deleteComplaint(String complaintId) async {
    final complaintService = context.read<ComplaintService>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await complaintService.deleteComplaint(complaintId);
    if (success) {
      messenger.showSnackBar(SnackBar(content: Text('Réclamation supprimée')));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            complaintService.lastError ?? 'Erreur lors de la suppression',
          ),
        ),
      );
    }
  }
}
