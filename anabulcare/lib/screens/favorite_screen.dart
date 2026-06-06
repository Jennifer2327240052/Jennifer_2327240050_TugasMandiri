import 'dart:convert';

import 'package:anabulcare/models/post.dart';
import 'package:anabulcare/screens/detail_screen.dart';
import 'package:anabulcare/services/favorite_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Shop Favorit'),
        backgroundColor: Colors.brown,
      ),
      body: currentUser == null
          ? const Center(
              child: Text(
                'Silakan login terlebih dahulu untuk melihat favorit.',
              ),
            )
          : StreamBuilder<List<Post>>(
              stream: FavoriteService.getFavoritePosts(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.brown),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );
                }

                final favoritePosts = snapshot.data ?? [];
                if (favoritePosts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada coffee shop favorit. Tambahkan dari halaman detail.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: favoritePosts.length,
                  itemBuilder: (context, index) {
                    final post = favoritePosts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(post: post),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.image != null && post.image!.isNotEmpty)
                              Image.memory(
                                base64Decode(post.image!),
                                width: double.infinity,
                                height: 170,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 170,
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 170,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.storefront,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.name ?? 'Coffee Shop',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    post.operationalHours ??
                                        'Jam operasional belum tersedia',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
