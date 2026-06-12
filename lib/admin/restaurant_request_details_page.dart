import 'package:flutter/material.dart';
import '../services/admin_restaurant_service.dart';

class RestaurantRequestDetailsPage extends StatefulWidget {
  const RestaurantRequestDetailsPage({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  State<RestaurantRequestDetailsPage> createState() => _RestaurantRequestDetailsPageState();
}

class _RestaurantRequestDetailsPageState extends State<RestaurantRequestDetailsPage> {
  final AdminRestaurantService _service = AdminRestaurantService();
  bool _busy = false;

  Future<void> _approve(RestaurantAdminRecord record) async {
    final confirmed = await _confirm(
      title: 'Approve restaurant?',
      message: 'This will activate ${record.restaurantName} and allow the restaurant dashboard to open.',
      confirmText: 'Approve',
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _service.approveRestaurant(record.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant approved successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(RestaurantAdminRecord record) async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      await _service.rejectRestaurant(record.id, reason.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant rejected. Reapply lock set for 48 hours.')),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmText)),
        ],
      ),
    );
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Restaurant Request'),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Rejection reason',
              hintText: 'Example: Documents are incomplete or delivery area details are invalid.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context, reason);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action failed: $e')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RestaurantAdminRecord?>(
      stream: _service.watchRestaurant(widget.restaurantId),
      builder: (context, snapshot) {
        final record = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Restaurant Request Details', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          bottomNavigationBar: record == null
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy || record.normalizedStatus == 'approved'
                                ? null
                                : () => _reject(record),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Reject with Reason'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy || record.normalizedStatus == 'approved'
                                ? null
                                : () => _approve(record),
                            icon: _busy
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: const Text('Approve Restaurant'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : record == null
                  ? const Center(child: Text('Restaurant request not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1050),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeaderCard(record: record),
                              const SizedBox(height: 18),
                              _DetailsGrid(record: record),
                              const SizedBox(height: 18),
                              _PlanAndPaymentCard(record: record),
                              const SizedBox(height: 18),
                              _RawStatusCard(record: record),
                            ],
                          ),
                        ),
                      ),
                    ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.record});

  final RestaurantAdminRecord record;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.normalizedStatus) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => const Color(0xFFFF6A00),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(Icons.storefront_rounded, color: color, size: 34),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.restaurantName,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '${record.ownerName} • ${record.city}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(record.normalizedStatus.toUpperCase()),
            backgroundColor: color.withOpacity(0.10),
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
            side: BorderSide.none,
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.record});

  final RestaurantAdminRecord record;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Restaurant Name', record.restaurantName),
      ('Owner Name', record.ownerName),
      ('Phone', record.phone),
      ('Business Email', record.businessEmail),
      ('City', record.city),
      ('Full Address', record.address),
      ('Google Map Link', record.mapLink),
      ('Food Type', record.foodType),
      ('Service Area', record.serviceAreaLabel),
      ('Delivery Radius', '${record.deliveryRadiusKm} KM'),
      ('Delivery Enabled', record.delivery ? 'Yes' : 'No'),
      ('Pickup Enabled', record.pickup ? 'Yes' : 'No'),
      ('Dine-In Enabled', record.dineIn ? 'Yes' : 'No'),
      ('Created At', record.createdAtText),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: items
              .map(
                (item) => SizedBox(
                  width: 320,
                  child: _InfoTile(label: item.$1, value: item.$2),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _PlanAndPaymentCard extends StatelessWidget {
  const _PlanAndPaymentCard({required this.record});

  final RestaurantAdminRecord record;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Trial Plan', record.trialEnabled ? 'Enabled' : 'Disabled'),
      ('Weekly Plan', record.weeklyEnabled ? 'Enabled' : 'Disabled'),
      ('Monthly Plan', record.monthlyEnabled ? 'Enabled' : 'Disabled'),
      ('UPI ID', record.upiId),
      ('QR Code URL', record.qrCodeUrl),
      ('Account Holder', record.accountHolder),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plan & Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: 320,
                      child: _InfoTile(label: item.$1, value: item.$2),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawStatusCard extends StatelessWidget {
  const _RawStatusCard({required this.record});

  final RestaurantAdminRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _InfoTile(label: 'Current Status', value: record.status),
            if (record.rejectionReason.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoTile(label: 'Rejection Reason', value: record.rejectionReason),
            ],
            if (record.reapplyAfterText.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoTile(label: 'Reapply Available After', value: record.reapplyAfterText),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          SelectableText(
            displayValue,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
