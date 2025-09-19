import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/booking_provider.dart';

class SubmitReviewScreen extends StatefulWidget {
  final String bookingId;
  final String hotelId;

  const SubmitReviewScreen({super.key, required this.bookingId, required this.hotelId});

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  int rating = 0;
  final commentController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> submitReview() async {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final bookingProvider = context.read<BookingProvider>();

    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating")),
      );
      return;
    }

    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a comment")),
      );
      return;
    }

    // Verify booking exists and belongs to user
    bookingProvider.bookings.firstWhere(
      (b) => b.id == widget.bookingId && b.userId == authProvider.user!.uid,
      orElse: () => throw Exception('Booking not found or not authorized'),
    );

    setState(() => isSubmitting = true);

    try {
      final review = {
        'id': const Uuid().v4(),
        'bookingId': widget.bookingId,
        'hotelId': widget.hotelId,
        'rating': rating,
        'comment': commentController.text.trim(),
        'date': DateTime.now().toIso8601String(),
        'userId': authProvider.user!.uid,
      };

      await FirebaseFirestore.instance.collection('reviews').add(review);

      // Send admin notification
      await notificationProvider.sendNotificationToAdmin(
        title: "New Review Submitted",
        body: "User ${authProvider.user!.uid} submitted a review for booking ${widget.bookingId.substring(0, 6)}.",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting review: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Role-based check
    if (authProvider.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Submit Review")),
      body: isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 600;
                final contentWidth = isWideScreen ? constraints.maxWidth * 0.6 : constraints.maxWidth * 0.9;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isWideScreen ? 32 : 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Rate your stay",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            return IconButton(
                              icon: Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber[700],
                                size: 32,
                              ),
                              onPressed: () => setState(() => rating = i + 1),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            labelText: "Leave a comment",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          maxLines: 4,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text("Submit Review", style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}