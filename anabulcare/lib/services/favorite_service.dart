import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:anabulcare/models/post.dart';

class FavoriteService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;

  static Stream<List<Post>> getFavoritePosts(String uid) {
    final favoritesCollection = _database
        .collection('users')
        .doc(uid)
        .collection('favorites');

    return favoritesCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Post(
              id: doc.id,
              image: data['image'],
              name: data['name'],
              description: data['description'],
              category: data['category'],
              createdAt: data['created_at'] as Timestamp?,
              updatedAt: data['updated_at'] as Timestamp?,
              latitude: data['latitude'],
              longitude: data['longitude'],
              operationalHours:
                  data['operationalHours'] ?? data['operational_hours'],
              userId: data['user_id'] ?? data['userId'],
              userFullName: data['user_full_name'] ?? data['userFullName'],
            );
          }).toList();
        });
  }

  static Future<bool> isPostFavorite(String uid, String postId) async {
    final doc = await _database
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(postId)
        .get();
    return doc.exists;
  }

  static Future<void> addFavorite(String uid, Post post) async {
    if (post.id == null) return;

    final favoriteDoc = _database
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(post.id);

    await favoriteDoc.set({
      'post_id': post.id,
      'image': post.image,
      'name': post.name,
      'description': post.description,
      'category': post.category,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'latitude': post.latitude,
      'longitude': post.longitude,
      'operationalHours': post.operationalHours,
      'user_id': post.userId,
      'user_full_name': post.userFullName,
    });
  }

  static Future<void> removeFavorite(String uid, String postId) async {
    await _database
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(postId)
        .delete();
  }
}
