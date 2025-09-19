import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';

class HotelService {
  final CollectionReference<Map<String, dynamic>> _hotels = FirebaseFirestore.instance.collection('hotels').withConverter<Map<String, dynamic>>(
        fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
        toFirestore: (m, _) => m,
      );
  final CollectionReference<Map<String, dynamic>> _rooms = FirebaseFirestore.instance.collection('rooms').withConverter<Map<String, dynamic>>(
        fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
        toFirestore: (m, _) => m,
      );

  Future<void> addHotel(HotelModel hotel) async {
    try {
      await _hotels.doc(hotel.id).set(hotel.toMap());
    } catch (e) {
      print('Error adding hotel: $e');
      rethrow;
    }
  }

  Future<void> updateHotel(HotelModel hotel) async {
    try {
      await _hotels.doc(hotel.id).update(hotel.toMap());
    } catch (e) {
      print('Error updating hotel: $e');
      rethrow;
    }
  }

  Future<void> deleteHotel(String id) async {
    try {
      await _hotels.doc(id).delete();
    } catch (e) {
      print('Error deleting hotel: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHotelsPaginated({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _hotels;
      q = q.orderBy('rating', descending: true).limit(limit);
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final qText = searchQuery.trim();
        q = q.where('name', isGreaterThanOrEqualTo: qText).where('name', isLessThanOrEqualTo: '$qText\uf8ff');
      }
      if (startAfter != null) {
        q = q.startAfterDocument(startAfter);
      }
      return await q.get();
    } catch (e) {
      print('Error fetching hotels: $e');
      rethrow;
    }
  }

  Future<HotelModel?> getHotelById(String id) async {
    try {
      final doc = await _hotels.doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return HotelModel.fromMap(data, id: doc.id);
    } catch (e) {
      print('Error fetching hotel: $e');
      return null;
    }
  }

  Future<List<RoomModel>> getRoomsByHotel(String hotelId) async {
    try {
      final snapshot = await _rooms.where('hotelId', isEqualTo: hotelId).get();
      return snapshot.docs.map((doc) => RoomModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching rooms: $e');
      return [];
    }
  }
}