import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/models/emergency_contact.dart';
import 'package:protectme/services/language_service.dart';
import 'package:protectme/screens/contacts/add_contact_screen.dart';
import 'package:protectme/services/contact_service.dart';
import 'package:protectme/widgets/contact_item.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser le service au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactService = Provider.of<ContactService>(
        context,
        listen: false,
      );
      contactService.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactService>(
      builder: (context, contactService, child) {
        final contacts = contactService.contacts;
        final isLoading = contactService.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text('My_Contacts'),
            actions: [
              if (contacts.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () => contactService.loadContacts(),
                  tooltip: 'Refresh',
                ),
            ],
          ),
          body: isLoading
              ? Center(child: CircularProgressIndicator())
              : contacts.isEmpty
              ? _buildEmptyState()
              : _buildContactsList(contacts, contactService),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addNewContact(context),
            child: Icon(Icons.add),
            tooltip: 'Add_Contact',
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            Provider.of<LanguageService>(context).t('no_contacts'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 10),
          Text(
            Provider.of<LanguageService>(context).t('add_first_contact'),
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _addNewContact(context),
            icon: Icon(Icons.add),
            label: Text(Provider.of<LanguageService>(context).t('add_contact')),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(
    List<EmergencyContact> contacts,
    ContactService contactService,
  ) {
    return RefreshIndicator(
      onRefresh: () => contactService.loadContacts(),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return Dismissible(
            key: Key(contact.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    Provider.of<LanguageService>(context).t('delete_contact'),
                  ),
                  content: Text(
                    Provider.of<LanguageService>(context).t('confirm_delete'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        Provider.of<LanguageService>(context).t('cancel'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        Provider.of<LanguageService>(context).t('delete'),
                      ),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) async {
              await contactService.deleteContact(contact.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    Provider.of<LanguageService>(context).t('contact_deleted'),
                  ),
                ),
              );
            },
            child: Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ContactItem(
                name: contact.name,
                phone: contact.phone,
                email: contact.email,
                relationship: contact.relationship,
                priority: contact.priority,
                receivesSMS: contact.receivesSMS,
                receivesCall: contact.receivesCall,
                onTap: () => _editContact(context, contact),
                onCall: () => _callContact(contact.phone),
                onSMS: () => _sendSMS(contact.phone),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addNewContact(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddContactScreen()),
    );

    if (result == true) {
      // Rafraîchir si nécessaire
      final contactService = Provider.of<ContactService>(
        context,
        listen: false,
      );
      contactService.loadContacts();
    }
  }

  Future<void> _editContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactScreen(contactToEdit: contact),
      ),
    );

    if (result == true) {
      // Rafraîchir si nécessaire
      final contactService = Provider.of<ContactService>(
        context,
        listen: false,
      );
      contactService.loadContacts();
    }
  }

  void _callContact(String phone) {
    // Implémenter l'appel téléphonique
    print('Appeler: $phone');
  }

  void _sendSMS(String phone) {
    // Implémenter l'envoi de SMS
    print('Envoyer SMS à: $phone');
  }
}
