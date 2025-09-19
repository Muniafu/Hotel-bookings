import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/room_model.dart';

class AddEditRoomScreen extends StatefulWidget {
  final String hotelId;
  final String? roomId;
  final RoomModel? roomData; // Use RoomModel

  const AddEditRoomScreen({
    super.key,
    required this.hotelId,
    this.roomId,
    this.roomData,
  });

  @override
  State<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends State<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final typeController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final capacityController = TextEditingController();
  final featuresController = TextEditingController();
  final amenitiesController = TextEditingController();
  final sizeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _newImages = [];
  final List<String> _uploadedImages = [];
  bool isLoading = false;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    if (widget.roomData != null) {
      final room = widget.roomData!;
      nameController.text = room.name;
      typeController.text = room.type;
      descController.text = room.description;
      priceController.text = room.pricePerNight.toString();
      capacityController.text = room.capacity.toString();
      featuresController.text = room.features.join(', ');
      amenitiesController.text = room.amenities.join(', ');
      sizeController.text = room.size.toString();
      _uploadedImages.addAll(room.images);
      _isAvailable = room.isAvailable;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    descController.dispose();
    priceController.dispose();
    capacityController.dispose();
    featuresController.dispose();
    amenitiesController.dispose();
    sizeController.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() => _newImages.addAll(picked.map((p) => File(p.path))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _removeUploadedImage(String url) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Remove this image from the room? (image file will remain in storage)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    ) ?? false;

    if (ok) setState(() => _uploadedImages.remove(url));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  Future<void> saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final roomId = widget.roomId ?? const Uuid().v4();

      // Upload new images
      for (final file in List<File>.from(_newImages)) {
        final url = await StorageService.uploadRoomImage(roomId, file);
        _uploadedImages.add(url);
      }

      final price = double.tryParse(priceController.text.trim()) ?? 0.0;
      final capacity = int.tryParse(capacityController.text.trim()) ?? 1;
      final size = double.tryParse(sizeController.text.trim()) ?? 0.0;
      final features = featuresController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final amenities = amenitiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      final room = RoomModel(
        id: roomId,
        hotelId: widget.hotelId,
        name: nameController.text.trim(),
        type: typeController.text.trim(),
        description: descController.text.trim(),
        pricePerNight: price,
        capacity: capacity,
        features: features,
        images: _uploadedImages,
        amenities: amenities,
        isAvailable: _isAvailable,
        size: size,
      );

      final ref = FirebaseFirestore.instance.collection('rooms').doc(roomId);

      if (widget.roomId == null) {
        await ref.set(room.toMap());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room added')));
      } else {
        await ref.update(room.toMap());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room updated')));
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildExistingImagesRow() {
    if (_uploadedImages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Existing Images', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _uploadedImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final url = _uploadedImages[i];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, width: 140, height: 90, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => _removeUploadedImage(url),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.delete, size: 16, color: Colors.white),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewImagesRow() {
    if (_newImages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('New Images (will be uploaded)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _newImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = _newImages[i];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(f, width: 140, height: 90, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => _removeNewImage(i),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ],
    );
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

    final isEdit = widget.roomId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Room' : 'Add Room')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24 : 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Room Name'),
                        validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: typeController,
                        decoration: const InputDecoration(labelText: 'Room Type', hintText: 'e.g. Deluxe, Suite'),
                        validator: (v) => v?.isEmpty ?? true ? 'Type is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Price per night'),
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Price is required';
                          if (double.tryParse(v!) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Capacity (guests)'),
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Capacity required';
                          if (int.tryParse(v!) == null) return 'Enter a whole number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sizeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Size (sq ft)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: featuresController,
                        decoration: const InputDecoration(labelText: 'Features (comma separated)', hintText: 'WiFi, TV, Mini Bar'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amenitiesController,
                        decoration: const InputDecoration(labelText: 'Amenities (comma separated)', hintText: 'AC, Parking, Balcony'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Available'),
                        value: _isAvailable,
                        onChanged: (value) => setState(() => _isAvailable = value),
                      ),
                      const SizedBox(height: 16),
                      _buildExistingImagesRow(),
                      const SizedBox(height: 12),
                      _buildNewImagesRow(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: pickImages,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Pick Images'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                                if (picked != null) setState(() => _newImages.add(File(picked.path)));
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: saveRoom,
                        child: Text(isEdit ? 'Update Room' : 'Add Room'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}