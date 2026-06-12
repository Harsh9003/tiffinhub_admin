import 'package:flutter/material.dart';

import '../services/admin_restaurant_service.dart';
import 'restaurant_request_details_page.dart';

class RestaurantRequestsPage extends StatefulWidget {
  const RestaurantRequestsPage({super.key});

  @override
  State<RestaurantRequestsPage> createState() => _RestaurantRequestsPageState();
}

class _RestaurantRequestsPageState extends State<RestaurantRequestsPage> {
  final AdminRestaurantService _service = AdminRestaurantService();
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Requests', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<List<RestaurantAdminRecord>>(
        stream: _service.watchRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          final records = _filter == 'all'
              ? all
              : all.where((r) => r.normalizedStatus == _filter).toList();

          return Padding(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterChips(
                      selected: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                      allCount: all.length,
                      pendingCount: all.where((r) => r.normalizedStatus == 'pending').length,
                      approvedCount: all.where((r) => r.normalizedStatus == 'approved').length,
                      rejectedCount: all.where((r) => r.normalizedStatus == 'rejected').length,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: records.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              itemCount: records.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final record = records[index];
                                return _RestaurantRequestCard(
                                  record: record,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RestaurantRequestDetailsPage(
                                          restaurantId: record.id,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onChanged,
    required this.allCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final int allCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('pending', 'Pending', pendingCount),
      ('approved', 'Approved', approvedCount),
      ('rejected', 'Rejected', rejectedCount),
      ('all', 'All', allCount),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final filter in filters)
          ChoiceChip(
            selected: selected == filter.$1,
            label: Text('${filter.$2} (${filter.$3})'),
            onSelected: (_) => onChanged(filter.$1),
          ),
      ],
    );
  }
}

class _RestaurantRequestCard extends StatelessWidget {
  const _RestaurantRequestCard({
    required this.record,
    required this.onTap,
  });

  final RestaurantAdminRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (record.normalizedStatus) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => const Color(0xFFFF6A00),
    };

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(Icons.storefront_rounded, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.restaurantName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.ownerName} • ${record.city}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Food: ${record.foodType} • Service Area: ${record.serviceAreaLabel}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Chip(
                label: Text(record.normalizedStatus.toUpperCase()),
                backgroundColor: statusColor.withOpacity(0.10),
                labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12),
                side: BorderSide.none,
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No restaurant requests found.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}
