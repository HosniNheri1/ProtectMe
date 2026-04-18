import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/language_service.dart';

class ContactItem extends StatelessWidget {
  final String name;
  final String phone;
  final String? email;
  final String? relationship;
  final int priority;
  final bool receivesSMS;
  final bool receivesCall;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onSMS;

  const ContactItem({
    super.key,
    required this.name,
    required this.phone,
    this.email,
    this.relationship,
    this.priority = 1,
    this.receivesSMS = true,
    this.receivesCall = true,
    required this.onTap,
    this.onCall,
    this.onSMS,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildPriorityIndicator(),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(phone),
          if (relationship != null && relationship!.isNotEmpty)
            Text(
              '${Provider.of<LanguageService>(context).t('relation')} $relationship',
              style: TextStyle(fontSize: 12),
            ),
          if (email != null && email!.isNotEmpty)
            Text(
              '${Provider.of<LanguageService>(context).t('email_label')} $email',
              style: TextStyle(fontSize: 12),
            ),
          _buildNotificationIcons(context),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onCall != null)
            IconButton(
              icon: Icon(Icons.call, color: Colors.green),
              onPressed: onCall,
              tooltip: Provider.of<LanguageService>(context).t('call'),
            ),
          if (onSMS != null)
            IconButton(
              icon: Icon(Icons.sms, color: Colors.blue),
              onPressed: onSMS,
              tooltip: Provider.of<LanguageService>(context).t('send_sms'),
            ),
          Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildPriorityIndicator() {
    Color color;
    switch (priority) {
      case 1:
        color = Colors.red;
        break;
      case 2:
        color = Colors.orange;
        break;
      case 3:
        color = Colors.yellow;
        break;
      default:
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        priority.toString(),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNotificationIcons(BuildContext context) {
    return Row(
      children: [
        if (receivesSMS) Icon(Icons.sms, size: 14, color: Colors.green),
        if (receivesSMS) SizedBox(width: 4),
        if (receivesCall) Icon(Icons.call, size: 14, color: Colors.blue),
        if (receivesCall) SizedBox(width: 4),
        Text(
          '${Provider.of<LanguageService>(context).t('priority_label')} $priority',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
