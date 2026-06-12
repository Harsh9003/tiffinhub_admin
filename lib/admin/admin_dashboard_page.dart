import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'admin_profile_edit_requests_page.dart';
import 'restaurant_requests_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        title: const Text('TiffinHub Admin', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: logout)],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(18),
        crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 4 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.35,
        children: [
          _AdminCard(
            title: 'Restaurant Requests',
            subtitle: 'Approve or reject new restaurants',
            icon: Icons.storefront_rounded,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RestaurantRequestsPage()));
            },
          ),
          _AdminCard(
            title: 'Edit Requests',
            subtitle: 'Review restaurant profile changes',
            icon: Icons.edit_document,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileEditRequestsPage()));
            },
          ),
          const _AdminCard(title: 'Payments', subtitle: 'Mismatch and verification', icon: Icons.payments_rounded),
          const _AdminCard(title: 'Complaints', subtitle: 'Customer and restaurant issues', icon: Icons.support_agent_rounded),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.title, required this.subtitle, required this.icon, this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD7BF)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: const Color(0xFFFFEFE4), child: Icon(icon, color: const Color(0xFFFF6A00))),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
