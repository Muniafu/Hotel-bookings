import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/payment_model.dart';
import '../providers/notification_provider.dart';
import '../providers/hotel_provider.dart';

class PaymentService {
  final String paystackPublicKeyTest;
  final String paystackSecretKey;
  final bool isSandbox;

  PaymentService({
    required this.paystackPublicKeyTest,
    required this.paystackSecretKey,
    this.isSandbox = true,
  });

  Future<PaymentModel> initializePayment({
    required BuildContext context,
    required String userId,
    required String bookingId,
    required double amount,
    required String email,
    String? phone,
    required String checkoutMethod,
  }) async {
    final txRef = 'BOOK_${DateTime.now().millisecondsSinceEpoch}';
    final payment = PaymentModel(
      id: txRef,
      bookingId: bookingId,
      userId: userId,
      amount: amount,
      currency: 'KES',
      paymentMethod: checkoutMethod,
      gatewayReference: txRef,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final completer = Completer<PaymentModel>();
    final uniqueTransRef = PayWithPayStack().generateUuidV4();

    try {
      await PayWithPayStack().now(
        context: context,
        secretKey: paystackSecretKey,
        customerEmail: email,
        reference: uniqueTransRef,
        currency: payment.currency,
        amount: (amount * 100),
        callbackUrl: isSandbox ? 'https://api.paystack.co' : 'https://your-callback-url.com',
        transactionCompleted: (paymentData) async {
          final updatedPayment = payment.copyWith(
            status: 'successful',
            paymentMethod: checkoutMethod,
            completedAt: DateTime.now(),
          );
          await _savePayment(updatedPayment);
          final bookingDoc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
          final hotelId = bookingDoc.data()?['hotelId'];
          final hotel = await Provider.of<HotelProvider>(context, listen: false).getHotelById(context, hotelId);
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          await notificationProvider.sendNotificationToUser(
            userId: userId,
            title: 'Payment Successful',
            body: 'Your payment for ${hotel?.name ?? "hotel"} was successful.',
          );
          await notificationProvider.sendNotificationToAdmin(
            title: 'New Payment Received',
            body: 'Payment for booking $bookingId was successful.',
          );
          completer.complete(updatedPayment);
        },
        transactionNotCompleted: (reason) async {
          final failedPayment = payment.copyWith(
            status: 'failed',
            completedAt: DateTime.now(),
          );
          await _savePayment(failedPayment);
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          await notificationProvider.sendNotificationToUser(
            userId: userId,
            title: 'Payment Failed',
            body: 'Your payment failed: $reason',
          );
          completer.complete(failedPayment);
        },
      );
      return completer.future;
    } catch (e) {
      final failedPayment = payment.copyWith(
        status: 'failed',
        completedAt: DateTime.now(),
      );
      await _savePayment(failedPayment);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.sendNotificationToUser(
        userId: userId,
        title: 'Payment Error',
        body: 'Payment error: $e',
      );
      print('Paystack error: $e');
      return failedPayment;
    }
  }

  Future<void> _savePayment(PaymentModel payment) async {
    try {
      await FirebaseFirestore.instance.collection('payments').doc(payment.id).set(payment.toMap());
    } catch (e) {
      print('Error saving payment: $e');
      rethrow;
    }
  }

  Future<bool> verifyPayment(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.paystack.co/transaction/verify/$reference'),
        headers: {'Authorization': 'Bearer $paystackSecretKey'},
      );
      final data = jsonDecode(response.body);
      return data['status'] == true && data['data']['status'] == 'success';
    } catch (e) {
      print('Verification error: $e');
      return false;
    }
  }

  Future<List<PaymentModel>> getPaymentsForAdmin() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('payments').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => PaymentModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching payments: $e');
      return [];
    }
  }
}