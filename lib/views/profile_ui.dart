import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_myread_app/services/supabase_service.dart';
import 'package:flutter_myread_app/views/home_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // เพิ่ม import ตัวนี้ด้วย

class ProfileUi extends StatefulWidget {
  ProfileUi({super.key});

  @override
  State<ProfileUi> createState() => _ProfileUiState();
}

class _ProfileUiState extends State<ProfileUi> {
  final SupabaseService _service = SupabaseService();

  Future<Map<String, dynamic>?> _getProfileData() async {
    final user = _service.supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _service.supabase
          .from('profile_tb')
          .select()
          .eq('id', user.id)
          .single();
      
      data['created_at_auth'] = user.createdAt;
      return data;
    } catch (e) {
      return {
        'user_name': 'User',
        'email': user.email,
        'created_at_auth': user.createdAt,
      };
    }
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  _updateProfileImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _updateProfileImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _updateProfileImage(ImageSource source) async {
    final user = _service.supabase.auth.currentUser;
    if (user == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 500,
      imageQuality: 80,
    );

    if (picked != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        final file = File(picked.path);
        final imageUrl = await _service.uploadFile(file);

        // 1. อัปเดตลงตาราง profile_tb (ตามเดิมของคุณ)
        await _service.supabase
            .from('profile_tb')
            .update({'profile_image_url': imageUrl})
            .eq('id', user.id);

        // 2. *** ส่วนที่ต้องเพิ่ม *** อัปเดตลง Auth Metadata เพื่อให้หน้า Home เห็นรูป
        await _service.supabase.auth.updateUser(
          UserAttributes(
            data: {'profile_image_url': imageUrl},
          ),
        );

        if (mounted) {
          Navigator.pop(context);
          setState(() {}); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ')),
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getProfileData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        final data = snapshot.data;
        String startDate = "-";
        if (data != null && data['created_at_auth'] != null) {
          DateTime dt = DateTime.parse(data['created_at_auth']);
          startDate = DateFormat('dd MMMM yyyy').format(dt);
        }

        final String? profileImageUrl = data?['profile_image_url'];

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                SizedBox(height: 30),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: (profileImageUrl == null || profileImageUrl.isEmpty)
                          ? Icon(Icons.person, size: 80, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showPicker(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xff7AAACE), 
                            shape: BoxShape.circle
                          ),
                          child: Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                _buildInfoRow('Name', data?['user_name'] ?? 'User'),
                _buildInfoRow('Email', data?['email'] ?? '-'),
                _buildInfoRow('Since', startDate),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () async {
                    await _service.supabase.auth.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomeUi()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                  ),
                  child: Text(
                    'Logout', 
                    style: TextStyle(color: Colors.white, fontSize: 18)
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          SizedBox(
            width: 80, 
            child: Text(
              label, 
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey
              )
            )
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
            )
          ),
        ],
      ),
    );
  }
}