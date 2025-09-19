class ReviewModel {
  final String id;
  final String bookingId;
  final double rating;
  final String comment;
  final DateTime date;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
        id: map['id']?.toString() ?? '',
        bookingId: map['bookingId']?.toString() ?? '',
        rating: (map['rating'] ?? 0).toDouble().clamp(0, 5),
        comment: map['comment']?.toString() ?? '',
        date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
        'date': date.toIso8601String(),
      };
}