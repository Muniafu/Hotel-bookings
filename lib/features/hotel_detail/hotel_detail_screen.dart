import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/hotel_model.dart';
import '../../models/room_model.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/auth_provider.dart';
import '../booking/booking_screen.dart';

class HotelDetailScreen extends StatefulWidget {
  final HotelModel hotel;

  const HotelDetailScreen({super.key, required this.hotel});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  late HotelProvider hotelProvider;
  List<RoomModel> rooms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    hotelProvider = context.read<HotelProvider>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Fetch rooms for the hotel
      rooms = await hotelProvider.getRoomsByHotel(context, widget.hotel.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rooms: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _bookRoom(RoomModel room) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    Navigator.pushNamed(
      context,
      '/booking',
      arguments: {'room': room, 'hotel': widget.hotel},
    );
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
      appBar: AppBar(title: Text(widget.hotel.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          final contentWidth = isWideScreen ? constraints.maxWidth * 0.6 : constraints.maxWidth * 0.9;

          return isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isWideScreen ? 32 : 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hotel Images Carousel
                        SizedBox(
                          height: 250,
                          child: PageView(
                            children: widget.hotel.images.isNotEmpty
                                ? widget.hotel.images
                                    .map((img) => CachedNetworkImage(
                                          imageUrl: img,
                                          fit: BoxFit.cover,
                                          placeholder: (c, u) => Container(color: Colors.grey[300]),
                                          errorWidget: (c, u, e) => Container(
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image),
                                          ),
                                        ))
                                    .toList()
                                : [
                                    Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: Text('No images available')),
                                    ),
                                  ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hotel.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber[700], size: 18),
                                const SizedBox(width: 4),
                                Text(widget.hotel.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.hotel.address,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.hotel.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.hotel.amenities
                                  .map((a) => Chip(
                                        label: Text(a, style: const TextStyle(fontSize: 12)),
                                        backgroundColor: Colors.indigo.shade100,
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Available Rooms',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            rooms.isEmpty
                                ? const Center(child: Text('No rooms available'))
                                : ListView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: rooms.length,
                                    itemBuilder: (_, index) {
                                      final room = rooms[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                        child: ListTile(
                                          title: Text(
                                            '${room.name} - \$${room.pricePerNight.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text('Capacity: ${room.capacity} guests'),
                                          trailing: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () => _bookRoom(room),
                                            child: const Text('Book', style: TextStyle(fontSize: 14)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
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