import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_myread_app/models/task_book.dart';
import 'package:flutter_myread_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class AddMyreadUi extends StatefulWidget {
  AddMyreadUi({super.key});

  @override
  State<AddMyreadUi> createState() => _AddMyreadUiState();
}

class _AddMyreadUiState extends State<AddMyreadUi> {
  TextEditingController titleCtrl = TextEditingController();
  TextEditingController authorCtrl = TextEditingController();
  TextEditingController publisherCtrl = TextEditingController();
  TextEditingController descriptionCtrl = TextEditingController();
  String? coverImageUrl = '';
  File? file;

  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        file = File(picked.path);
      });
    }
  }

  void showPickOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.black87),
              title: Text('เลือกจากแกลลอรี่'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.black87),
              title: Text('ถ่ายรูปด้วยกล้อง'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> save() async {
    if (titleCtrl.text.trim().isEmpty || authorCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกชื่อหนังสือและชื่อผู้แต่ง'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final service = SupabaseService();
    final userId = service.getCurrentUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนบันทึก'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      if (file != null) {
        coverImageUrl = await service.uploadFile(file!);
      } else {
        coverImageUrl = '';
      }

      final taskBook = TaskBook(
        userId: userId,
        title: titleCtrl.text.trim(),
        author: authorCtrl.text.trim(),
        publisher: publisherCtrl.text.trim(),
        description: descriptionCtrl.text.trim(),
        coverImageUrl: coverImageUrl,
      );

      await service.insertBook(taskBook);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกหนังสือเข้าคลังสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add New Book', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: () => showPickOptions(),
                child: Container(
                  width: 140,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      )
                    ],
                    color: Color(0xFFF3F3F3),
                    image: file != null
                        ? DecorationImage(image: FileImage(file!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: file == null
                      ? Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 30),
            _buildTextField('Book Title', titleCtrl, Icons.book_outlined),
            _buildTextField('Author', authorCtrl, Icons.person_outline),
            _buildTextField('Publisher', publisherCtrl, Icons.business_outlined),
            _buildTextField('Description', descriptionCtrl, Icons.description_outlined, maxLines: 3),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => save(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff7AAACE),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black54),
          filled: true,
          fillColor: Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.black12),
          ),
        ),
      ),
    );
  }
}