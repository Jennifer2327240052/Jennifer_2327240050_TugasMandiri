import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:anabulcare/models/post.dart';
import 'package:anabulcare/services/post_service.dart';
import 'package:anabulcare/screens/detail_screen.dart';
import 'package:anabulcare/screens/add_post_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Anabul Care",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1A5F7A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Kolom Pencarian Laporan Hewan Hilang
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari hewan hilang...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A5F7A)),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Stream data laporan hewan hilang dari Firebase
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: PostService.getPostListByCategory(''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A5F7A)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Terjadi kesalahan: ${snapshot.error}"),
                  );
                }

                var posts = snapshot.data ?? [];

                // Filter pencarian teks nama hewan atau deskripsi laporan
                if (_searchQuery.isNotEmpty) {
                  posts = posts.where((p) {
                    final name = p.name?.toLowerCase() ?? '';
                    final description = p.description?.toLowerCase() ?? '';
                    final category = p.category?.toLowerCase() ?? '';
                    return name.contains(_searchQuery) ||
                        description.contains(_searchQuery) ||
                        category.contains(_searchQuery);
                  }).toList();
                }

                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      "Tidak ada hewan hilang ditemukan.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      elevation: 2,
                      child: InkWell(
                        // Sesuai perintah: Data post dikirim utuh ke detail_screen.dart saat diklik
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(post: post),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto Pratinjau Utama
                            Stack(
                              children: [
                                if (post.image != null &&
                                    post.image!.isNotEmpty)
                                  Image.memory(
                                    base64Decode(post.image!),
                                    width: double.infinity,
                                    height: 170,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Container(
                                    height: 170,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.pets,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // Detail Informasi Singkat pada List Utama
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.name ?? 'Hewan Hilang',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_filled,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Waktu Laporan: ${post.operationalHours ?? '-'}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A5F7A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Laporkan Hewan Hilang'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPostScreen(isAdmin: false),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}
