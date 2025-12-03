import 'dart:math';

import 'package:flutter/material.dart';
import 'package:periodico/models/comment_model.dart';
import 'package:periodico/services/comment_service.dart';
import 'package:periodico/services/user_service.dart';

class NewsDetailModal extends StatefulWidget {
  final String newsId;
  final String title;
  final String? body;

  const NewsDetailModal({
    Key? key,
    required this.newsId,
    required this.title,
    this.body,
  }) : super(key: key);

  static Future show(
    BuildContext context, {
    required String newsId,
    required String title,
    String? body,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: NewsDetailModal(newsId: newsId, title: title, body: body),
      ),
    );
  }

  @override
  State<NewsDetailModal> createState() => _NewsDetailModalState();
}

class _NewsDetailModalState extends State<NewsDetailModal> {
  final CommentService _commentService = CommentService();
  final UserService _userService = UserService();
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _commentService.addComment(
        newsId: widget.newsId,
        userId: 'user${(Random().nextInt(5) + 1)}',
        text: text,
      );
      _controller.clear();
      // opcional: cerrar teclado
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar el comentario.')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return date.toLocal().toString();
  }

  Widget _buildCommentsList(
    List<Comment> comments,
    ScrollController scrollController,
  ) {
    return ListView.separated(
      controller: scrollController,
      itemCount: comments.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final comment = comments[index];

        return ListTile(
          leading: CircleAvatar(
            child: Text(
              _initialsFromUserId(comment.userId),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: FutureBuilder<String>(
            future: _userService.getUserName(comment.userId),
            builder: (context, userSnap) {
              final name = userSnap.data ?? 'Desconocido';
              return Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            },
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(comment.text),
              const SizedBox(height: 6),
              Text(
                _formatDate(comment.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (widget.body != null) ...[
                  SizedBox(height: 8),
                  Text(widget.body!),
                ],
                SizedBox(height: 12),

                // Comentarios: stream
                Expanded(
                  child: StreamBuilder<List<Comment>>(
                    stream: _commentService.getCommentsByNews(widget.newsId),
                    builder: (context, snapshot) {
                      // Si hay error en el stream, intentamos un fallback con una consulta puntual
                      if (snapshot.hasError) {
                        return FutureBuilder<List<Comment>>(
                          future: _commentService.fetchCommentsByNewsOnce(
                            widget.newsId,
                          ),
                          builder: (context, futSnap) {
                            if (futSnap.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (futSnap.hasError) {
                              // Mostramos mensaje de error explícito para depuración/usuario
                              return Center(
                                child: Text(
                                  'Error al cargar comentarios: ${snapshot.error}\nIntento fallback: ${futSnap.error}',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            final comments = futSnap.data ?? [];
                            if (comments.isEmpty) {
                              return const Center(
                                child: Text('Sé el primero en comentar.'),
                              );
                            }
                            return _buildCommentsList(
                              comments,
                              scrollController,
                            );
                          },
                        );
                      }

                      // Stream aún no ha entregado datos
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final comments = snapshot.data!;
                      if (comments.isEmpty) {
                        return const Center(
                          child: Text('Sé el primero en comentar.'),
                        );
                      }

                      return _buildCommentsList(comments, scrollController);
                    },
                  ),
                ),

                // Input para nuevo comentario
                SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(),
                          decoration: InputDecoration(
                            hintText: 'Escribe un comentario...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      _isSending
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _sendComment,
                              icon: Icon(Icons.send),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  final Map<String, String> _initialsCache = {};

  String _initialsFromUserId(String userId) {
    if (userId.isEmpty) return '?';

    // Si ya lo tenemos en cache, devolverlo
    if (_initialsCache.containsKey(userId)) return _initialsCache[userId]!;

    _userService
        .getUserName(userId)
        .then((name) {
          final initials = _computeInitialsFromName(name);
          if (mounted) {
            setState(() {
              _initialsCache[userId] = initials;
            });
          }
        })
        .catchError((_) {
          if (mounted) {
            setState(() {
              _initialsCache[userId] = userId.substring(0, 1).toUpperCase();
            });
          }
        });

    return userId.substring(0, 1).toUpperCase();
  }

  String _computeInitialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
