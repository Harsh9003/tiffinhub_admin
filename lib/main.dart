import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin/admin_auth_wrapper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TiffinHubAdminApp());
}

class TiffinHubAdminApp extends StatelessWidget {
  const TiffinHubAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TiffinHub Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF6A00),
        scaffoldBackgroundColor: const Color(0xFFFFF8F3),
      ),
      home: const AdminAuthWrapper(),
    );
  }
}
