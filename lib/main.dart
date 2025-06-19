import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linkily/screens/loading.dart';
import 'package:linkily/screens/login.dart';
import 'package:linkily/screens/map.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

late final FlutterSecureStorage secureStorage;

void main() async {
  await dotenv.load(fileName: ".env");
  secureStorage = const FlutterSecureStorage();
  WidgetsFlutterBinding.ensureInitialized();
  final accessToken = dotenv.env["VITE_MAPBOX_API_KEY"] ?? "No API Key";

  MapboxOptions.setAccessToken(accessToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linkily',
      home: const LoadingScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}
