import 'dart:convert';
import 'dart:math' show max;
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../services/storage/post_storage.dart';

class RestClient {
  late final PostStorage _storage;
  int _nextId = 1;

  RestClient() {
    _init();
  }

  Future<void> _init() async {
    _storage = await PostStorage.create();
    final posts = _storage.getPosts();
    if (posts.isNotEmpty) {
      _nextId = posts.map((p) => p.id ?? 0).reduce(max) + 1;
    }
  }

  Future<List<Post>> fetchPosts({int? limit}) async {
    try {
      // Selalu coba ambil dari API dulu
      final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        final posts =
            data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();

        // Gabungkan dengan data yang sudah ada di storage
        final storedPosts = _storage.getPosts();
        final combinedPosts = [...posts, ...storedPosts];

        // Update storage dengan data gabungan
        await _storage.savePosts(combinedPosts);

        if (limit != null && limit > 0) {
          return combinedPosts.take(limit).toList();
        }
        return combinedPosts;
      }
    } catch (e) {
      // Jika gagal ambil dari API, coba ambil dari storage
      final storedPosts = _storage.getPosts();
      if (storedPosts.isNotEmpty) {
        if (limit != null && limit > 0) {
          return storedPosts.take(limit).toList();
        }
        return storedPosts;
      }
    }

    // Jika semua gagal, kembalikan list kosong
    return [];
  }

  Future<Post> fetchPost(int id) async {
    final posts = _storage.getPosts();
    final post = posts.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Post not found'),
    );
    return post;
  }

  Future<Post> createPost(Post post) async {
    final posts = _storage.getPosts();
    final newPost = Post(
      id: _nextId++,
      userId: post.userId,
      title: post.title,
      body: post.body,
    );
    posts.insert(0, newPost);
    await _storage.savePosts(posts);
    return newPost;
  }

  Future<Post> updatePost(Post post) async {
    if (post.id == null) {
      throw ArgumentError('Post.id must be provided to update');
    }
    final posts = _storage.getPosts();
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index < 0) throw Exception('Post not found');

    posts[index] = post;
    await _storage.savePosts(posts);
    return post;
  }

  Future<void> deletePost(int id) async {
    final posts = _storage.getPosts();
    posts.removeWhere((p) => p.id == id);
    await _storage.savePosts(posts);
  }

  void close() {}
}
