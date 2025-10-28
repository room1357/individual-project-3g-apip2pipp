import 'package:flutter/material.dart';
import '../client/rest_client.dart';
import '../services/post_service.dart';
import '../models/post.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  late final RestClient _client;
  late final PostService _service;
  List<Post> _posts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _client = RestClient();
    _service = PostService(_client);
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
    });
    try {
      final posts = await _service.list(limit: 50);
      if (!mounted) return;
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load posts: $e')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final userIdCtl = TextEditingController();
    final titleCtl = TextEditingController();
    final bodyCtl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create Post'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: userIdCtl,
                    decoration: const InputDecoration(labelText: 'User ID'),
                    keyboardType: TextInputType.number,
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'User ID is required'
                                : null,
                  ),
                  TextFormField(
                    controller: titleCtl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator:
                        (v) =>
                            v == null || v.isEmpty ? 'Title is required' : null,
                  ),
                  TextFormField(
                    controller: bodyCtl,
                    decoration: const InputDecoration(labelText: 'Body'),
                    maxLines: 3,
                    validator:
                        (v) =>
                            v == null || v.isEmpty ? 'Body is required' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );

    if (result == true) {
      final userId = int.tryParse(userIdCtl.text) ?? 0;
      final post = Post(
        userId: userId,
        title: titleCtl.text,
        body: bodyCtl.text,
      );

      // Optimistic insert
      final tmp = Post(
        id: null,
        userId: post.userId,
        title: post.title,
        body: post.body,
      );
      if (!mounted) return;
      setState(() {
        _posts.insert(0, tmp);
      });

      try {
        final created = await _service.create(post);
        if (!mounted) return;
        setState(() {
          _posts[0] = created;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post created')));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _posts.removeAt(0);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
      }
    }
  }

  Future<void> _showEditDialog(int index) async {
    final post = _posts[index];
    final titleCtl = TextEditingController(text: post.title);
    final bodyCtl = TextEditingController(text: post.body);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Post'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator:
                        (v) =>
                            v == null || v.isEmpty ? 'Title is required' : null,
                  ),
                  TextFormField(
                    controller: bodyCtl,
                    decoration: const InputDecoration(labelText: 'Body'),
                    maxLines: 3,
                    validator:
                        (v) =>
                            v == null || v.isEmpty ? 'Body is required' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result == true) {
      final updated = Post(
        id: post.id,
        userId: post.userId,
        title: titleCtl.text,
        body: bodyCtl.text,
      );

      // optimistic update
      setState(() {
        _posts[index] = updated;
      });

      try {
        final saved = await _service.update(updated);
        if (!mounted) return;
        setState(() {
          _posts[index] = saved;
        });
      } catch (e) {
        if (!mounted) return;
        await _loadPosts();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update post: $e')));
      }
    }
  }

  Future<void> _deletePost(int index) async {
    final id = _posts[index].id;
    if (id == null) {
      setState(() {
        _posts.removeAt(index);
      });
      return;
    }

    final removed = _posts[index];
    setState(() {
      _posts.removeAt(index);
    });

    try {
      await _service.delete(id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _posts.insert(index, removed);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return ListTile(
                      title: Text(post.title),
                      subtitle: Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialog(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deletePost(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
