import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'notification_provider.dart';
import 'hotel_provider.dart';
import 'auth_provider.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<void> loadBookings(BuildContext context, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      _bookings = await _bookingService.getUserBookings(userId);
    } catch (e) {
      print('Error loading bookings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBooking(BuildContext context, BookingModel booking) async {
    try {
      await _bookingService.createBooking(context, booking);
      _bookings.add(booking);
      notifyListeners();
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  Future<void> updateBooking(BuildContext context, BookingModel updatedBooking, Map<String, dynamic> changes) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      throw Exception('Only admins can update bookings');
    }
    try {
      await _bookingService.updateBooking(context, updatedBooking);
      final index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating booking: $e');
      rethrow;
    }
  }

  Future<void> cancelBooking(BuildContext context, String bookingId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final booking = _bookings.firstWhere((b) => b.id == bookingId, orElse: () => throw Exception('Booking not found'));
    if (authProvider.user?.uid != booking.userId && !authProvider.isAdmin) {
      throw Exception('Only the booking owner or admin can cancel');
    }
    try {
      await _bookingService.cancelBooking(context, bookingId);
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = BookingModel(
          id: _bookings[index].id,
          userId: _bookings[index].userId,
          hotelId: _bookings[index].hotelId,
          roomId: _bookings[index].roomId,
          checkIn: _bookings[index].checkIn,
          checkOut: _bookings[index].checkOut,
          guests: _bookings[index].guests,
          totalPrice: _bookings[index].totalPrice,
          status: 'cancelled',
          paymentId: _bookings[index].paymentId,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }
}