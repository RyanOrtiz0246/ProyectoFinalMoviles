import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  // Crear usuario
  Future<String> createUser({
    required String name,
    required String role,
  }) async {
    final doc = await usersRef.add({
      "name": name,
      "role": role,
      "createdAt": FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // Obtener un usuario por id
  Future<DocumentSnapshot> getUserById(String id) {
    return usersRef.doc(id).get();
  }

  Future<String> getUserName(String id) async {
    final snapshot = await getUserById(id);

    // documento no existe
    if (!snapshot.exists) {
      return "Desconocido";
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    return data?['name'];
  }
}
