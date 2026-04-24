import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_myread_app/models/task_book.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }


  // ดึงข้อมูลหนังสือพร้อมข้อมูล Journal (Join 2 ตาราง)
  Future<List<TaskBook>> getBooks() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    try {
      final data = await supabase
          .from('books_tb')
          .select('*, journal_tb(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((json) {
        // ตรวจสอบข้อมูลจาก journal_tb
        if (json['journal_tb'] != null) {
          var journalEntry;

          // ถ้าข้อมูลมาเป็น List (มีหลายอัน) ให้เอาอันแรก
          if (json['journal_tb'] is List &&
              (json['journal_tb'] as List).isNotEmpty) {
            journalEntry = (json['journal_tb'] as List).first;
          }
          // ถ้าข้อมูลมาเป็น Map (ก้อนเดียว) ให้ใช้ก้อนนั้นเลย
          else if (json['journal_tb'] is Map) {
            journalEntry = json['journal_tb'];
          }

          // ในฟังก์ชัน getBooks() ตรงส่วนที่จัดการ journalEntry
          if (journalEntry != null) {
            json['start_date'] = journalEntry['start_date'];
            json['finish_date'] = journalEntry['finish_date'];
            json['rating'] = journalEntry['rating'];
            // มั่นใจว่าตรงนี้ดึงค่า descrip_feel มาตรงๆ ทั้งก้อน
            json['descrip_feel'] = journalEntry['descrip_feel']?.toString();
          }
        }
        return TaskBook.fromJson(json);
      }).toList();
    } catch (e) {
      print('Fetch books error: $e');
      return [];
    }
  }

  // บันทึกข้อมูลลงตาราง journal_tb
  Future<void> upsertJournal({
    required String bookId,
    required String? startDate,
    required String? finishDate,
    required int rating,
    required String descripFeel,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    // แก้ไขตรงนี้: เพิ่ม onConflict: 'book_id'
    await supabase.from('journal_tb').upsert({
      'book_id': bookId,
      'user_id': userId,
      'start_date': startDate,
      'finish_date': finishDate,
      'rating': rating,
      'descrip_feel': descripFeel,
    }, onConflict: 'book_id'); // <--- ระบุ Column ที่ตั้งเป็น Unique ไว้
  }

  // ฟังก์ชันพื้นฐานอื่นๆ
  Future<void> insertBook(TaskBook book) async =>
      await supabase.from('books_tb').insert(book.toJson());

  Future<void> updateBook(TaskBook book) async =>
      await supabase.from('books_tb').update(book.toJson()).eq('id', book.id!);

  Future<void> deleteBook(String id) async =>
      await supabase.from('books_tb').delete().eq('id', id);

  Future<String> uploadFile(File file) async {
    final userId = getCurrentUserId()!;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.png';

    // ตรวจสอบชื่อตรงนี้ให้แม่นยำว่าเป็น 'profile_bk'
    await supabase.storage.from('profile_bk').upload(path, file);

    return supabase.storage.from('profile_bk').getPublicUrl(path);
  }

  // ส่วนของการสลับสถานะเรื่องโปรด (Favorite)
  Future<void> toggleFavorite(String bookId, bool currentStatus) async {
    try {
      await supabase
          .from('books_tb')
          .update({'is_favorite': !currentStatus}) // สลับสถานะเป็นค่าตรงข้าม
          .eq('id', bookId);
    } catch (e) {
      print('Toggle favorite error: $e');
      rethrow;
    }
  }
}
