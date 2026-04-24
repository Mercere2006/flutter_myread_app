import 'package:flutter/material.dart';
import 'package:flutter_myread_app/views/home_ui.dart';

class SplashScreenUi extends StatefulWidget {
  SplashScreenUi({super.key});

  @override
  State<SplashScreenUi> createState() => _SplashScreenUiState();
}

class _SplashScreenUiState extends State<SplashScreenUi> {
  @override
  void initState() {
    Future.delayed(
      Duration(seconds: 3),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeUi(),
          ),
        );
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. พื้นหลัง texture
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. ส่วนตรงกลาง (ไอคอนหนังสือ และชื่อแอป)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/book.png',
                  width: 150.0,
                  height: 150.0,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 100.0),
                Text(
                  'MY READ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 35.0,
                    color: Colors.black,
                  ),
                ),
                // ปรับระยะห่างระหว่างชื่อแอปกับเส้นโหลดตามความเหมาะสม
                SizedBox(height: 150.0), 
              ],
            ),
          ),

          // 3. เส้นโหลด (วางตำแหน่งตายตัวเหนือชั้นวางหนังสือ)
          Positioned(
            bottom: 200.0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 80.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: LinearProgressIndicator(
                  minHeight: 5.0,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ),
          ),

          // 4. ชั้นวางหนังสือ bookshelf (วางชิดขอบล่างสุด)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/bookshelf_.png',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}