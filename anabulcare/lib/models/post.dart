import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String? id;
  String? image;
  String? name;
  String? description;
  String? category;
  String? ownerPhone;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  String? latitude;
  String? longitude;
  String? operationalHours;
  String? userId;
  String? userFullName;

  Post({
    this.id,
    this.image,
    this.name,
    this.description,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.operationalHours,
    this.userId,
    this.userFullName,
    this.ownerPhone,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      image: map['image'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      createdAt: map['createdAt'] ?? map['created_at'],
      updatedAt: map['updatedAt'] ?? map['updated_at'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      operationalHours: map['operationalHours'] ?? map['operational_hours'],
      userId: map['userId'] ?? map['user_id'],
      userFullName: map['userFullName'] ?? map['user_full_name'],
      ownerPhone: map['ownerPhone'] ?? map['owner_phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': image,
      'name': name,
      'description': description,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'latitude': latitude,
      'longitude': longitude,
      'operationalHours': operationalHours,
      'userId': userId,
      'userFullName': userFullName,
      'ownerPhone': ownerPhone,
    };
  }
}
