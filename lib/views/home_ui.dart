import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_myread_app/services/supabase_service.dart';
import 'package:flutter_myread_app/views/journal_ui.dart';
import 'package:flutter_myread_app/views/login_ui.dart';
import 'package:flutter_myread_app/views/profile_ui.dart';
import 'package:flutter_myread_app/views/show_myread_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeUi extends StatefulWidget {
  HomeUi({super.key});

  @override
  State<HomeUi> createState() => _HomeUiState();
}

class _HomeUiState extends State<HomeUi> {
  int barItemIndex = 0;
  bool isProfileVisible = false;
  final SupabaseService _service = SupabaseService();
  String? _profileImageUrl;

  List showUI = [
    ShowMyreadUi(),
    JournalUi(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileImageDirectly();
  }

  // เปลี่ยนมาดึงข้อมูลจากตาราง profile_tb โดยตรงเพื่อให้ชัวร์
  Future<void> _fetchProfileImageDirectly() async {
    final user = _service.supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _service.supabase
          .from('profile_tb')
          .select('profile_image_url')
          .eq('id', user.id)
          .single();

      if (data != null && data['profile_image_url'] != null) {
        setState(() {
          // ใส่ timestamp กัน cache
          _profileImageUrl = "${data['profile_image_url']}?t=${DateTime.now().millisecondsSinceEpoch}";
        });
      }
    } catch (e) {
      print('Error fetching image from table: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff7AAACE),
        elevation: 0,
        leading: isProfileVisible
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  setState(() {
                    isProfileVisible = false;
                  });
                  _fetchProfileImageDirectly(); // รีเฟรชรูปเมื่อกลับจากหน้า Profile
                },
              )
            : null,
        title: Padding(
          padding: EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isProfileVisible
                  ? 'PROFILE'
                  : (barItemIndex == 0 ? 'MY READ' : 'JOURNAL'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        actions: [
          if (!isProfileVisible)
            GestureDetector(
              onTap: () {
                final user = _service.supabase.auth.currentUser;
                if (user == null) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginUi())).then((_) => _fetchProfileImageDirectly());
                } else {
                  setState(() {
                    isProfileVisible = true;
                  });
                }
              },
              child: Padding(
                padding: EdgeInsets.only(right: 15.0),
                child: Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                        ? Icon(Icons.account_circle, color: Colors.white, size: 30.0)
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isProfileVisible ? ProfileUi() : showUI[barItemIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            barItemIndex = index;
            isProfileVisible = false;
          });
          _fetchProfileImageDirectly();
        },
        selectedItemColor: Color(0xff7AAACE),
        currentIndex: isProfileVisible ? 0 : barItemIndex,
        items: [
          BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.bookOpen), label: 'Book'),
          BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.bookJournalWhills),
              label: 'Journal'),
        ],
      ),
    );
  }
}