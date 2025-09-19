import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/hotel_model.dart';
import '../../models/room_model.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/notification_provider.dart';
import 'confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  final RoomModel room;
  final HotelModel hotel;

  const BookingScreen({super.key, required this.room, required this.hotel});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  int _guests = 1;
  String? _bookingId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIn = DateTime.now();
    _checkOut = _checkIn.add(const Duration(days: 1));
    _bookingId = const Uuid().v4();
  }

  int get selectedNights => _checkOut.difference(_checkIn).inDays;

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (!_checkOut.isAfter(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _proceedToPayment() async {
    final authProvider = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    if (_guests < 1 || selectedNights < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid dates and number of guests')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create booking
      final booking = BookingModel(
        id: _bookingId!,
        userId: authProvider.user!.uid,
        hotelId: widget.hotel.id, // Added hotelId
        roomId: widget.room.id,
        checkIn: _checkIn,
        checkOut: _checkOut,
        guests: _guests,
        totalPrice: widget.room.pricePerNight * selectedNights,
        status: 'pending',
        paymentId: '',
      );

      await bookingProvider.createBooking(context, booking);

      // Notify admin of new booking
      await notificationProvider.sendNotificationToAdmin(
        title: 'New Booking Request',
        body: 'User ${authProvider.user!.email} created booking $_bookingId for ${widget.room.name} at ${widget.hotel.name}.',
      );

      // Process payment
      await paymentProvider.initializePayment(
        context: context,
        userId: authProvider.user!.uid,
        bookingId: _bookingId!,
        amount: widget.room.pricePerNight * selectedNights,
        email: authProvider.user!.email,
        phone: authProvider.user!.phone,
      );

      if (paymentProvider.currentPayment?.status == 'successful') {
        // Update booking status
        final updatedBooking = BookingModel(
          id: booking.id,
          userId: booking.userId,
          hotelId: booking.hotelId,
          roomId: booking.roomId,
          checkIn: booking.checkIn,
          checkOut: booking.checkOut,
          guests: booking.guests,
          totalPrice: booking.totalPrice,
          status: 'confirmed',
          paymentId: paymentProvider.currentPayment!.id,
        );

        await bookingProvider.updateBooking(context, updatedBooking, {
          'status': 'confirmed',
          'paymentId': paymentProvider.currentPayment!.id,
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConfirmationScreen(
                bookingId: _bookingId!,
                paymentId: paymentProvider.currentPayment!.id,
              ),
            ),
          );
        }
      } else if (paymentProvider.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${paymentProvider.error!}')),
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Booking failed: ${e.toString()}';
      if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please contact support.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    // Role-based check
    if (authProvider.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.hotel.name}')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          final contentWidth = isWideScreen ? constraints.maxWidth * 0.6 : constraints.maxWidth * 0.9;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWideScreen ? 32 : 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking details
                    Text(
                      'Room: ${widget.room.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Price: KES ${widget.room.pricePerNight.toStringAsFixed(2)}/night',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    // Date selection
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Check-in'),
                            trailing: Text(DateFormat('MMM d, y').format(_checkIn)),
                            onTap: () => _selectDate(context, true),
                          ),
                          ListTile(
                            title: const Text('Check-out'),
                            trailing: Text(DateFormat('MMM d, y').format(_checkOut)),
                            onTap: () => _selectDate(context, false),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Nights: $selectedNights', style: Theme.of(context).textTheme.bodyLarge),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Guest selection
                    Card(
                      elevation: 2,
                      child: ListTile(
                        title: const Text('Guests'),
                        trailing: DropdownButton<int>(
                          value: _guests,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _guests = value);
                            }
                          },
                          items: List.generate(6, (i) => i + 1)
                              .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                              .toList(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Total and payment button
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Total: KES ${(widget.room.pricePerNight * selectedNights).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoading || paymentProvider.isLoading ? null : _proceedToPayment,
                                child: _isLoading || paymentProvider.isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Proceed to Payment', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
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