// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_myread_app/services/supabase_service.dart';
import 'package:flutter_myread_app/views/home_ui.dart';

class SignupUi extends StatefulWidget {
  SignupUi({super.key});

  @override
  State<SignupUi> createState() => _SignupUiState();
}

class _SignupUiState extends State<SignupUi> {
  TextEditingController userCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController phoneCtrl = TextEditingController();
  TextEditingController passCtrl = TextEditingController();
  bool _isObscure = true;

  Future<void> signup() async {
    if (userCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final service = SupabaseService();

      // 1. สมัครสมาชิกในระบบ Auth
      final response = await service.supabase.auth.signUp(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final user = response.user;

      if (user != null) {
        // 2. บันทึกข้อมูลลงในตาราง profile_tb
        // แก้ไขชื่อคอลัมน์เป็น 'user_name' ให้ตรงกับในรูปฐานข้อมูลของคุณ
        await service.supabase.from('profile_tb').upsert({
          'id': user.id,
          'user_name':
              userCtrl.text.trim(), // ตรวจสอบตรงนี้: ต้องมีขีดล่างตามรูป DB
          'email': emailCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'profile_image_url': '',
        });

        if (mounted) Navigator.pop(context); // ปิด Loading

        if (mounted) {
          // 3. ไปหน้า Home ทันที
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeUi()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      // ถ้าเจอ Error ว่า User already exists แต่ข้อมูลใน profile ยังไม่เข้า
      // เราจะพยายามดึง User ปัจจุบันมาเขียนทับใน profile_tb อีกรอบ
      if (e.toString().contains('user_already_exists')) {
        // ลอง Login หรือจัดการเคสนี้ตามที่คุณต้องการ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('อีเมลนี้ถูกใช้งานแล้ว กรุณาเข้าสู่ระบบ'),
              backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            children: [
              SizedBox(height: 50),
              // Logo หนังสือ
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset('assets/images/book.png',
                    width: 180, height: 180),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('สมัครสมาชิก',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 35)),
              ),
              SizedBox(height: 20),
              TextField(
                controller: userCtrl,
                decoration: InputDecoration(
                  hintText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Phone No',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('SIGNUP',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? "),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('LOGIN',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
