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

  // Obtener todos los usuarios
  Stream<QuerySnapshot> getAllUsers() {
    return usersRef.orderBy("createdAt", descending: true).snapshots();
  }

  // Obtener usuarios por rol
  Stream<QuerySnapshot> getUsersByRole(String role) {
    return usersRef
        .where("role", isEqualTo: role)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // Obtener un usuario por id
  Future<DocumentSnapshot> getUserById(String id) {
    return usersRef.doc(id).get();
  }

  // Escuchar cambios de un usuario por id
  Stream<DocumentSnapshot> streamUserById(String id) {
    return usersRef.doc(id).snapshots();
  }

  // Actualizar usuario
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await usersRef.doc(id).update(data);
  }

  // Eliminar usuario
  Future<void> deleteUser(String id) async {
    await usersRef.doc(id).delete();
  }
}
