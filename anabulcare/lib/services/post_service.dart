import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:anabulcare/models/post.dart';

class PostService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _postsCollection = _database.collection(
    'posts',
  );

  static Future<void> addPost(Post post) async {
    Map<String, dynamic> newPost = {
      'name': post.name,
      'image': post.image,
      'description': post.description,
      'category': post.category,
      'latitude': post.latitude,
      'longitude': post.longitude,
      'operationalHours': post.operationalHours,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'user_id': post.userId,
      'user_full_name': post.userFullName,
    };
    await _postsCollection.add(newPost);
  }

  static Future<void> updatPost(Post post) async {
    Map<String, dynamic> updatedPost = {
      'image': post.image,
      'description': post.description,
      'category': post.category,
      'latitude': post.latitude,
      'longitude': post.longitude,
      'operationalHours': post.operationalHours,
      'created_at': post.createdAt,
      'updated_at': FieldValue.serverTimestamp(),
      'user_id': post.userId,
      'user_full_name': post.userFullName,
    };

    await _postsCollection.doc(post.id).update(updatedPost);
  }

  static Future<void> deletePost(Post post) async {
    await _postsCollection.doc(post.id).delete();
  }

  static Future<QuerySnapshot> retrievePost() {
    return _postsCollection.get();
  }

  static Stream<List<Post>> getPostList() {
    return _postsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Post(
          id: doc.id,
          image: data['image'],
          name: data['name'],
          description: data['description'],
          category: data['category'],
          createdAt: data['created_at'] != null
              ? data['created_at'] as Timestamp
              : null,
          updatedAt: data['updated_at'] != null
              ? data['updated_at'] as Timestamp
              : null,
          latitude: data['latitude'],
          longitude: data['longitude'],
          operationalHours:
              data['operationalHours'] ?? data['operational_hours'],
          userId: data['user_id'],
          userFullName: data['user_full_name'],
        );
        // create function getPostListByCategory dng parameter category
      }).toList();
    });
  }

  static Stream<List<Post>> getPostListByCategory(String category) {
    Query query = _postsCollection;
    if (category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Post(
          id: doc.id,
          image: data['image'],
          name: data['name'],
          description: data['description'],
          category: data['category'],
          createdAt: data['created_at'] != null
              ? data['created_at'] as Timestamp
              : null,
          updatedAt: data['updated_at'] != null
              ? data['updated_at'] as Timestamp
              : null,
          latitude: data['latitude'],
          longitude: data['longitude'],
          operationalHours:
              data['operationalHours'] ?? data['operational_hours'],
          userId: data['user_id'],
          userFullName: data['user_full_name'],
        );
      }).toList();
    });
  }

  void getPostsStream() {}

  static Future<void> createPost(Post newPost) async {}

  static Future<void> addReviewToCoffeeShop({
    required String coffeeShopId,
    required Map<String, Object?> reviewData,
  }) async {
    final reviewCollection = _postsCollection
        .doc(coffeeShopId)
        .collection('reviews');

    final Map<String, dynamic> reviewToSave = {
      ...reviewData,
      'created_at': FieldValue.serverTimestamp(),
    };

    await reviewCollection.add(reviewToSave);
  }

  static Stream<List<Map<String, dynamic>>> getReviewsForCoffeeShop(
    String coffeeShopId,
  ) {
    return _postsCollection
        .doc(coffeeShopId)
        .collection('reviews')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return doc.data() as Map<String, dynamic>;
          }).toList();
        });
  }
}
