class BookingModel {
  final String id;
  final String userId;
  final String hotelId;
  final String roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final String status;
  final String paymentId;

  BookingModel({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
    required this.status,
    required this.paymentId,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
        id: map['id']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        hotelId: map['hotelId']?.toString() ?? '',
        roomId: map['roomId']?.toString() ?? '',
        checkIn: map['checkIn'] != null ? DateTime.tryParse(map['checkIn']) ?? DateTime.now() : DateTime.now(),
        checkOut: map['checkOut'] != null ? DateTime.tryParse(map['checkOut']) ?? DateTime.now() : DateTime.now(),
        guests: (map['guests'] ?? 1).toInt().clamp(1, 100),
        totalPrice: (map['totalPrice'] ?? 0).toDouble().clamp(0, double.infinity),
        status: map['status']?.toString() ?? 'pending',
        paymentId: map['paymentId']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'hotelId': hotelId,
        'roomId': roomId,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'guests': guests,
        'totalPrice': totalPrice,
        'status': status,
        'paymentId': paymentId,
      };
}