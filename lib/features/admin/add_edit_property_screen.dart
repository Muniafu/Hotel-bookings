import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:cloud_firestore/cloud_firestore.dart'; // For SettableMetadata

import '../../providers/hotel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/hotel_model.dart';
import '../../services/hotel_service.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final HotelModel? hotel;

  const AddEditPropertyScreen({super.key, this.hotel});

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final descController = TextEditingController();
  final ratingController = TextEditingController();
  final amenitiesController = TextEditingController();
  final seoTagsController = TextEditingController();
  final basePriceController = TextEditingController();
  final taxRateController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final availableRoomsController = TextEditingController();
  final tagsController = TextEditingController();

  int _currentStep = 0;
  final picker = ImagePicker();
  final List<File> _images = [];
  final List<Uint8List> _webImages = [];
  String? _coverImageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.hotel != null) {
      final hotel = widget.hotel!;
      nameController.text = hotel.name;
      addressController.text = hotel.address;
      descController.text = hotel.description;
      ratingController.text = hotel.rating.toString();
      amenitiesController.text = hotel.amenities.join(', ');
      latController.text = (hotel.coordinates['lat'] ?? 0).toString();
      lngController.text = (hotel.coordinates['lng'] ?? 0).toString();
      basePriceController.text = hotel.basePrice.toString();
      taxRateController.text = (hotel.taxRate * 100).toString();
      availableRoomsController.text = hotel.availableRooms.toString();
      tagsController.text = hotel.tags.join(', ');
      seoTagsController.text = hotel.seoTags.join(', ');
    }
  }

  double getCalculatedPrice() {
    final base = double.tryParse(basePriceController.text) ?? 0;
    final tax = double.tryParse(taxRateController.text) ?? 0;
    return base + (base * (tax / 100));
  }

  Future<void> pickImages() async {
    try {
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          if (kIsWeb) {
            for (var file in pickedFiles) {
              file.readAsBytes().then((bytes) => _webImages.add(bytes));
            }
          } else {
            _images.addAll(pickedFiles.map((file) => File(file.path)));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> saveHotel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final id = widget.hotel?.id ?? const Uuid().v4();
      final List<String> uploadedUrls = [];
      String? coverImageFinalUrl;

      // Upload mobile images
      for (var i = 0; i < _images.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('hotel_images')
            .child('${DateTime.now().millisecondsSinceEpoch}_mobile_$i.jpg');

        await ref.putFile(_images[i]);
        final url = await ref.getDownloadURL();
        uploadedUrls.add(url);

        if (_coverImageUrl == 'mobile_$i') {
          coverImageFinalUrl = url;
        }
      }

      // Upload web images
      for (var i = 0; i < _webImages.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('hotel_images')
            .child('${DateTime.now().millisecondsSinceEpoch}_web_$i.jpg');

        await ref.putData(
          _webImages[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final url = await ref.getDownloadURL();
        uploadedUrls.add(url);

        if (_coverImageUrl == 'web_$i') {
          coverImageFinalUrl = url;
        }
      }

      coverImageFinalUrl ??= uploadedUrls.isNotEmpty ? uploadedUrls.first : null;

      final hotel = HotelModel(
        id: id,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        coordinates: {
          'lat': double.tryParse(latController.text) ?? 0,
          'lng': double.tryParse(lngController.text) ?? 0
        },
        description: descController.text.trim(),
        amenities: amenitiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        images: uploadedUrls,
        coverImage: coverImageFinalUrl,
        rating: double.tryParse(ratingController.text.trim()) ?? 0.0,
        seoTags: seoTagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        basePrice: double.tryParse(basePriceController.text) ?? 0.0,
        taxRate: (double.tryParse(taxRateController.text) ?? 0) / 100,
        avgPrice: getCalculatedPrice(),
        availableRooms: int.tryParse(availableRoomsController.text) ?? 0,
        isPopular: false,
        isNew: widget.hotel == null,
        tags: tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );

      final service = HotelService();
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);

      if (widget.hotel == null) {
        await service.addHotel(hotel);
        await hotelProvider.fetchHotels(refresh: true);
      } else {
        await service.updateHotel(hotel);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.hotel == null ? 'Hotel added successfully' : 'Hotel updated successfully')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving hotel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Role-based check
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isEdit = widget.hotel != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Hotel" : "Add Hotel")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stepper(
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep < 2) {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _currentStep++);
                        }
                      } else {
                        saveHotel();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      }
                    },
                    steps: [
                      Step(
                        title: const Text("Images"),
                        content: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: pickImages,
                              icon: const Icon(Icons.photo_library),
                              label: const Text("Pick Images"),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: constraints.maxHeight * 0.3,
                              child: ReorderableGridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: constraints.maxWidth > 600 ? 4 : 3,
                                children: [
                                  if (kIsWeb)
                                    ..._webImages.asMap().entries.map((entry) => GestureDetector(
                                          key: ValueKey('web_${entry.key}'),
                                          onTap: () => setState(() => _coverImageUrl = 'web_${entry.key}'),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.memory(entry.value, fit: BoxFit.cover),
                                              if (_coverImageUrl == 'web_${entry.key}')
                                                Container(
                                                  color: Colors.black45,
                                                  child: const Center(child: Icon(Icons.star, color: Colors.yellow)),
                                                )
                                            ],
                                          ),
                                        )),
                                  if (!kIsWeb)
                                    ..._images.asMap().entries.map((entry) => GestureDetector(
                                          key: ValueKey('mobile_${entry.key}'),
                                          onTap: () => setState(() => _coverImageUrl = 'mobile_${entry.key}'),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.file(entry.value, fit: BoxFit.cover),
                                              if (_coverImageUrl == 'mobile_${entry.key}')
                                                Container(
                                                  color: Colors.black45,
                                                  child: const Center(child: Icon(Icons.star, color: Colors.yellow)),
                                                )
                                            ],
                                          ),
                                        )),
                                ],
                                onReorder: (oldIndex, newIndex) {
                                  if (kIsWeb) {
                                    final item = _webImages.removeAt(oldIndex);
                                    _webImages.insert(newIndex, item);
                                  } else {
                                    final item = _images.removeAt(oldIndex);
                                    _images.insert(newIndex, item);
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Step(
                        title: const Text("Details"),
                        content: Column(
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(labelText: "Hotel Name"),
                              validator: (value) => value?.isEmpty ?? true ? "Required" : null,
                            ),
                            TextFormField(
                              controller: addressController,
                              decoration: const InputDecoration(labelText: "Address"),
                              validator: (value) => value?.isEmpty ?? true ? "Required" : null,
                            ),
                            TextFormField(
                              controller: descController,
                              decoration: const InputDecoration(labelText: "Description"),
                              maxLines: 3,
                              validator: (value) => value?.isEmpty ?? true ? "Required" : null,
                            ),
                            TextFormField(
                              controller: ratingController,
                              decoration: const InputDecoration(labelText: "Rating (0-5)"),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final rating = double.tryParse(value ?? '');
                                if (rating == null || rating < 0 || rating > 5) return "Enter a valid rating (0-5)";
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: amenitiesController,
                              decoration: const InputDecoration(labelText: "Amenities (comma-separated)"),
                            ),
                            TextFormField(
                              controller: seoTagsController,
                              decoration: const InputDecoration(labelText: "SEO Tags (comma-separated)"),
                            ),
                          ],
                        ),
                      ),
                      Step(
                        title: const Text("Pricing & Location"),
                        content: Column(
                          children: [
                            TextFormField(
                              controller: basePriceController,
                              decoration: const InputDecoration(labelText: "Base Price"),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final price = double.tryParse(value ?? '');
                                if (price == null || price < 0) return "Enter a valid price";
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: taxRateController,
                              decoration: const InputDecoration(labelText: "Tax Rate (%)"),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final tax = double.tryParse(value ?? '');
                                if (tax == null || tax < 0) return "Enter a valid tax rate";
                                return null;
                              },
                            ),
                            Text(
                              "Avg Price: \$${getCalculatedPrice().toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextFormField(
                              controller: latController,
                              decoration: const InputDecoration(labelText: "Latitude"),
                              keyboardType: TextInputType.number,
                              validator: (value) => double.tryParse(value ?? '') == null ? "Enter a valid latitude" : null,
                            ),
                            TextFormField(
                              controller: lngController,
                              decoration: const InputDecoration(labelText: "Longitude"),
                              keyboardType: TextInputType.number,
                              validator: (value) => double.tryParse(value ?? '') == null ? "Enter a valid longitude" : null,
                            ),
                            TextFormField(
                              controller: availableRoomsController,
                              decoration: const InputDecoration(labelText: "Available Rooms"),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final rooms = int.tryParse(value ?? '');
                                if (rooms == null || rooms < 0) return "Enter a valid number";
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: tagsController,
                              decoration: const InputDecoration(labelText: "Tags (comma-separated)"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}