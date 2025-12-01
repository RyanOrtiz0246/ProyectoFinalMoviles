# Base de Datos de la App de Noticias

## Colecciones en Firestore

### /news
- Campos:
    - title: string
    - subtitle: string
    - content: string
    - category: string
    - imageUrl: string
    - authorId: string
    - createdAt: Timestamp
- Documento de prueba: test1

### /categories
- general
- deportes
- economía
- internacional

### /users
- admin
    - name: "Administrador"
    - role: "admin"