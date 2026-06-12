import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_profile_edit_request_details_page.dart';

class AdminProfileEditRequestsPage extends StatelessWidget {
  const AdminProfileEditRequestsPage({super.key});

  static const Color _bg = Color(0xFFFFFBF7);
  static const Color _orange = Color(0xFFFF6A00);
  static const Color _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Restaurant Edit Requests', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('restaurant_profile_edit_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No pending restaurant edit requests.', style: TextStyle(fontWeight: FontWeight.w800, color: _muted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final proposed = (data['proposedData'] as Map?)?.cast<String, dynamic>() ?? {};
              final restaurantName = (data['restaurantName'] ?? proposed['restaurantName'] ?? 'Restaurant').toString();
              final ownerEmail = (data['ownerEmail'] ?? '').toString();
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminProfileEditRequestDetailsPage(requestId: doc.id)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFD7BF)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFEFE4),
                        child: Icon(Icons.edit_document, color: _orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(restaurantName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 3),
                            Text(ownerEmail.isEmpty ? 'Profile change request' : ownerEmail, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
