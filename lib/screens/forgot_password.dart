import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:protectme/services/auth_service.dart';
import 'package:protectme/services/language_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageService>();
    return Scaffold(
      appBar: AppBar(title: Text('Réinitialiser le mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              'Entrez l\'email associé à votre compte. Nous enverrons un lien pour réinitialiser le mot de passe.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: lang.t('email'),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text('Envoyer le lien'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);

    final email = _emailController.text.trim();

    // Attempt to send the reset email directly. This will work even when
    // the user exists in Firebase Auth but doesn't have a Firestore profile.
    final success = await auth.sendPasswordResetEmail(email);

    if (success) {
      print('Debug: sendPasswordResetEmail succeeded for $email');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Email de réinitialisation envoyé. Vérifiez votre boîte de réception.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      print('Debug: sendPasswordResetEmail failed: ${auth.lastAuthError}');
      final err = auth.lastAuthError ?? 'Erreur lors de l\'envoi de l\'email';
      String message = err;
      if (err.toLowerCase().contains('user-not-found') ||
          err.toLowerCase().contains('no user record') ||
          err.toLowerCase().contains('not-found')) {
        message = 'Aucun compte trouvé pour cet email.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    setState(() => _isLoading = false);
  }
}
