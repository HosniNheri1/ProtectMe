import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/user_service.dart';
import 'package:protectme/models/firestore_user.dart';
import 'package:protectme/services/language_service.dart';

class UserRolesScreen extends StatefulWidget {
  const UserRolesScreen({super.key});

  @override
  State<UserRolesScreen> createState() => _UserRolesScreenState();
}

class _UserRolesScreenState extends State<UserRolesScreen> {
  bool _isLoading = true;
  List<FirestoreUser> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final svc = Provider.of<UserService>(context, listen: false);
    final users = await svc.getAllUsers(limit: 200);
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _toggleAdmin(FirestoreUser user) async {
    final svc = Provider.of<UserService>(context, listen: false);
    final newRole = (user.role == 'admin') ? 'user' : 'admin';
    final ok = await svc.setUserRole(user.id, newRole);
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('${user.name} set to $newRole')),
      );
      await _loadUsers();
    } else {
      messenger.showSnackBar(SnackBar(content: Text('Error updating role')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<LanguageService>(context).t('manage_roles')),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.separated(
                padding: EdgeInsets.all(12),
                itemCount: _users.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, i) {
                  final u = _users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(u.name),
                    subtitle: Text(u.email),
                    trailing: ElevatedButton(
                      child: Text(u.role == 'admin' ? 'Demote' : 'Promote'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: u.role == 'admin'
                            ? Colors.red
                            : Colors.green,
                      ),
                      onPressed: () => _toggleAdmin(u),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
