import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/auth_service.dart';
import 'package:protectme/services/user_service.dart';
import 'package:protectme/services/language_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final userService = context.read<UserService>();
    final lang = Provider.of<LanguageService>(context);

    return Drawer(
      child: FutureBuilder(
        future: userService.getCurrentUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'ProtectMe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text(lang.t('home')),
                onTap: () => Navigator.pushNamed(context, '/home'),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(lang.t('profile')),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              ListTile(
                leading: Icon(Icons.contacts),
                title: Text(lang.t('contacts')),
                onTap: () => Navigator.pushNamed(context, '/contacts'),
              ),
              if (user?.role != 'admin')
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text(lang.t('alerts')),
                  onTap: () => Navigator.pushNamed(context, '/alerts'),
                ),
              // 'alert_history' removed from drawer per request
              if (user?.role != 'user')
                ListTile(
                  leading: Icon(Icons.rule),
                  title: Text(lang.t('consulter_reclamation')),
                  onTap: () => Navigator.pushNamed(
                    context,
                    user?.role == 'admin' ? '/admin/complaints' : '/complaints',
                  ),
                ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text(lang.t('settings')),
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              Divider(),
              if (user?.role == 'admin')
                ListTile(
                  leading: Icon(Icons.group),
                  title: Text('User_Roles'),
                  onTap: () => Navigator.pushNamed(context, '/admin/users'),
                ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text(lang.t('logout')),
                onTap: () async {
                  await auth.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/auth',
                    (r) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
