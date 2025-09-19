import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../providers/notification_provider.dart';
import '../providers/hotel_provider.dart';

class BookingService {
  final _bookings = FirebaseFirestore.instance.collection('bookings');

  Future<double> calculateTotalPrice({
    required double basePrice,
    required double taxRate,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final days = checkOut.difference(checkIn).inDays;
      final subtotal = basePrice * days;
      return subtotal + (subtotal * taxRate);
    } catch (e) {
      print('Error calculating price: $e');
      return 0.0;
    }
  }

  Future<List<BookingModel>> getBookingsByDateRange(
    String hotelId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _bookings
          .where('hotelId', isEqualTo: hotelId)
          .where('checkIn', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('checkOut', isLessThanOrEqualTo: end.toIso8601String())
          .get();
      return snapshot.docs.map((doc) => BookingModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching bookings by date range: $e');
      return [];
    }
  }

  Future<void> createBooking(BuildContext context, BookingModel booking) async {
    try {
      await _bookings.doc(booking.id).set(booking.toMap());
      final hotel = await Provider.of<HotelProvider>(context, listen: false).getHotelById(context, booking.hotelId);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.sendNotificationToAdmin(
        title: 'New Booking Request',
        body: 'A new booking for ${hotel?.name ?? "hotel"} is pending approval.',
      );
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final snapshot = await _bookings.where('userId', isEqualTo: userId).get();
      return snapshot.docs.map((doc) => BookingModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching user bookings: $e');
      return [];
    }
  }

  Future<void> cancelBooking(BuildContext context, String bookingId) async {
    try {
      await _bookings.doc(bookingId).update({'status': 'cancelled'});
      final bookingDoc = await _bookings.doc(bookingId).get();
      final booking = BookingModel.fromMap(bookingDoc.data()!);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.sendNotificationToUser(
        userId: booking.userId,
        title: 'Booking Cancelled',
        body: 'Your booking has been cancelled.',
      );
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  Future<void> updateBooking(BuildContext context, BookingModel booking) async {
    try {
      await _bookings.doc(booking.id).update(booking.toMap());
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.sendNotificationToUser(
        userId: booking.userId,
        title: 'Booking Updated',
        body: 'Your booking status is now ${booking.status}.',
      );
    } catch (e) {
      print('Error updating booking: $e');
      rethrow;
    }
  }

  Future<bool> isRoomAvailable(String roomId, DateTime checkIn, DateTime checkOut) async {
    try {
      final snapshot = await _bookings
          .where('roomId', isEqualTo: roomId)
          .where('status', isEqualTo: 'confirmed')
          .get();
      for (var doc in snapshot.docs) {
        final booking = BookingModel.fromMap(doc.data());
        final overlap = checkIn.isBefore(booking.checkOut) && checkOut.isAfter(booking.checkIn);
        if (overlap) return false;
      }
      return true;
    } catch (e) {
      print('Error checking room availability: $e');
      return false;
    }
  }
}