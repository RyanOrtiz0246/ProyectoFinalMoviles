import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ajusta la importación según la ubicación real de news_service.dart
import 'package:periodico/services/news_service.dart';
import 'package:periodico/services/user_service.dart';
import 'package:periodico/views/create_news_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _query = '';
  String _selectedCategory = 'Todas';

  List<Map<String, String>> _articles = [];
  bool _loading = true;
  String? _error;

  final NewsService _newsService = NewsService();
  final UserService _userService = UserService();

  List<String> get _categories {
    final cats = <String>{'Todas'};
    for (var a in _articles) {
      final c = a['category'] ?? '';
      if (c.isNotEmpty) cats.add(c);
    }
    return cats.toList();
  }

  List<Map<String, String>> get _filtered {
    return _articles.where((a) {
      final matchesQuery =
          _query.isEmpty ||
          (a['title'] ?? '').toLowerCase().contains(_query.toLowerCase()) ||
          (a['subtitle'] ?? '').toLowerCase().contains(_query.toLowerCase()) ||
          (a['content'] ?? '').toLowerCase().contains(_query.toLowerCase()) ||
          (a['authorId'] ?? '').toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Todas' || a['category'] == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stream = _newsService.getAllNews();
      final snapshot = await stream.first;

      // Mapeamos a Future<Map> y luego esperamos todos
      final futures = snapshot.docs.map((doc) async {
        final map = doc.data() as Map<String, dynamic>;

        // createdAt puede ser Timestamp o DateTime o null
        String time = '';
        final created = map['createdAt'];
        if (created != null) {
          if (created is Timestamp) {
            time = created.toDate().toLocal().toString().split('.').first;
          } else if (created is DateTime) {
            time = created.toLocal().toString().split('.').first;
          } else {
            time = created.toString();
          }
        }

        // Asegúrate de convertir authorId a String y prevenir null
        final authorId = (map['authorId'] ?? '').toString();

        // Esperamos el nombre del autor (esta llamada es async)
        String authorName;
        try {
          authorName = await _userService.getUserName(authorId);
        } catch (_) {
          authorName = 'Desconocido';
        }

        return <String, String>{
          'id': doc.id,
          'title': (map['title'] ?? '').toString(),
          'subtitle': (map['subtitle'] ?? '').toString(),
          'content': (map['content'] ?? '').toString(),
          'imageUrl': (map['imageUrl'] ?? '').toString(),
          'category': (map['category'] ?? '').toString(),
          'authorId':
              authorId, //Agregue aqui esta linea para poder editar luego
          'authorName': authorName,
          'time': time,
        };
      }).toList();

      // Await all los futures en paralelo
      final List<Map<String, String>> data = await Future.wait(futures);

      if (!mounted) return;
      setState(() {
        _articles = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar noticias';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadArticles();
  }

  void _showFullContent(Map<String, String> article) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(article['title'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((article['imageUrl'] ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article['imageUrl']!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                article['subtitle'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(article['content'] ?? ''),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Autor: ${article['authorName'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Text(
                    article['time'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // BOTÓN ELIMINAR
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Confirmación simple
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Confirmar Eliminación'),
                  content: const Text(
                    '¿Estás seguro de que deseas eliminar esta noticia? Esta acción no se puede deshacer.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Borramos usando el ID
                await _newsService.deleteNews(article['id']!);
                if (mounted) {
                  Navigator.pop(context); // Cerrar el diálogo de detalle
                  _loadArticles(); // Recargar la lista
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Noticia eliminada')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),

          // BOTÓN EDITAR
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar el diálogo de detalle primero

              // Navegar a la pantalla de crear, pero enviando la noticia para editar
              final bool? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateNewsView(article: article), // Pasamos la noticia
                ),
              );

              if (result == true) {
                _loadArticles(); // Recargamos si hubo cambios
              }
            },
            child: const Text('Editar'),
          ),

          // BOTÓN CERRAR
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de Noticias'),
        centerTitle: false,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegar a la pantalla de crear
          final bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateNewsView()),
          );

          // Si retornamos 'true', recargamos las noticias
          if (result == true) {
            _loadArticles();
          }
        },
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar noticias, temas o autores',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : Colors.grey[900],
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading && _articles.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _articles.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadArticles,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: _filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'No se encontraron noticias',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final a = _filtered[index];
                                return InkWell(
                                  onTap: () => _showFullContent(a),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: (a['imageUrl'] ?? '').isNotEmpty
                                            ? Image.network(
                                                a['imageUrl']!,
                                                width: 110,
                                                height: 70,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      width: 110,
                                                      height: 70,
                                                      color: Colors.grey,
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                width: 110,
                                                height: 70,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.image),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a['title'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              a['subtitle'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              a['content'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  a['category'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey[600],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Autor: ${a['authorName'] ?? ''}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  a['time'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
