import 'dart:convert';

import 'package:anabulcare/firebase_options.dart';
import 'package:anabulcare/screens/admin_home_screen.dart';
import 'package:anabulcare/screens/main_navigation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:anabulcare/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:anabulcare/providers/app_provider.dart';
import 'package:anabulcare/theme/app_theme.dart';
import 'package:anabulcare/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Izin notifikasi diberikan');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('Izin notifikasi sementara diberikan');
  } else {
    print('Izin notifikasi ditolak');
  }
}

Future<void> showBasicNotification(String? title, String? body) async {
  final android = AndroidNotificationDetails(
    'default_channel',
    'Notifikasi Default',
    channelDescription: 'Notifikasi masuk dari FCM',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  final platform = NotificationDetails(android: android);
  await flutterLocalNotificationsPlugin.show(0, title, body, platform);
}

Future<void> showNotificationFromData(Map<String, dynamic> data) async {
  final title = data['title'] ?? 'Pesan Baru';
  final body = data['body'] ?? '';
  final sender = data['senderName'] ?? 'Pengirim tidak diketahui';
  final time = data['sentAt'] ?? '';
  final photoUrl = data['senderPhotoUrl'] ?? '';

  ByteArrayAndroidBitmap? largeIconBitmap;
  if (photoUrl.isNotEmpty) {
    final base64 = await _networkImageToBase64(photoUrl);
    if (base64 != null) {
      largeIconBitmap = ByteArrayAndroidBitmap.fromBase64String(base64);
    }
  }

  // ignore: unused_local_variable
  final styleInfo = largeIconBitmap != null
      ? BigPictureStyleInformation(
          largeIconBitmap,
          contentTitle: title,
          summaryText: '$body\n\nDari: $sender - $time',
          largeIcon: largeIconBitmap,
          hideExpandedLargeIcon: true,
        )
      : BigTextStyleInformation(
          '$body\n\nDari: $sender\nWaktu: $time',
          contentTitle: title,
        );

  final simpleStyleInfo = BigTextStyleInformation(
    '$body\n\nDari: $sender\nWaktu: $time',
    contentTitle: title,
  );

  final androidDetails = AndroidNotificationDetails(
    'detailed_channel',
    'Notifikasi Detail',
    channelDescription: 'Notifikasi dengan detail tambahan',
    styleInformation: simpleStyleInfo,
    largeIcon: largeIconBitmap,
    importance: Importance.max,
    priority: Priority.max,
  );

  final platform = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(1, title, body, platform);
}

Future<String?> _networkImageToBase64(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
  } catch (_) {}
  return null;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data.isNotEmpty) {
    await showNotificationFromData(message.data);
  } else {
    await showBasicNotification(
      message.notification!.title,
      message.notification!.body,
    );
  }
}

const String _adminLoggedInKey = 'admin_logged_in';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await requestNotificationPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings settings = InitializationSettings(
    android: androidInit,
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(settings);

  final prefs = await SharedPreferences.getInstance();
  final isAdminLoggedIn = prefs.getBool(_adminLoggedInKey) ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MyApp(initialAdminLoggedIn: isAdminLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool initialAdminLoggedIn;

  const MyApp({super.key, required this.initialAdminLoggedIn});

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan dari provider
    final appProvider = Provider.of<AppProvider>(context);

    return MaterialApp(
      title: "CoffeeShop Finder",
      debugShowCheckedModeBanner: false,

      // Menggunakan Tema dari file app_theme.dart
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appProvider.themeMode,

      // Lokalisasi
      locale: appProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.brown),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // Jika user berhasil login, jalankan AuthWrapper untuk cek Role
            return AuthWrapper(user: snapshot.data!);
          } else if (initialAdminLoggedIn) {
            // Pemulihan admin login lokal di web saat refresh
            return const AdminHomeScreen();
          } else {
            return const SignInScreen();
          }
        },
      ),
    );
  }
}

// --- WIDGET BARU UNTUK CEK ROLE ANTARA ADMIN DAN PENGGUNA ---
class AuthWrapper extends StatelessWidget {
  final User user;
  const AuthWrapper({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // Mengambil data pengguna berdasarkan UID dari koleksi 'users' di Firestore
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.brown)),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          // Ambil data dokumen user
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final role =
              userData?['role'] ??
              'pengguna'; // Nilai fallback jika role kosong

          if (role == 'admin') {
            return const AdminHomeScreen();
          } else {
            return const MainNavigationScreen();
          }
        }

        // Jika data user tidak ditemukan di database Cloud Firestore, default lempar ke MainNavigationScreen
        return const MainNavigationScreen();
      },
    );
  }
}
