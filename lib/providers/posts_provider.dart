import 'package:flutter/foundation.dart';
import '../models/post.dart';

class PostsProvider extends ChangeNotifier {
  List<Post> _posts = [];

  List<Post> get posts => _posts;

  void addPost(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void updatePost(Post post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index >= 0) {
      _posts[index] = post;
      notifyListeners();
    }
  }

  void deletePost(int id) {
    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void setPosts(List<Post> posts) {
    _posts = posts;
    notifyListeners();
  }
}
