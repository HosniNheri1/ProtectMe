import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/user_service.dart';
import 'package:protectme/models/firestore_user.dart';

class AdminGate extends StatefulWidget {
  final Widget child;
  const AdminGate({required this.child, super.key});

  @override
  _AdminGateState createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  bool _loading = true;
  FirestoreUser? _user;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final userService = context.read<UserService>();
    final user = await userService.getCurrentUser();
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return Scaffold(body: Center(child: Text('Utilisateur introuvable')));
    }
    if (_user!.role != 'admin') {
      return Scaffold(
        body: Center(child: Text('Accès réservé aux administrateurs')),
      );
    }
    return widget.child;
  }
}
