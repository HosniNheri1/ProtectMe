import 'package:flutter/material.dart';

class MessageMethodSelector extends StatefulWidget {
  final ValueChanged<String> onMethodSelected;
  final bool isWeb;

  const MessageMethodSelector({
    super.key,
    required this.onMethodSelected,
    required this.isWeb,
  });

  @override
  _MessageMethodSelectorState createState() => _MessageMethodSelectorState();
}

class _MessageMethodSelectorState extends State<MessageMethodSelector> {
  String _selectedMethod = 'whatsapp';

  @override
  void initState() {
    super.initState();
    // On web, default to WhatsApp
    _selectedMethod = widget.isWeb ? 'whatsapp' : 'sms';
    widget.onMethodSelected(_selectedMethod);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sending method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // WhatsApp Option
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.message, color: Colors.green),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Recommended on web',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              value: 'whatsapp',
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() => _selectedMethod = value!);
                widget.onMethodSelected(value!);
              },
            ),

            // SMS Option (seulement sur mobile)
            if (!widget.isWeb) ...[
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.sms, color: Colors.blue),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'For phones without WhatsApp',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                value: 'sms',
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                  widget.onMethodSelected(value!);
                },
              ),
            ],

            // Information
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isWeb
                          ? 'On web, WhatsApp will open in a new tab'
                          : 'The system will use the selected method',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
