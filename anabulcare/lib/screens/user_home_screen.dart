import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:anabulcare/models/post.dart';
import 'package:anabulcare/services/post_service.dart';
import 'package:anabulcare/screens/detail_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initGeoLocation();
  }

  // 1. Mengambil izin GPS dan posisi koordinat pengguna saat ini
  Future<void> _initGeoLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      } else {
        // Jika izin ditolak, matikan loading agar aplikasi tidak stuck
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      debugPrint("Gagal memuat lokasi: $e");
      setState(() => _isLoadingLocation = false);
    }
  }

  // 2. Menghitung jarak numerik (meter) antara posisi user dengan koordinat Coffee Shop
  double _getRawDistance(String? latStr, String? lngStr) {
    if (_currentPosition == null || latStr == null || lngStr == null)
      return double.maxFinite;
    double lat = double.tryParse(latStr) ?? 0.0;
    double lng = double.tryParse(lngStr) ?? 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  // 3. Mengubah hasil hitung meter menjadi teks keterangan jarak (Meter / Km) sesuai perintah Anda
  String _getDistanceText(double distanceInMeters) {
    if (distanceInMeters == double.maxFinite) return "- m";
    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toStringAsFixed(0)} meter"; // Contoh: 100 meter
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return "${distanceInKm.toStringAsFixed(1)} km"; // Contoh: 1.5 km
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Coffee Shop",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : Column(
              children: [
                // Kolom Pencarian Nama Kedai Kopi
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Cari kedai kopi...",
                      prefixIcon: const Icon(Icons.search, color: Colors.brown),
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

                // Stream data Coffee Shop global dari Firebase
                Expanded(
                  child: StreamBuilder<List<Post>>(
                    stream: PostService.getPostListByCategory(''),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.brown),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text("Terjadi kesalahan: ${snapshot.error}"),
                        );
                      }

                      var posts = snapshot.data ?? [];

                      // Filter pencarian teks nama kedai kopi
                      if (_searchQuery.isNotEmpty) {
                        posts = posts
                            .where(
                              (p) => (p.name ?? '').toLowerCase().contains(
                                _searchQuery,
                              ),
                            )
                            .toList();
                      }

                      // LOGIKA URUTAN: Mengurutkan otomatis dari jarak yang PALING DEKAT ke PALING JAUH
                      posts.sort((a, b) {
                        double distA = _getRawDistance(a.latitude, a.longitude);
                        double distB = _getRawDistance(b.latitude, b.longitude);
                        return distA.compareTo(distB);
                      });

                      if (posts.isEmpty) {
                        return const Center(
                          child: Text(
                            "Tidak ada coffee shop ditemukan.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: posts.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          // Ambil jarak numerik untuk ditampilkan ke teks pendukung card
                          double distance = _getRawDistance(
                            post.latitude,
                            post.longitude,
                          );

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
                                  // Foto Pratinjau Utama Kedai Kopi
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
                                              Icons.storefront,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),

                                      // BADGE KETERANGAN JARAK AKTUAL (Sesuai Perintah Anda)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.brown.shade800
                                                .withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.near_me,
                                                size: 14,
                                                color: Colors.amberAccent,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _getDistanceText(
                                                  distance,
                                                ), // Menampilkan teks jarak (cth: 100 meter)
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Detail Informasi Singkat pada List Utama
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.name ?? 'Coffee Shop',
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
                                              "Jam Operasional: ${post.operationalHours ?? '-'}",
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
    );
  }
}
