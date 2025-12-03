import 'package:flutter/material.dart';
import 'package:periodico/services/news_service.dart';

class CreateNewsView extends StatefulWidget {
  final Map<String, String>? article;
  const CreateNewsView({super.key, this.article});

  @override
  State<CreateNewsView> createState() => _CreateNewsViewState();
}

class _CreateNewsViewState extends State<CreateNewsView> {
  final _formKey = GlobalKey<FormState>();
  final NewsService _newsService = NewsService();

  // Controladores de texto
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _subtitleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _imageUrlCtrl = TextEditingController();
  final TextEditingController _authorIdCtrl = TextEditingController();

  // Categorías según la DATABASE.md
  final List<String> _categories = [
    'general',
    'deportes',
    'economía',
    'internacional',
    'tecnologia',
  ];
  String? _selectedCategory;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si recibimos una noticia, rellenamos los campos
    if (widget.article != null) {
      _titleCtrl.text = widget.article!['title'] ?? '';
      _subtitleCtrl.text = widget.article!['subtitle'] ?? '';
      _contentCtrl.text = widget.article!['content'] ?? '';
      _imageUrlCtrl.text = widget.article!['imageUrl'] ?? '';
      _authorIdCtrl.text = widget.article!['authorId'] ?? '';

      // Validamos que la categoría exista en nuestra lista
      if (_categories.contains(widget.article!['category'])) {
        _selectedCategory = widget.article!['category'];
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      setState(() => _isLoading = true);

      try {
        final data = {
          "title": _titleCtrl.text.trim(),
          "subtitle": _subtitleCtrl.text.trim(),
          "content": _contentCtrl.text.trim(),
          "category": _selectedCategory!,
          "imageUrl": _imageUrlCtrl.text.trim(),
          "authorId": _authorIdCtrl.text.trim(),
        };

        if (widget.article == null) {
          // --- MODO CREAR ---
          await _newsService.createNews(
            title: data["title"]!,
            subtitle: data["subtitle"]!,
            content: data["content"]!,
            category: data["category"]!,
            imageUrl: data["imageUrl"]!,
            authorId: data["authorId"]!,
          );
        } else {
          // --- MODO EDITAR ---
          // Usamos el ID del documento para actualizar
          await _newsService.updateNews(widget.article!['id']!, data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.article == null ? 'Creada' : 'Actualizada'),
            ),
          );
          Navigator.pop(context, true); // Volver y recargar
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _contentCtrl.dispose();
    _imageUrlCtrl.dispose();
    _authorIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.article == null ? 'Crear Noticia' : 'Editar Noticia',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _subtitleCtrl,
                decoration: const InputDecoration(labelText: 'Subtítulo'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(labelText: 'Contenido'),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de la Imagen',
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _authorIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'ID del Autor (ej: usuario1)',
                  helperText:
                      'Debe existir en la colección users para ver el nombre',
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text('Publicar Noticia'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
