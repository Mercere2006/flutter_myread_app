import 'package:flutter/material.dart';
import 'package:flutter_myread_app/models/task_book.dart';
import 'package:flutter_myread_app/services/supabase_service.dart';

class JournalDetailUi extends StatefulWidget {
  final TaskBook book;
  JournalDetailUi({super.key, required this.book});

  @override
  State<JournalDetailUi> createState() => _JournalDetailUiState();
}

class _JournalDetailUiState extends State<JournalDetailUi> {
  DateTime? startDate;
  DateTime? finishDate;
  int rating = 0;
  TextEditingController descripFeelCtrl = TextEditingController();
  final SupabaseService _service = SupabaseService();
  
  // ตัวแปรสำหรับเช็คว่ามีการแก้ไขข้อมูลหรือไม่
  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    if (widget.book.startDate != null) {
      startDate = DateTime.tryParse(widget.book.startDate!);
    }
    if (widget.book.finishDate != null) {
      finishDate = DateTime.tryParse(widget.book.finishDate!);
    }
    rating = widget.book.rating ?? 0;
    descripFeelCtrl.text = widget.book.descripFeel ?? "";
  }

  // ฟังก์ชันดักจับการกดออก
  Future<bool> _onWillPop() async {
    if (!isChanged) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ข้อมูลยังไม่ได้บันทึก'),
        content: Text('คุณต้องการบันทึกข้อมูลก่อนออกจากหน้านี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true), // ออกโดยไม่บันทึก
            child: Text('ไม่ต้องบันทึก', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, false); // ปิด Dialog
              await _saveJournal(); // บันทึกข้อมูล
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('บันทึกทันที', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() {
        isChanged = true; // มาร์คว่าข้อมูลเปลี่ยน
        if (isStart) {
          startDate = picked;
        } else {
          finishDate = picked;
        }
      });
    }
  }

  Future<void> _saveJournal() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      await _service.upsertJournal(
        bookId: widget.book.id!,
        startDate: startDate?.toIso8601String(),
        finishDate: finishDate?.toIso8601String(),
        rating: rating,
        descripFeel: descripFeelCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // ปิด loading
        setState(() => isChanged = false); // รีเซ็ตสถานะหลังบันทึก
        Navigator.pop(context, true); // กลับหน้าก่อนหน้า
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isChanged, // ถ้าข้อมูลเปลี่ยน จะยังไม่ออกทันที
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('JOURNAL'),
          backgroundColor: Color(0xff7AAACE),
          centerTitle: true,
          // แสดงสถานะการเปลี่ยนแปลงที่ AppBar เล็กน้อย
          actions: [
            if (isChanged)
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: Center(child: Text("Unsaved", style: TextStyle(fontSize: 12))),
              )
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(25),
          child: Column(
            children: [
              Text(
                widget.book.title ?? "ชื่อหนังสือ",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                width: 140,
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xffD9D9D9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                  ],
                  image: (widget.book.coverImageUrl != null &&
                          widget.book.coverImageUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(widget.book.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (widget.book.coverImageUrl == null ||
                        widget.book.coverImageUrl!.isEmpty)
                    ? Icon(Icons.book, size: 60, color: Colors.grey)
                    : null,
              ),
              SizedBox(height: 30),
              _buildDateRow("When you start read?", startDate, true),
              _buildDateRow("When you finish read?", finishDate, false),
              SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Record your feelings",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descripFeelCtrl,
                maxLines: 8,
                minLines: 8,
                onChanged: (value) => setState(() => isChanged = true),
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Typing here',
                  filled: true,
                  fillColor: Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text("What is the score of this book?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 45,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                        isChanged = true;
                      });
                    },
                  );
                }),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveJournal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isChanged ? Colors.green : Colors.grey,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("SAVE",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("CANCEL",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime? date, bool isStart) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          TextButton.icon(
            onPressed: () => _selectDate(context, isStart),
            icon: Icon(Icons.calendar_month, color: Color(0xff7AAACE)),
            label: Text(
              date == null
                  ? "เลือกวันที่"
                  : "${date.day}/${date.month}/${date.year}",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}