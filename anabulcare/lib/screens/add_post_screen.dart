import 'dart:convert';

import 'package:anabulcare/models/post.dart';
import 'package:anabulcare/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ditambahkan untuk TextInputFormatter
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  final bool
  isAdmin; // True: Admin tambah laporan, False: Pengguna lapor hewan hilang
  final Post? coffeeShop; // tidak digunakan untuk laporan pengguna baru

  const AddPostScreen({super.key, required this.isAdmin, this.coffeeShop});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();

  // Controller tambahan untuk mode pengguna lama, tidak dipakai lagi
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0; // Default rating bintang adalah 0

  String? _base64Image;
  String? _latitude;
  String? _longitude;
  String? _category;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  bool _isGenerating = false;
  bool _isEditing = false;

  // Kategori disesuaikan dengan jenis hewan hilang
  List<String> get categories {
    return ['Kucing', 'Anjing', 'Burung', 'Kelinci', 'Reptil', 'Lainnya'];
  }

  // 1. Fungsi pick, dan convert Image
  Future<void> pickImageAndConvert() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
        // AI otomatis mendeskripsikan suasana hanya jika dijalankan oleh Admin
        if (widget.isAdmin) {
          _generateDescriptionWithAI();
        }
      });
    }
  }

  // 2. Fungsi Get Geo Location (Untuk mengukur jarak meter ke pengguna nantinya)
  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Layanan lokasi dinonaktifkan.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Izin lokasi ditolak atau tidak tersedia."),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
        _latitudeController.text = _latitude!;
        _longitudeController.text = _longitude!;
      });
    } catch (e) {
      debugPrint('Failed to retrieve location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal mengambil lokasi. Pastikan izin lokasi sudah diberikan.",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // 3. Fungsi tampil pilihan kategori
  void _showCategorySelect() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((cat) {
            return ListTile(
              title: Text(cat),
              onTap: () {
                setState(() {
                  _category = cat;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  // 4. Widget tampil gambar
  Widget _buildImagePreview() {
    if (_base64Image == null) {
      return Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          widget.isAdmin
              ? 'Belum ada foto laporan dipilih'
              : 'Belum ada foto laporan dipilih (Opsional)',
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        base64Decode(_base64Image!),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  // 5. Widget tampil koordinat lokasi
  Widget _buildLocationInfo() {
    if (_latitude == null || _longitude == null) {
      return const Text('Koordinat lokasi belum diambil');
    }

    return Text(
      'Koordinat Terpasang:\nLat: $_latitude | Lng: $_longitude',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
    );
  }

  // 6. Fungsi submit Post atau Ulasan (Disesuaikan berdasarkan Role)
  Future<void> _submitPost() async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    final adminName = FirebaseAuth.instance.currentUser?.displayName;

    if (widget.isAdmin) {
      final isEditingNow = _isEditing && widget.coffeeShop != null;
      // ---------------- LOGIKA SUBMIT ADMIN ----------------
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan nama atau jenis hewan hilang.'),
          ),
        );
        return;
      }
      if (_base64Image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pilih foto hewan atau lokasi terakhir terlebih dahulu.',
            ),
          ),
        );
        return;
      }
      if (_category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenis hewan terlebih dahulu.')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        _updateLocationFromManualInput();

        if (_latitude == null || _longitude == null) {
          await _getLocation();
        }

        if (_latitude == null || _longitude == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Harap ambil atau masukkan lokasi hewan hilang terlebih dahulu.',
              ),
            ),
          );
          return;
        }

        if (!_isValidCoordinate(_latitude) || !_isValidCoordinate(_longitude)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Koordinat tidak valid. Pastikan latitude dan longitude berupa angka.',
              ),
            ),
          );
          return;
        }

        final postToSave = Post(
          id: isEditingNow ? widget.coffeeShop!.id : null,
          image: _base64Image,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          latitude: _latitude,
          longitude: _longitude,
          operationalHours:
              '', // Jam operasional dikosongkan karena tidak dipakai
          userId: adminId,
          userFullName: adminName,
          ownerPhone: _ownerPhoneController.text.trim(),
        );

        if (isEditingNow) {
          await PostService.updatPost(postToSave);
        } else {
          await PostService.addPost(postToSave);
        }

        if (!mounted) return;

        await sendNotificationToTopic(
          "Laporan hewan hilang terkirim: ${_nameController.text}",
          adminName ?? 'Pengguna',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Laporan hewan hilang berhasil dikirim."),
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan data: $e")));
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else {
      // ---------------- LOGIKA SUBMIT PENGGUNA (ULASAN) ----------------
      if (_ownerPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan nomor WhatsApp/Telepon terlebih dahulu.'),
          ),
        );
        return;
      }
      if (_ownerPhoneController.text.trim().length > 13) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor WhatsApp/Telepon maksimal 13 angka.'),
          ),
        );
        return;
      }
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan nama atau jenis hewan hilang.'),
          ),
        );
        return;
      }
      if (_descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jelaskan lokasi atau kondisi terakhir hewan.'),
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        _updateLocationFromManualInput();

        if (_latitude == null || _longitude == null) {
          await _getLocation();
        }

        if (_latitude == null || _longitude == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Harap ambil atau masukkan lokasi hewan hilang terlebih dahulu.',
              ),
            ),
          );
          return;
        }

        if (!_isValidCoordinate(_latitude) || !_isValidCoordinate(_longitude)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Koordinat tidak valid. Pastikan latitude dan longitude berupa angka.',
              ),
            ),
          );
          return;
        }

        final reportPost = Post(
          id: null,
          image: _base64Image,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          latitude: _latitude,
          longitude: _longitude,
          operationalHours: DateTime.now().toLocal().toString(),
          userId: adminId,
          userFullName: adminName,
          ownerPhone: _ownerPhoneController.text.trim(),
        );

        await PostService.addPost(reportPost);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Laporan hewan hilang berhasil dikirim."),
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengirim laporan: $e")));
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // If a coffeeShop is provided and we're in admin mode, prefill fields for editing
    if (widget.isAdmin && widget.coffeeShop != null) {
      _isEditing = true;
      final p = widget.coffeeShop!;
      _base64Image = p.image;
      _nameController.text = p.name ?? '';
      _descriptionController.text = p.description ?? '';
      _category = p.category;
      _latitude = p.latitude;
      _longitude = p.longitude;
      _latitudeController.text = p.latitude ?? '';
      _longitudeController.text = p.longitude ?? '';
      _ownerPhoneController.text = p.ownerPhone ?? '';
    }
  }

  // 7. Fungsi AI: Generate deskripsi menarik otomatis berdasarkan foto hewan hilang
  Future<void> _generateDescriptionWithAI() async {
    if (_base64Image == null) return;
    setState(() => _isGenerating = true);
    try {
      const apikey = 'AQ.Ab8RN6KpErACNM-5iVwJVbh-yJ7iLmvKM5EFz0DuaFeVyIo1Xg';
      const url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apikey';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {"mimeType": "image/jpeg", "data": _base64Image},
              },
              {
                "text":
                    "Berdasarkan foto hewan ini, identifikasi jenis hewannya "
                    "dari daftar kategori berikut: Kucing, Anjing, Burung, Kelinci, Reptil, atau Lainnya. "
                    "Buat deskripsi ciri-ciri fisik singkat, jelas, dan spesifik (seperti warna bulu, jenis ras jika terlihat, corak, atau tanda unik lainnya) "
                    "yang dapat membantu mengenali hewan hilang ini.\n\n"
                    "Format output harus persis seperti ini (tanpa simbol markdown seperti asteriks *):\n"
                    "Kategori: [Pilih salah satu dari: Kucing / Anjing / Burung / Kelinci / Reptil / Lainnya]\n"
                    "Deskripsi: [Deskripsi ciri-ciri fisik singkat]",
              },
            ],
          },
        ],
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        if (text != null && text.isNotEmpty) {
          final lines = text.trim().split('\n');
          String? aicategory;
          String? aidescription;

          for (var line in lines) {
            final lower = line.toLowerCase();
            if (lower.startsWith('kategori:')) {
              aicategory = line.substring(9).trim();
            } else if (lower.startsWith('deskripsi:')) {
              aidescription = line.substring(10).trim();
            }
          }

          aidescription ??= text.trim();
          setState(() {
            if (categories.contains(aicategory)) {
              _category = aicategory;
            }
            _descriptionController.text = aidescription!;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to generate AI description: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // Fungsi kirim notifikasi topik (FCM)
  Future<void> sendNotificationToTopic(String body, String senderName) async {
    final url = Uri.parse(
      'https://coffeeshop-finder-kohl.vercel.app/send-to-topic',
    );
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "topic": "coffee-shop-palembang",
          "title": "☕ Laporan Hewan Hilang Baru!",
          "body": body,
          "senderName": senderName,
          "senderPhotoUrl":
              "https://static.vecteezy.com/system/resources/thumbnails/041/642/167/small_2x/ai-generated-portrait-of-handsome-smiling-young-man-with-folded-arms-isolated-free-png.png",
        }),
      );
    } catch (e) {
      debugPrint("Notification error: $e");
    }
  }

  bool _isValidCoordinate(String? value) {
    return value != null && value.isNotEmpty && double.tryParse(value) != null;
  }

  void _updateLocationFromManualInput() {
    final lat = _latitudeController.text.trim();
    final lng = _longitudeController.text.trim();
    if (lat.isNotEmpty && lng.isNotEmpty) {
      _latitude = lat;
      _longitude = lng;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _ownerPhoneController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdmin
              ? (_isEditing
                    ? 'Edit Laporan Hewan'
                    : 'Tambah Laporan Hewan Hilang')
              : 'Tambah Laporan Hewan Hilang',
        ),
        backgroundColor: Color(0xFF1A5F7A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isGenerating ? null : pickImageAndConvert,
                  icon: const Icon(Icons.image),
                  label: Text(
                    widget.isAdmin
                        ? (_isGenerating
                              ? 'Menganalisis Foto...'
                              : 'Pilih Foto')
                        : 'Pilih Foto Hewan',
                  ),
                ),
                const SizedBox(width: 16),
                // Tombol generator AI hanya muncul jika user adalah Admin & gambar sudah ada
                if (widget.isAdmin && !_isGenerating && _base64Image != null)
                  OutlinedButton.icon(
                    onPressed: _isGenerating
                        ? null
                        : _generateDescriptionWithAI,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Ulangi AI Generate'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ================= TAMPILAN KHUSUS ADMIN =================
            if (widget.isAdmin) ...[
              // Input Nama atau jenis hewan hilang
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama / Jenis Hewan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
              ),
              const SizedBox(height: 16),

              // Pilih jenis hewan / kategori laporan
              OutlinedButton(
                onPressed: _isSubmitting ? null : _showCategorySelect,
                child: const Text('Pilih Jenis Hewan'),
              ),
              const SizedBox(height: 8),
              Text(
                _category ?? 'Belum memilih karakteristik',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5F7A),
                ),
              ),
              const SizedBox(height: 16),

              // Input Deskripsi
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Laporan',
                  hintText:
                      'Tuliskan ciri-ciri, warna, atau lokasi terakhir hewan hilang',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Mengambil Lokasi Maps
              OutlinedButton.icon(
                onPressed: (_isSubmitting || _isGettingLocation)
                    ? null
                    : _getLocation,
                icon: const Icon(Icons.pin_drop),
                label: Text(
                  _isGettingLocation
                      ? 'Mengunci Koordinat...'
                      : 'Ambil Lokasi Maps',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Atau masukkan koordinat secara manual jika lokasi peta tidak tersedia',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _latitude = value.trim();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _longitude = value.trim();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLocationInfo(),
            ],

            // ================= TAMPILAN KHUSUS PENGGUNA =================
            if (!widget.isAdmin) ...[
              Text(
                "Laporkan Hewan Hilang",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5F7A),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _ownerPhoneController,
                keyboardType: TextInputType.phone,
                maxLength: 13,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp/Telepon',
                  hintText: 'Contoh: 081234567890',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  counterText: '', // Sembunyikan counter text agar lebih rapi
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama / Jenis Hewan',
                  hintText:
                      'Contoh: Kucing abu-abu, anjing golden retriever, burung parkit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
              ),
              const SizedBox(height: 16),

              // Input detail laporan hewan hilang
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Detail Laporan',
                  hintText:
                      'Cerita singkat tentang hewan hilang atau lokasi terakhir yang diketahui...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Input Lokasi Maps Pengguna
              const Text(
                'Lokasi Terakhir Hewan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5F7A),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: (_isSubmitting || _isGettingLocation)
                    ? null
                    : _getLocation,
                icon: const Icon(Icons.pin_drop),
                label: Text(
                  _isGettingLocation
                      ? 'Mengambil Lokasi...'
                      : 'Ambil Lokasi Saat Ini',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Atau masukkan koordinat secara manual jika GPS kurang akurat',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _latitude = value.trim();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _longitude = value.trim();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLocationInfo(),
            ],

            const SizedBox(height: 24),

            // Tombol Submit Final
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6EA0B4),
              ),
              child: Text(
                _isSubmitting
                    ? 'Menyimpan...'
                    : (widget.isAdmin
                          ? (_isEditing ? 'Simpan Perubahan' : 'Kirim Laporan')
                          : 'Kirim Laporan'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
