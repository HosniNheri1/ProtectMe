import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:protectme/models/alert.dart';
import 'package:protectme/services/alert_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alert_History'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<AlertService>(
        builder: (context, alertService, child) {
          final alerts = alertService.alerts;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No alerts',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Alerts will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _buildAlertCard(context, alert);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Alert alert) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getAlertIcon(alert.type),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAlertTitle(alert.type),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDateTime(alert.timestamp),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _getStatusChip(alert.status),
              ],
            ),
            if (alert.message != null) ...[
              const SizedBox(height: 12),
              Text(alert.message!, style: TextStyle(fontSize: 14)),
            ],
            // Show the map only if coordinates are available
            if (alert.latitude != null && alert.longitude != null) ...[
              const SizedBox(height: 8),
              _buildMapWidget(alert),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ] else ...[
              // Show a message if location is not available
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_off, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Location not available',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (alert.contactedNumbers.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Contacts alerted: ${alert.contactedNumbers.length}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            if (alert.biometricConfirmed) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.fingerprint, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Confirmed by biometrics',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getAlertIcon(AlertType type) {
    IconData icon;
    Color color;

    switch (type) {
      case AlertType.manual:
        icon = Icons.touch_app;
        color = Colors.blue;
        break;
      case AlertType.inactivity:
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case AlertType.fall:
        icon = Icons.warning;
        color = Colors.red;
        break;
      case AlertType.anomaly:
        icon = Icons.error;
        color = Colors.purple;
        break;
      case AlertType.location:
        icon = Icons.location_off;
        color = Colors.teal;
        break;
      case AlertType.health:
        icon = Icons.health_and_safety;
        color = Colors.green;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  String _getAlertTitle(AlertType type) {
    switch (type) {
      case AlertType.manual:
        return 'Manual alert';
      case AlertType.inactivity:
        return 'Inactivity detected';
      case AlertType.fall:
        return 'Fall detected';
      case AlertType.anomaly:
        return 'Anomaly detected';
      case AlertType.location:
        return 'Location issue';
      case AlertType.health:
        return 'Health issue';
    }
  }

  Widget _getStatusChip(AlertStatus status) {
    String label;
    Color color;

    switch (status) {
      case AlertStatus.pending:
        label = 'Pending';
        color = Colors.orange;
        break;
      case AlertStatus.confirmed:
        label = 'Confirmed';
        color = Colors.green;
        break;
      case AlertStatus.cancelled:
        label = 'Cancelled';
        color = Colors.grey;
        break;
      case AlertStatus.escalated:
        label = 'Escalated';
        color = Colors.red;
        break;
      case AlertStatus.resolved:
        label = 'Resolved';
        color = Colors.blue;
        break;
    }

    return Chip(
      label: Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildMapWidget(Alert alert) {
    if (alert.latitude == null || alert.longitude == null) {
      return const SizedBox.shrink();
    }

    final mapsUrl =
        'https://maps.google.com/maps?q=${alert.latitude},${alert.longitude}&z=17';

    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(mapsUrl))) {
          await launchUrl(Uri.parse(mapsUrl));
        }
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 48, color: Colors.blue),
                SizedBox(height: 8),
                Text(
                  'View location',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to open Google Maps',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
