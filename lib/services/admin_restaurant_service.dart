import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantAdminRecord {
  RestaurantAdminRecord({
    required this.id,
    required this.data,
  });

  final String id;
  final Map<String, dynamic> data;

  String _s(String key, {String fallback = ''}) {
    final value = data[key];
    if (value == null) return fallback;
    return value.toString();
  }

  bool _b(String key) => data[key] == true;

  String get restaurantName =>
      _s('restaurantName', fallback: _s('name', fallback: 'Restaurant'));

  String get ownerName => _s('ownerName', fallback: 'Owner');

  String get phone => _s('phone', fallback: _s('ownerPhone'));

  String get businessEmail => _s('businessEmail', fallback: _s('email'));

  String get city => _s('city', fallback: 'Not available');

  String get address => _s('address', fallback: _s('fullAddress'));

  String get mapLink => _s('mapLink', fallback: _s('googleMapLink'));

  String get foodType => _s('foodType', fallback: 'Not set');

  String get serviceAreaLabel =>
      _s('serviceAreaLabel', fallback: _s('serviceArea', fallback: 'Not set'));

  num get deliveryRadiusKm {
    final value = data['deliveryRadiusKm'] ?? data['deliveryRadius'] ?? 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  bool get delivery => _b('delivery');

  bool get pickup => _b('pickup');

  bool get dineIn => _b('dineIn');

  bool get trialEnabled => _b('trialEnabled');

  bool get weeklyEnabled => _b('weeklyEnabled');

  bool get monthlyEnabled => _b('monthlyEnabled');

  String get upiId => _s('upiId', fallback: 'Not available');

  String get qrCodeUrl => _s('qrCodeUrl');

  String get accountHolder => _s('accountHolder', fallback: 'Not available');

  String get rejectionReason => _s('rejectionReason');

  String get status =>
      _s('status', fallback: _s('registrationStatus', fallback: 'pending'));

  String get normalizedStatus {
    final value = status.toLowerCase().trim();

    if (value == 'approved' || value == 'active') return 'approved';
    if (value == 'rejected' || value == 'rejected_by_admin') return 'rejected';

    return 'pending';
  }

  String get createdAtText => _formatDate(data['createdAt']);

  String get reapplyAfterText => _formatDate(data['reapplyAfter']);

  String _formatDate(dynamic value) {
    if (value == null) return '';

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return '';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class AdminRestaurantService {
  final CollectionReference<Map<String, dynamic>> _restaurants =
      FirebaseFirestore.instance.collection('restaurants');

  Stream<List<RestaurantAdminRecord>> watchRestaurants() {
    return _restaurants.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RestaurantAdminRecord(
          id: doc.id,
          data: doc.data(),
        );
      }).toList();
    });
  }

  Stream<RestaurantAdminRecord?> watchRestaurant(String restaurantId) {
    return _restaurants.doc(restaurantId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;

      return RestaurantAdminRecord(
        id: doc.id,
        data: doc.data()!,
      );
    });
  }

  Future<void> approveRestaurant(String restaurantId) async {
    await _restaurants.doc(restaurantId).update({
      'status': 'approved',
      'registrationStatus': 'approved',
      'isApproved': true,
      'isActive': true,
      'rejectionReason': '',
      'reapplyAfter': null,
      'reviewedAt': FieldValue.serverTimestamp(),
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRestaurant(String restaurantId, String reason) async {
    final reapplyAfter = DateTime.now().add(const Duration(hours: 48));

    await _restaurants.doc(restaurantId).update({
      'status': 'rejected',
      'registrationStatus': 'rejected',
      'isApproved': false,
      'isActive': false,
      'rejectionReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectedAt': FieldValue.serverTimestamp(),
      'reapplyAfter': Timestamp.fromDate(reapplyAfter),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}