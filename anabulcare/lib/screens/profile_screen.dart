import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anabulcare/providers/app_provider.dart';
import 'package:anabulcare/screens/edit_profile_screen.dart';
import 'package:anabulcare/screens/sign_in_screen.dart';
import 'package:anabulcare/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _isDarkMode = false;
  String _selectedLanguage = 'Indonesia';
  String _displayName = 'Nama Pengguna';
  String _phone = '';
  String _history = '';
  String _city = '';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    var displayName = user.displayName?.trim() ?? 'Nama Pengguna';
    var phone = '';
    var history = '';
    var city = '';
    DateTime? birthDate;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        final data = snapshot.data();
        phone = data?['phone'] ?? data?['nomor'] ?? '';
        history = data?['history'] ?? data?['riwayat'] ?? '';
        city = data?['city'] ?? data?['kota'] ?? '';
        final birthValue = data?['birthdate'] ?? data?['tanggal_lahir'];
        if (birthValue != null) {
          birthDate = DateTime.tryParse(birthValue.toString()) ?? birthDate;
        }
      }
    } catch (_) {
      // ignore loading errors
    }

    if (!mounted) return;
    setState(() {
      _displayName = displayName;
      _phone = phone;
      _history = history;
      _city = city;
      _birthDate = birthDate;
      _isDarkMode = appProvider.themeMode == ThemeMode.dark;
      _selectedLanguage = appProvider.locale.languageCode == 'en'
          ? 'English'
          : 'Indonesia';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final initials = _displayName.isNotEmpty
        ? _displayName
              .split(' ')
              .where((part) => part.isNotEmpty)
              .map((part) => part[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    final localization = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localization.profileTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFB1D3E0),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.grey[800]
                              : Color(0xFFEAF4F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: _isDarkMode
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localization.editProfile,
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _city,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                  // gender removed as per request
                  if (_birthDate != null) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                  if (_phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _phone,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    localization.settingsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: Text(localization.darkMode),
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() => _isDarkMode = value);
                      appProvider.toggleTheme(value);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(localization.language),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Indonesia',
                          child: Text('Indonesia'),
                        ),
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (newValue) {
                        if (newValue == null) return;
                        setState(() => _selectedLanguage = newValue);
                        appProvider.setLocale(
                          newValue == 'English' ? 'en' : 'id',
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      localization.history,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_history),
                    const SizedBox(height: 16),
                  ],
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      localization.logout,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

