import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../services/hotel_service.dart';
import 'auth_provider.dart';

class HotelProvider extends ChangeNotifier {
  final HotelService _hotelService = HotelService();
  final Map<String, HotelModel> _hotelCache = {};
  final Map<String, List<RoomModel>> _roomCache = {};
  final List<HotelModel> _hotels = [];
  List<HotelModel> get hotels => List.unmodifiable(_hotels);
  List<RoomModel> _rooms = [];
  List<RoomModel> get rooms => _rooms;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  final int _pageSize = 10;
  String _search = '';

  HotelProvider() {
    fetchHotels(refresh: true);
  }

  Future<HotelModel?> getHotelById(BuildContext context, String id, {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _hotelCache.containsKey(id)) {
        return _hotelCache[id];
      }
      final hotel = await _hotelService.getHotelById(id);
      if (hotel != null) {
        _hotelCache[id] = hotel;
      }
      return hotel;
    } catch (e) {
      print('Error fetching hotel: $e');
      return null;
    }
  }

  Future<void> addHotel(BuildContext context, HotelModel hotel) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      throw Exception('Only admins can add hotels');
    }
    try {
      await _hotelService.addHotel(hotel);
      _hotels.add(hotel);
      _hotelCache[hotel.id] = hotel;
      notifyListeners();
    } catch (e) {
      print('Error adding hotel: $e');
      rethrow;
    }
  }

  Future<void> fetchHotels({bool refresh = false}) async {
    if (_isLoading) return;
    try {
      if (refresh) {
        _lastDoc = null;
        _hasMore = true;
        _hotels.clear();
        notifyListeners();
      }
      if (!_hasMore) return;
      _isLoading = true;
      notifyListeners();
      final snap = await _hotelService.getHotelsPaginated(
        startAfter: _lastDoc,
        limit: _pageSize,
        searchQuery: _search.isNotEmpty ? _search : null,
      );
      if (snap.docs.isNotEmpty) {
        for (final d in snap.docs) {
          final data = d.data();
          final model = HotelModel.fromMap(data, id: d.id);
          if (!_hotels.any((h) => h.id == model.id)) _hotels.add(model);
        }
        _lastDoc = snap.docs.last;
      }
      if (snap.docs.length < _pageSize) _hasMore = false;
    } catch (e) {
      print('fetchHotels error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await fetchHotels(refresh: false);
  }

  Future<void> searchHotels(String query) async {
    try {
      _search = query.trim();
      _lastDoc = null;
      _hasMore = true;
      _hotels.clear();
      notifyListeners();
      await fetchHotels(refresh: true);
    } catch (e) {
      print('Error searching hotels: $e');
    }
  }

  Future<List<RoomModel>> getRoomsByHotel(BuildContext context, String hotelId, {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _roomCache.containsKey(hotelId)) {
        return _roomCache[hotelId]!;
      }
      _isLoading = true;
      notifyListeners();
      final rooms = await _hotelService.getRoomsByHotel(hotelId);
      _roomCache[hotelId] = rooms;
      return rooms;
    } catch (e) {
      print('Error fetching rooms: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<HotelModel> get filteredHotels => _hotels;

  Future<void> prefetchHotelDetails(BuildContext context, String hotelId) async {
    try {
      await _hotelService.getHotelById(hotelId);
    } catch (e) {
      print('prefetchHotelDetails error: $e');
    }
  }

  Future<void> bulkDeleteHotels(BuildContext context, List<String> hotelIds) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      throw Exception('Only admins can delete hotels');
    }
    try {
      for (final id in hotelIds) {
        await _hotelService.deleteHotel(id);
      }
      _hotels.removeWhere((h) => hotelIds.contains(h.id));
      notifyListeners();
    } catch (e) {
      print('Error deleting hotels: $e');
      rethrow;
    }
  }

  Future<void> approveHotel(BuildContext context, String hotelId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      throw Exception('Only admins can approve hotels');
    }
    try {
      final idx = _hotels.indexWhere((h) => h.id == hotelId);
      if (idx == -1) return;
      final h = _hotels[idx];
      final updated = HotelModel(
        id: h.id,
        name: h.name,
        address: h.address,
        coordinates: h.coordinates,
        description: h.description,
        amenities: h.amenities,
        images: h.images,
        coverImage: h.coverImage,
        rating: h.rating,
        isPopular: h.isPopular,
        isNew: false,
        avgPrice: h.avgPrice,
        basePrice: h.basePrice,
        taxRate: h.taxRate,
        seoTags: h.seoTags,
        availableRooms: h.availableRooms,
        tags: h.tags,
      );
      await _hotelService.updateHotel(updated);
      _hotels[idx] = updated;
      notifyListeners();
    } catch (e) {
      print('Error approving hotel: $e');
      rethrow;
    }
  }
}