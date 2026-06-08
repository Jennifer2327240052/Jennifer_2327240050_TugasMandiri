import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anabulcare/models/post.dart';
import 'package:anabulcare/services/post_service.dart';
import 'package:anabulcare/screens/add_post_screen.dart';
import 'package:anabulcare/screens/sign_in_screen.dart';
import 'package:anabulcare/widgets/post_list_item.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Selamat Datang, Admin!",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1A5F7A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Keluar",
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('admin_logged_in');
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              // Arahkan kembali ke halaman Sign In setelah logout
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Deskripsi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Color(0xFFEAF4F7),
            child: const Text(
              "Kelola seluruh daftar laporan hewan hilang yang terdaftar melalui halaman ini.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              "Daftar Hewan Hilang",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Memuat daftar postingan secara real-time
          Expanded(
            child: StreamBuilder<List<Post>>(
              // Mengambil seluruh data post
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

                // Mengambil seluruh data post tanpa filter userId agar tersinkronisasi dengan UserHomeScreen
                final adminPosts = snapshot.data ?? [];

                if (adminPosts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Belum ada laporan hewan hilang yang terdaftar.\nKetuk tombol (+) di bawah untuk menambahkan.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: adminPosts.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final post = adminPosts[index];

                    // Menggunakan widget card bawaan proyek Anda untuk menampilkan item
                    // isOwner diatur true agar admin memiliki hak akses edit/hapus pada semua laporan
                    return PostListItem(post: post, isOwner: true);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Tombol mengarah ke halaman add_post_screen.dart dengan membawa data role Admin
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF1A5F7A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () async {
          // Menunggu hasil kembalian jika ada refresh data (pop bawa nilai true)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddPostScreen(isAdmin: true), // Mode Admin aktif
            ),
          );

          if (result == true) {
            setState(() {});
          }
        },
      ),
    );
  }
}
