import 'package:flutter/material.dart';
import 'package:periodico/services/news_service.dart';

class CreateNewsView extends StatefulWidget {
  const CreateNewsView({super.key});

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
  
  // Por simplicidad, usaremos un ID manual o fijo, ya que no hay sistema de Auth completo visible aún.
  // Puedes cambiar esto por el ID del usuario logueado si implementas Auth más adelante.
  final TextEditingController _authorIdCtrl = TextEditingController(); 

  // Categorías según tu DATABASE.md
  final List<String> _categories = [
    'general',
    'deportes',
    'economía',
    'internacional'
  ];
  String? _selectedCategory;

  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      setState(() => _isLoading = true);

      try {
        await _newsService.createNews(
          title: _titleCtrl.text.trim(),
          subtitle: _subtitleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          category: _selectedCategory!,
          imageUrl: _imageUrlCtrl.text.trim(),
          authorId: _authorIdCtrl.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Noticia creada con éxito')),
          );
          Navigator.pop(context, true); // Retorna true para indicar que se creó algo
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
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
      appBar: AppBar(title: const Text('Crear Noticia')),
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
                decoration: const InputDecoration(labelText: 'URL de la Imagen'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _authorIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'ID del Autor (ej: usuario1)',
                  helperText: 'Debe existir en la colección users para ver el nombre',
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