import 'package:flutter/material.dart';
import 'package:flutter_myread_app/views/splash_screen_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // ----ตั้งค่าการใช้งาน supabase ที่จะทำงาน----
  WidgetsFlutterBinding.ensureInitialized();

// 2. โหลดไฟล์ .env ก่อน
  await dotenv.load(fileName: ".env");

  // 3. ดึงค่ามาใช้แทนการพิมพ์ String ลงไปตรงๆ
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    FlutterMyReadApp(),
  );
}

class FlutterMyReadApp extends StatefulWidget {
  const FlutterMyReadApp({super.key});

  @override
  State<FlutterMyReadApp> createState() => _FlutterMyReadAppState();
}

class _FlutterMyReadAppState extends State<FlutterMyReadApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreenUi(),
      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
    );
  }
}
