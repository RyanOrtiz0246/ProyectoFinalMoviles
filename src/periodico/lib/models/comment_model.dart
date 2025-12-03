import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String newsId;
  final String userId;
  final String text;
  final DateTime? date;

  Comment({
    required this.id,
    required this.newsId,
    required this.userId,
    required this.text,
    this.date,
  });

  factory Comment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    Timestamp? ts = data['date'] as Timestamp?;
    return Comment(
      id: doc.id,
      newsId: data['newsId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      date: ts?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'newsId': newsId,
      'userId': userId,
      'text': text,
      'date': date != null
          ? Timestamp.fromDate(date!)
          : FieldValue.serverTimestamp(),
    };
  }
}
