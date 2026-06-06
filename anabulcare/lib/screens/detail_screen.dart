import 'dart:convert';

import 'package:anabulcare/models/post.dart'; // Sesuaikan jika nama modelnya berubah menjadi coffee_shop.dart
import 'package:anabulcare/screens/add_post_screen.dart';
import 'package:anabulcare/screens/map_detail_screen.dart';
import 'package:anabulcare/services/favorite_service.dart';
import 'package:anabulcare/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class DetailScreen extends StatefulWidget {
  final Post post;

  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;
  late final Stream<List<Map<String, dynamic>>> _reviewStream;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _reviewStream = widget.post.id != null
        ? PostService.getReviewsForCoffeeShop(widget.post.id!)
        : Stream.value([]);
  }

  Future<void> _loadFavoriteStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || widget.post.id == null) return;

    final isFavorite = await FavoriteService.isPostFavorite(
      currentUser.uid,
      widget.post.id!,
    );
    if (!mounted) return;
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login untuk menggunakan favorit.'),
        ),
      );
      return;
    }

    final postId = widget.post.id;
    if (postId == null) return;

    if (_isFavorite) {
      await FavoriteService.removeFavorite(currentUser.uid, postId);
      if (!mounted) return;
      setState(() {
        _isFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coffee shop dihapus dari favorit.')),
      );
    } else {
      await FavoriteService.addFavorite(currentUser.uid, widget.post);
      if (!mounted) return;
      setState(() {
        _isFavorite = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coffee shop ditambahkan ke favorit.')),
      );
    }
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Coffee Shop'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus informasi tempat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PostService.deletePost(widget.post);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _sharePost() {
    final text =
        '☕ ${widget.post.name ?? 'Coffee Shop'}\n📌 Suasana: ${widget.post.category ?? '-'}\n🕒 Jam Buka: ${widget.post.operationalHours ?? '-'}\n\n${widget.post.description ?? ''}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Cek apakah user yang membuka ini adalah admin pemilik postingan kedai kopi
    final isAdmin =
        currentUserId != null && widget.post.userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.name ?? 'Detail Coffee Shop'),
        backgroundColor: Color(0xFF1A5F7A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _sharePost,
            icon: const Icon(Icons.share),
            tooltip: 'Bagikan',
          ),
          if (isAdmin)
            IconButton(
              onPressed: () => _deletePost(context),
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus Kedai (Admin)',
              color: Colors.redAccent,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. GAMBAR COFFEE SHOP ---
            if (widget.post.image != null && widget.post.image!.isNotEmpty)
              Image.memory(
                base64Decode(widget.post.image!),
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 250,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. NAMA & KARAKTERISTIK ---
                  Text(
                    widget.post.name ?? 'Nama Kafe Tidak Tersedia',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5F7A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.post.category != null)
                    Chip(
                      label: Text(widget.post.category!),
                      backgroundColor: Color(0xFFEAF4F7),
                      labelStyle: TextStyle(
                        color: Color(0xFF375F74),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // --- 3. WAKTU / JAM OPERASIONAL ---
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Jam Operasional: ${widget.post.operationalHours?.trim().isNotEmpty == true ? widget.post.operationalHours : 'Tidak ditentukan'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- 4. LOKASI COORD MARKER ---
                  if (widget.post.latitude != null &&
                      widget.post.longitude != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Koordinat Maps: ${widget.post.latitude}, ${widget.post.longitude}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // --- 5. DESKRIPSI (HASIL GENERATE AI / MANUAL ADMIN) ---
                  const Text(
                    'Tentang Coffee Shop:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5F7A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.post.description ??
                        'Belum ada deskripsi untuk coffee shop ini.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- 6. RUTE GOOGLE MAPS ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapDetailScreen(post: widget.post),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1A5F7A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: const Text(
                        'Lihat Rute di Google Maps',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),

                  if (currentUserId != null &&
                      currentUserId != widget.post.userId) ...[
                    // --- 7. INTERAKSI LIKE ---
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                        ),
                        Text(
                          _isFavorite ? 'Favorit' : 'Tambah ke favorit',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],

                  // --- 8. BAGIAN ULASAN PENGGUNA (TAMPIL UNTUK SEMUA, TOMBOL HANYA UNTUK PENGGUNA) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ulasan Pengunjung',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A5F7A),
                        ),
                      ),
                      if (currentUserId != null &&
                          currentUserId != widget.post.userId)
                        TextButton.icon(
                          onPressed: () async {
                            // Berpindah ke AddPostScreen dengan mode Pengguna (isAdmin: false)
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddPostScreen(
                                  isAdmin: false,
                                  coffeeShop:
                                      widget.post, // Kirim data toko saat ini
                                ),
                              ),
                            );

                            if (result == true) {
                              // Segarkan data ulasan jika pengguna sukses memposting ulasan baru
                              setState(() {});
                            }
                          },
                          icon: const Icon(
                            Icons.rate_review,
                            color: Color(0xFF1A5F7A),
                          ),
                          label: const Text(
                            "Beri Ulasan",
                            style: TextStyle(
                              color: Color(0xFF1A5F7A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _reviewStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Belum ada ulasan.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      final reviewCount = reviews.length;
                      final totalRating = reviews.fold<double>(0.0, (
                        sum,
                        review,
                      ) {
                        final ratingValue = review['rating'];
                        if (ratingValue is num) {
                          return sum + ratingValue.toDouble();
                        }
                        if (ratingValue is String) {
                          return sum + (double.tryParse(ratingValue) ?? 0.0);
                        }
                        return sum;
                      });
                      final averageRating = reviewCount > 0
                          ? totalRating / reviewCount
                          : 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$reviewCount ulasan',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (averageRating > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEAF4F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...reviews.map((review) {
                            final userName = review['userName'] ?? 'Pengunjung';
                            final ratingValue = review['rating'];
                            final comment = review['comment'] ?? '';
                            final rating = ratingValue is num
                                ? ratingValue.toInt()
                                : int.tryParse(ratingValue?.toString() ?? '') ??
                                      0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              elevation: 0.5,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              backgroundColor: Color(0xFF1A5F7A),
                                              radius: 14,
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              userName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: List.generate(5, (
                                            starIndex,
                                          ) {
                                            return Icon(
                                              starIndex < rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 14,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      comment,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

