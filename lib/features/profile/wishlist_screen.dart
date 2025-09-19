import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hotel_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hotel_provider.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final hotelProvider = context.watch<HotelProvider>();

    if (authProvider.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authProvider.user!;
    final hotels = hotelProvider.hotels;

    // Get favorite hotel IDs from user preferences
    final favoriteHotelIds = (user.preferences['favoriteHotels'] as List<dynamic>?)?.cast<String>() ?? [];
    final favoriteHotels = hotels.where((h) => favoriteHotelIds.contains(h.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Wishlist")),
      body: hotelProvider.isLoading && hotels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : favoriteHotels.isEmpty
              ? const Center(child: Text("No favorites yet."))
              : ListView.builder(
                  itemCount: favoriteHotels.length,
                  itemBuilder: (context, index) {
                    final HotelModel hotel = favoriteHotels[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: hotel.images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  hotel.images.first,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image),
                              ),
                        title: Text(hotel.name),
                        subtitle: Text(hotel.address),
                        onTap: () => Navigator.pushNamed(context, '/hotel-detail', arguments: hotel),
                      ),
                    );
                  },
                ),
    );
  }
}