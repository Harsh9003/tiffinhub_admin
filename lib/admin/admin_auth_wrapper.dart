import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'admin_login_page.dart';

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

  static const Set<String> allowedAdminEmails = {
    // Change/add your real admin Gmail here if needed.
    'harshandersingh@gmail.com',
    'dailykharcha.app@gmail.com',
  };

  bool _isAllowedAdmin(User user) {
    final email = user.email?.trim().toLowerCase();
    return email != null && allowedAdminEmails.contains(email);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AdminLoadingScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          return const AdminLoginPage();
        }

        if (!_isAllowedAdmin(user)) {
          return _UnauthorizedAdminScreen(email: user.email ?? 'Unknown email');
        }

        return const AdminDashboardPage();
      },
    );
  }
}

class _AdminLoadingScreen extends StatelessWidget {
  const _AdminLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _UnauthorizedAdminScreen extends StatelessWidget {
  const _UnauthorizedAdminScreen({required this.email});

  final String email;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.all(24),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 54, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Unauthorized Admin Account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This Google account is not allowed to access the TiffinHub Admin Panel.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
