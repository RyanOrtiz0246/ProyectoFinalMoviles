import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:periodico/models/comment_model.dart';

class CommentService {
  final CollectionReference commentsRef = FirebaseFirestore.instance.collection(
    'comments',
  );

  // Añadir comentario
  Future<String> addComment({
    required String newsId,
    required String userId,
    required String text,
  }) async {
    final doc = await commentsRef.add({
      'newsId': newsId,
      'userId': userId,
      'text': text,
      'date': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // Obtener comentarios por noticia
  Stream<List<Comment>> getCommentsByNews(String newsId) {
    var comments = commentsRef
        .where('newsId', isEqualTo: newsId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Comment.fromDoc(doc as DocumentSnapshot))
              .toList(),
        );

    return comments;
  }

  // Obtener comentarios una sola vez
  Future<List<Comment>> fetchCommentsByNewsOnce(String newsId) async {
    final snap = await commentsRef
        .where('newsId', isEqualTo: newsId)
        .orderBy('date', descending: true)
        .get();

    return snap.docs.map((d) => Comment.fromDoc(d)).toList();
  }

  // Borrar comentario
  Future<void> deleteComment(String id) async {
    await commentsRef.doc(id).delete();
  }

  // Actualizar comentario
  Future<void> updateComment(String id, String text) async {
    await commentsRef.doc(id).update({
      'text': text,
      'date': FieldValue.serverTimestamp(),
    });
  }
}
