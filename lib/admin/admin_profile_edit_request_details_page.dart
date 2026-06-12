import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminProfileEditRequestDetailsPage extends StatefulWidget {
  const AdminProfileEditRequestDetailsPage({super.key, required this.requestId});
  final String requestId;

  @override
  State<AdminProfileEditRequestDetailsPage> createState() => _AdminProfileEditRequestDetailsPageState();
}

class _AdminProfileEditRequestDetailsPageState extends State<AdminProfileEditRequestDetailsPage> {
  static const Color _bg = Color(0xFFFFFBF7);
  static const Color _orange = Color(0xFFFF6A00);
  bool _saving = false;

  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    final restaurantId = (request['restaurantId'] ?? '').toString();
    final proposedData = (request['proposedData'] as Map?)?.cast<String, dynamic>() ?? {};
    if (restaurantId.isEmpty || proposedData.isEmpty) return;

    setState(() => _saving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final restaurantRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
      final requestRef = FirebaseFirestore.instance.collection('restaurant_profile_edit_requests').doc(widget.requestId);

      batch.update(restaurantRef, {
        ...proposedData,
        'profileUpdateStatus': 'approved',
        'lastProfileUpdateApprovedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(requestRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant profile changes approved.')));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reject() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reject reason is required.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('restaurant_profile_edit_requests').doc(widget.requestId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant profile changes rejected.')));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Edit Request Review', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _reject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size.fromHeight(52)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () async {
                    final snap = await FirebaseFirestore.instance.collection('restaurant_profile_edit_requests').doc(widget.requestId).get();
                    if (snap.exists) await _approve(snap.data()!);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('restaurant_profile_edit_requests').doc(widget.requestId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() ?? {};
          final current = (data['currentData'] as Map?)?.cast<String, dynamic>() ?? {};
          final proposed = (data['proposedData'] as Map?)?.cast<String, dynamic>() ?? {};
          final keys = {...current.keys, ...proposed.keys}.toList()..sort();

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 760;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFED7AA))),
                    child: const Text(
                      'Compare old restaurant details with requested new details. Approve only if the information is valid.',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF9A3412)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _CompareCard(title: 'Current / Live Details', data: current, keys: keys)),
                            const SizedBox(width: 14),
                            Expanded(child: _CompareCard(title: 'Requested / New Details', data: proposed, keys: keys, highlight: true)),
                          ],
                        )
                      : Column(
                          children: [
                            _CompareCard(title: 'Current / Live Details', data: current, keys: keys),
                            const SizedBox(height: 14),
                            _CompareCard(title: 'Requested / New Details', data: proposed, keys: keys, highlight: true),
                          ],
                        ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _reason,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reject Reason',
                      hintText: 'Required only if rejecting this edit request',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.title, required this.data, required this.keys, this.highlight = false});
  final String title;
  final Map<String, dynamic> data;
  final List<String> keys;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: highlight ? const Color(0xFFFFC69F) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          ...keys.map((key) {
            final value = data[key];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 150, child: Text(key, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280), fontSize: 12))),
                  Expanded(child: Text(_format(value), style: const TextStyle(fontWeight: FontWeight.w800))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _format(dynamic value) {
    if (value == null) return '-';
    if (value is List) return value.join(', ');
    if (value is Map) return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return value.toString();
  }
}
