// Prototype mock data — delete when real API is wired. In-memory session store.
// Mirrors frontend/src/mockData/mockBookings.ts.
import '../models/booking.dart';

const List<String> mockBookingSlots = [
  '10:00 AM',
  '11:30 AM',
  '01:00 PM',
  '02:30 PM',
  '04:00 PM',
  '05:30 PM',
];

class OfflineVenue {
  final String name;
  final String address;
  final String city;
  const OfflineVenue({required this.name, required this.address, required this.city});
}

/// Fixed office per booking kind — this prototype has one physical office,
/// not a multi-location backend, so a small constant is the right amount
/// of "data model" for it. Both kinds share the same building for now.
const mockOfflineVenues = {
  'placement': OfflineVenue(name: 'Aerostar Careers Office', address: '3rd Floor, Baner Road, Pune', city: 'Pune'),
  'counseling': OfflineVenue(name: 'Aerostar Careers Office', address: '3rd Floor, Baner Road, Pune', city: 'Pune'),
};

/// Seed so Sessions / SchoolHome aren't empty on first load.
List<Booking> _bookings = [
  Booking(
    id: 'booking-demo-1',
    userId: 'demo',
    kind: 'placement',
    mode: 'online',
    sessionType: 'Mock Interview',
    date: 'Thu, 14 Aug',
    time: '02:30 PM',
    name: 'Demo User',
    phone: '9876543210',
    email: null,
    counselor: 'Ms. Ananya Rao',
    status: 'Confirmed',
    createdAt: DateTime.now().toIso8601String(),
  ),
];

List<Booking> listBookings() => List.of(_bookings);

Booking createBooking({
  required String kind,
  required String mode,
  String? sessionType,
  required String date,
  required String time,
  required String name,
  String? phone,
  String? email,
}) {
  final venue = mode == 'offline' ? mockOfflineVenues[kind] : null;
  final booking = Booking(
    id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
    userId: 'demo',
    kind: kind,
    mode: mode,
    sessionType: sessionType,
    date: date,
    time: time,
    name: name,
    phone: phone,
    email: email,
    counselor: 'Ms. Ananya Rao',
    status: 'Confirmed',
    createdAt: DateTime.now().toIso8601String(),
    venueName: venue?.name,
    venueAddress: venue?.address,
    venueCity: venue?.city,
  );
  _bookings = [booking, ..._bookings];
  return booking;
}

Booking? updateBooking(
  String id, {
  String? mode,
  String? sessionType,
  String? date,
  String? time,
}) {
  final idx = _bookings.indexWhere((b) => b.id == id);
  if (idx < 0) return null;
  var updated = _bookings[idx].copyWith(
    mode: mode,
    sessionType: sessionType,
    date: date,
    time: time,
  );
  // mode is the only field above that changes whether a venue applies —
  // recompute it explicitly rather than letting copyWith's ?? fallback
  // leave a stale venue attached after switching offline -> online.
  if (mode != null) {
    final venue = mode == 'offline' ? mockOfflineVenues[updated.kind] : null;
    updated = updated.withVenue(name: venue?.name, address: venue?.address, city: venue?.city);
  }
  _bookings[idx] = updated;
  return updated;
}

bool deleteBooking(String id) {
  final before = _bookings.length;
  _bookings = _bookings.where((b) => b.id != id).toList();
  return _bookings.length < before;
}
