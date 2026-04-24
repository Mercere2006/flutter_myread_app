import 'package:flutter/material.dart';
import 'package:flutter_myread_app/models/task_book.dart';
import 'package:flutter_myread_app/services/supabase_service.dart';
import 'package:flutter_myread_app/views/journal_detail_ui.dart';

class JournalUi extends StatefulWidget {
  JournalUi({super.key});

  @override
  State<JournalUi> createState() => _JournalUiState();
}

class _JournalUiState extends State<JournalUi> {
  final SupabaseService _service = SupabaseService();

  // ฟังก์ชันสำหรับยืนยันการลบหนังสือ
  Future<void> _confirmDelete(TaskBook book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบหนังสือเรื่อง "${book.title}" ใช่หรือไม่?\nการลบนี้จะทำให้ข้อมูลหายไปจากทั้งหน้า Journal และปฏิทิน'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteBook(book.id!);
        setState(() {}); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบข้อมูลเรียบร้อยแล้ว')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'บันทึกการอ่านหนังสือของคุณ',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<TaskBook>>(
                  future: _service.getBooks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(height: 100),
                          Center(child: Text('ยังไม่มีบันทึกหนังสือใน Journal')),
                        ],
                      );
                    }

                    final books = snapshot.data!;
                    
                    books.sort((a, b) {
                      if (a.isFavorite == b.isFavorite) {
                        return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
                      }
                      return a.isFavorite ? -1 : 1;
                    });

                    return ListView.builder(
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 15),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack( // ใช้ Stack เพื่อคุมตำแหน่งปุ่มลบ
                            children: [
                              InkWell(
                                onTap: () async {
                                  bool? refresh = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => JournalDetailUi(book: book),
                                    ),
                                  );
                                  if (refresh == true) setState(() {});
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // รูปปกหนังสือ
                                      Container(
                                        width: 80,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFD9D9D9),
                                          borderRadius: BorderRadius.circular(8),
                                          image: (book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(book.coverImageUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: (book.coverImageUrl == null || book.coverImageUrl!.isEmpty)
                                            ? Icon(Icons.book, color: Colors.grey)
                                            : null,
                                      ),
                                      SizedBox(width: 15),
                                      // รายละเอียดหนังสือ
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min, // ให้ Column กระชับตามเนื้อหา
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    book.title ?? 'ไม่มีชื่อเรื่อง',
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                // ปุ่มหัวใจอยู่มุมขวาบน
                                                GestureDetector(
                                                  onTap: () async {
                                                    final bool oldStatus = book.isFavorite;
                                                    setState(() {
                                                      book.isFavorite = !oldStatus;
                                                    });
                                                    try {
                                                      await _service.toggleFavorite(book.id!, oldStatus);
                                                    } catch (e) {
                                                      setState(() { book.isFavorite = oldStatus; });
                                                    }
                                                  },
                                                  child: Icon(
                                                    book.isFavorite ? Icons.favorite : Icons.favorite_border,
                                                    color: book.isFavorite ? Colors.red : Colors.grey,
                                                    size: 26,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // ลดระยะห่างโดยไม่ใช้ Spacer หรือ Alignment ที่ห่างเกินไป
                                            SizedBox(height: 4), 
                                            Text('ผู้แต่ง: ${book.author ?? '-'}', style: TextStyle(color: Colors.black87, fontSize: 14)),
                                            Text('สำนักพิมพ์: ${book.publisher ?? '-'}', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                            SizedBox(height: 8),
                                            // แสดง Rating
                                            Row(
                                              children: List.generate(5, (starIndex) {
                                                return Icon(
                                                  starIndex < (book.rating ?? 0) ? Icons.star : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 18,
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // ปุ่มถังขยะอยู่ที่มุมขวาล่างของการ์ด
                              Positioned(
                                bottom: 8,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _confirmDelete(book),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.blue.withOpacity(0.8),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}