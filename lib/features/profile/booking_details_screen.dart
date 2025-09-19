import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/room_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/booking_model.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Map<String, dynamic>? roomData;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoomAndUser();
  }

  Future<void> _fetchRoomAndUser() async {
    try {
      final hotelProvider = context.read<HotelProvider>();
      final rooms = await hotelProvider.getRoomsByHotel(context, widget.booking.hotelId);
      final room = rooms.firstWhere((r) => r.id == widget.booking.roomId, orElse: () => RoomModel(
        id: widget.booking.roomId,
        hotelId: widget.booking.hotelId,
        name: 'Unknown Room',
        type: 'Unknown',
        description: '',
        pricePerNight: 0.0,
        capacity: 1,
        features: [],
        images: [],
        amenities: [],
      ));
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.booking.userId)
          .get();

      if (mounted) {
        setState(() {
          roomData = room.toMap();
          userData = userSnap.data();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading room/user data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final booking = widget.booking;

    // Role-based check
    if (authProvider.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room images carousel
                  if (roomData != null &&
                      roomData!['images'] != null &&
                      (roomData!['images'] as List).isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: (roomData!['images'] as List).length,
                        itemBuilder: (_, index) => CachedNetworkImage(
                          imageUrl: roomData!['images'][index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (c, u) => Container(color: Colors.grey[300]),
                          errorWidget: (c, u, e) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text("No room images")),
                    ),

                  const SizedBox(height: 16),

                  // Booking Timeline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _bookingTimeline(
                      checkIn: booking.checkIn.toString().split(" ").first,
                      checkOut: booking.checkOut.toString().split(" ").first,
                    ),
                  ),
                  const Divider(height: 32),

                  // Guest Info Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.person, color: Colors.black54),
                        ),
                        title: Text(userData?['name'] ?? "Guest"),
                        subtitle: Text(userData?['email'] ?? "No email provided"),
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  // Booking Info Section
                  _sectionTitle("Booking Information"),
                  _infoTile("Booking ID", booking.id),
                  _infoTile("Check-in", booking.checkIn.toString().split(" ").first),
                  _infoTile("Check-out", booking.checkOut.toString().split(" ").first),
                  _infoTile("Guests", booking.guests.toString()),

                  const Divider(height: 32),

                  // Payment Info Section
                  _sectionTitle("Payment Details"),
                  _infoTile("Total Price", "\$${booking.totalPrice.toStringAsFixed(2)}"),
                  _infoTile("Payment ID", booking.paymentId.isEmpty ? "Pending" : booking.paymentId),

                  const Divider(height: 32),

                  // Status & Cancel Option
                  _sectionTitle("Booking Status"),
                  ListTile(
                    title: const Text("Status"),
                    trailing: Chip(
                      label: Text(booking.status),
                      backgroundColor: _statusColor(booking.status),
                    ),
                  ),

                  if (booking.status.toLowerCase() == 'confirmed')
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text("Cancel Booking"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Cancel Booking?"),
                              content: const Text("Are you sure you want to cancel this booking?"),
                              actions: [
                                TextButton(
                                  child: const Text("No"),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text("Yes, Cancel"),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await Provider.of<BookingProvider>(context, listen: false)
                                  .cancelBooking(context, booking.id);
                              final notificationProvider = context.read<NotificationProvider>();
                              await notificationProvider.sendNotificationToUser(
                                userId: booking.userId,
                                title: "Booking Cancelled",
                                body: "Your booking ${booking.id.substring(0, 6)} has been cancelled.",
                              );
                              await notificationProvider.sendNotificationToAdmin(
                                title: "Booking Cancelled",
                                body: "Booking ${booking.id.substring(0, 6)} by user ${booking.userId} has been cancelled.",
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Booking cancelled successfully")),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error cancelling booking: $e")),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// --- Helper Widgets ---
  Widget _infoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      case 'checked-in':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _bookingTimeline({required String checkIn, required String checkOut}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _timelineStep("Check-in", checkIn, true),
        Expanded(
          child: Container(height: 2, color: Colors.grey.shade400),
        ),
        _timelineStep("Stay", "In Progress", false, icon: Icons.hotel),
        Expanded(
          child: Container(height: 2, color: Colors.grey.shade400),
        ),
        _timelineStep("Check-out", checkOut, false),
      ],
    );
  }

  Widget _timelineStep(String label, String date, bool completed, {IconData? icon}) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: completed ? Colors.green : Colors.grey.shade400,
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 20)
              : const Icon(Icons.check, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}