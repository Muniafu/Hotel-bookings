class PaymentModel {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String gatewayReference;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.currency = 'KES',
    this.status = 'pending',
    required this.paymentMethod,
    required this.gatewayReference,
    required this.createdAt,
    this.completedAt,
  });

  PaymentModel copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    String? currency,
    String? status,
    String? paymentMethod,
    String? gatewayReference,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      gatewayReference: gatewayReference ?? this.gatewayReference,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
        id: map['id']?.toString() ?? '',
        bookingId: map['bookingId']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        amount: (map['amount'] ?? 0).toDouble().clamp(0, double.infinity),
        currency: map['currency']?.toString() ?? 'KES',
        status: map['status']?.toString() ?? 'pending',
        paymentMethod: map['paymentMethod']?.toString() ?? '',
        gatewayReference: map['gatewayReference']?.toString() ?? '',
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
        completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookingId': bookingId,
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'status': status,
        'paymentMethod': paymentMethod,
        'gatewayReference': gatewayReference,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };
}