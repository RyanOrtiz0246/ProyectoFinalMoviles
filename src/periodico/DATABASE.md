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

### /users
- Campos
    - name: string
    - role: string
- Documento existentes: admin 1-3, reportero 1-5, usuarios 1-5

### /comments
- Campos:
    - userId: string
    - newsId: string
    - text: string
    - date: Timestamp
