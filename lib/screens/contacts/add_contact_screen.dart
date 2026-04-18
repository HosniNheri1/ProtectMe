import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/models/emergency_contact.dart';
import 'package:protectme/services/language_service.dart';
import 'package:protectme/services/contact_service.dart';
import 'package:protectme/utils/error_handler.dart';

class AddContactScreen extends StatefulWidget {
  final EmergencyContact? contactToEdit;

  const AddContactScreen({super.key, this.contactToEdit});

  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationshipController = TextEditingController();

  bool _receivesSMS = true;
  bool _receivesCall = true;
  bool _isSaving = false;
  int _priority = 1;

  @override
  void initState() {
    super.initState();

    // If editing a contact, pre-fill the fields
    if (widget.contactToEdit != null) {
      final contact = widget.contactToEdit!;
      _nameController.text = contact.name;
      _phoneController.text = contact.phone;
      _emailController.text = contact.email ?? '';
      _relationshipController.text = contact.relationship ?? '';
      _receivesSMS = contact.receivesSMS;
      _receivesCall = contact.receivesCall;
      _priority = contact.priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contactToEdit != null
              ? 'Edit_Contact'
              : Provider.of<LanguageService>(context).t('add_contact'),
        ),
        actions: [
          if (widget.contactToEdit != null) ...[
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteContact,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Section informations personnelles
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name is required';
                          }
                          if (value.length < 2) {
                            return 'Name must contain at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          hintText: 'E.g.: 0612345678',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          // Validation basique du numéro
                          if (value.length < 8) {
                            return 'Number too short';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          hintText: 'contact@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _relationshipController,
                        decoration: InputDecoration(
                          labelText: 'Relationship',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                          hintText: 'E.g.: Family, Friend, Doctor...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Notification options section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),

                      SwitchListTile(
                        title: Text('Receive alert SMS'),
                        subtitle: Text('Send an SMS in case of emergency'),
                        value: _receivesSMS,
                        onChanged: (value) =>
                            setState(() => _receivesSMS = value),
                      ),

                      SwitchListTile(
                        title: Text('Receive alert calls'),
                        subtitle: Text('Call in case of emergency'),
                        value: _receivesCall,
                        onChanged: (value) =>
                            setState(() => _receivesCall = value),
                      ),

                      ListTile(
                        title: Text(
                          Provider.of<LanguageService>(context).t('priority'),
                        ),
                        subtitle: Text(
                          Provider.of<LanguageService>(context).t('more'),
                        ),
                        trailing: DropdownButton<int>(
                          value: _priority,
                          items: [1, 2, 3, 4, 5].map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Text('Priority $priority'),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _priority = value!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Informations importantes
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This contact will receive emergency alerts with your location. '
                          'Make sure you have their consent.',
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Bouton de sauvegarde
              if (_isSaving)
                CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _saveContact,
                  icon: Icon(Icons.save),
                  label: Text(
                    widget.contactToEdit != null ? 'Update' : 'Add contact',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    final contactService = Provider.of<ContactService>(context, listen: false);

    // Vérifier si le numéro existe déjà (sauf pour l'édition)
    if (widget.contactToEdit == null ||
        widget.contactToEdit!.phone != _phoneController.text) {
      if (contactService.contactExists(_phoneController.text)) {
        ErrorHandler.showError(
          context,
          'This number is already in your contacts',
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final contact = EmergencyContact(
        id: widget.contactToEdit?.id ?? '', // Généré par Firestore si nouveau
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        relationship: _relationshipController.text.trim().isEmpty
            ? null
            : _relationshipController.text.trim(),
        priority: _priority,
        receivesSMS: _receivesSMS,
        receivesCall: _receivesCall,
        isActive: true,
        addedDate: DateTime.now(),
      );

      bool success;
      if (widget.contactToEdit != null) {
        success = await contactService.updateContact(
          widget.contactToEdit!.id,
          contact,
        );
      } else {
        success = await contactService.addContact(contact);
      }

      if (success) {
        ErrorHandler.showSuccess(
          context,
          widget.contactToEdit != null
              ? 'Contact updated successfully'
              : 'Contact added successfully',
        );
        Navigator.pop(context);
      } else {
        ErrorHandler.showError(context, 'Error saving contact');
      }
    } catch (e) {
      ErrorHandler.showError(context, 'Error: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteContact() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<LanguageService>(context).t('delete_contact')),
        content: Text(
          Provider.of<LanguageService>(context).t('confirm_delete'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Provider.of<LanguageService>(context).t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(Provider.of<LanguageService>(context).t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);

      final contactService = Provider.of<ContactService>(
        context,
        listen: false,
      );
      final success = await contactService.deleteContact(
        widget.contactToEdit!.id,
      );

      if (success) {
        ErrorHandler.showSuccess(context, 'Contact deleted successfully');
        Navigator.pop(context);
      } else {
        ErrorHandler.showError(context, 'Error deleting contact');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }
}
