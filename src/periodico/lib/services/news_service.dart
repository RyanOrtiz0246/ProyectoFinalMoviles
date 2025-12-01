import 'package:cloud_firestore/cloud_firestore.dart';

class NewsService {
  final CollectionReference newsRef =
  FirebaseFirestore.instance.collection('news');

  // Agregar noticia
  Future<String> createNews({
    required String title,
    required String subtitle,
    required String content,
    required String category,
    required String imageUrl,
    required String authorId,
  }) async {
    final doc = await newsRef.add({
      "title": title,
      "subtitle": subtitle,
      "content": content,
      "category": category,
      "imageUrl": imageUrl,
      "authorId": authorId,
      "createdAt": FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // Mostrar todas las noticias
  Stream<QuerySnapshot> getAllNews() {
    return newsRef.orderBy("createdAt", descending: true).snapshots();
  }

  // Filtrar noticias por categoría
  Stream<QuerySnapshot> getNewsByCategory(String category) {
    return newsRef
        .where("category", isEqualTo: category)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // Filtrar noticias por autor
  Stream<QuerySnapshot> getNewsByAuthor(String authorId) {
    return newsRef
        .where("authorId", isEqualTo: authorId)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // Editar noticia
  Future<void> updateNews(String id, Map<String, dynamic> data) async {
    await newsRef.doc(id).update(data);
  }

  // Eliminar noticia
  Future<void> deleteNews(String id) async {
    await newsRef.doc(id).delete();
  }

  // Insertar una noticia de ejemplo
  Future<void> seedExample() async {
    await createNews(
      title: "Noticia de ejemplo",
      subtitle: "Subtítulo de prueba",
      content: "Contenido de test para comprobar la base de datos.",
      category: "general",
      imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/News.jpg/640px-News.jpg",
      authorId: "admin",
    );
  }
}
