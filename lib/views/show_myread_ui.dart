import 'package:flutter/material.dart';
import 'package:flutter_myread_app/services/supabase_service.dart';
import 'package:flutter_myread_app/models/task_book.dart';
import 'package:flutter_myread_app/views/add_myread_ui.dart';
import 'package:flutter_myread_app/views/edit_myread_ui.dart';
import 'package:table_calendar/table_calendar.dart';

class ShowMyreadUi extends StatefulWidget {
  ShowMyreadUi({super.key});

  @override
  State<ShowMyreadUi> createState() => _ShowMyreadUiState();
}

class _ShowMyreadUiState extends State<ShowMyreadUi> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final SupabaseService _service = SupabaseService();
  List<TaskBook> _allBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // ดึงข้อมูลหนังสือจาก Supabase
  Future<void> _fetchData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      final books = await _service.getBooks();
      if (!mounted) return;
      setState(() {
        _allBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading books: $e')),
      );
    }
  }

  // กรองหนังสือตามวันที่เลือกในปฏิทิน
  List<TaskBook> _getBooksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);

    return _allBooks.where((book) {
      if (book.startDate == null) return false;

      DateTime? sDate = DateTime.tryParse(book.startDate!);
      DateTime? fDate = book.finishDate != null ? DateTime.tryParse(book.finishDate!) : null;

      if (sDate == null) return false;

      final start = DateTime(sDate.year, sDate.month, sDate.day);

      if (fDate != null) {
        final end = DateTime(fDate.year, fDate.month, fDate.day);
        return normalizedDay.isAtSameMomentAs(start) ||
            normalizedDay.isAtSameMomentAs(end) ||
            (normalizedDay.isAfter(start) && normalizedDay.isBefore(end));
      } else {
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        if (normalizedDay.isAtSameMomentAs(start)) return true;
        return normalizedDay.isAfter(start) &&
            (normalizedDay.isBefore(today) || normalizedDay.isAtSameMomentAs(today));
      }
    }).toList();
  }

  // แสดงหน้ารายการหนังสือที่อ่านในวันนั้น
  void _showBooksBottomSheet(DateTime day, List<TaskBook> books) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Books on ${day.day}/${day.month}/${day.year}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 15),
              books.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('ไม่มีประวัติการอ่านในวันนี้')),
                    )
                  : Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            leading: Container(
                              width: 45,
                              height: 65,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                                image: (book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(book.coverImageUrl!),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: (book.coverImageUrl == null || book.coverImageUrl!.isEmpty)
                                  ? const Icon(Icons.book, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(book.title ?? 'ไม่มีชื่อเรื่อง', 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(book.author ?? 'ไม่ระบุผู้แต่ง'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditMyreadUi(book: book)),
                              ).then((value) => value == true ? _fetchData() : null);
                            },
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              color: Colors.black,
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header ---
                    Padding(
                      padding: const EdgeInsets.only(left: 25, right: 25, top: 50, bottom: 10),
                      child: Row(
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Library', 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)),
                              Text('ติดตามการเดินทางของหนังสือคุณ', 
                                style: TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => AddMyreadUi())
                            ).then((_) => _fetchData()),
                            icon: const Icon(Icons.add_circle, size: 40, color: Colors.black),
                          )
                        ],
                      ),
                    ),

                    // --- Horizontal List (Bookshelf) ---
                    SizedBox(
                      height: 230,
                      child: _allBooks.isEmpty 
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            scrollDirection: Axis.horizontal,
                            itemCount: _allBooks.length,
                            itemBuilder: (context, index) {
                              final book = _allBooks[index];
                              return _buildBookCard(book);
                            },
                          ),
                    ),

                    // --- Calendar Section ---
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reading Calendar', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05), 
                                  blurRadius: 20, 
                                  offset: const Offset(0, 10)
                                ),
                              ],
                            ),
                            child: TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              rowHeight: 85,
                              eventLoader: _getBooksForDay,
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                                final booksOnDay = _getBooksForDay(selectedDay);
                                _showBooksBottomSheet(selectedDay, booksOnDay);
                              },
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              calendarStyle: const CalendarStyle(
                                todayDecoration: BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                                selectedDecoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                              ),
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, day, focusedDay) => _buildCellWithBook(day, false, false),
                                todayBuilder: (context, day, focusedDay) => _buildCellWithBook(day, true, false),
                                selectedBuilder: (context, day, focusedDay) => _buildCellWithBook(day, false, true),
                                markerBuilder: (context, day, events) => const SizedBox(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBookCard(TaskBook book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => EditMyreadUi(book: book))
      ).then((value) => value == true ? _fetchData() : null),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                  image: (book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(book.coverImageUrl!), fit: BoxFit.cover)
                      : null,
                  color: const Color(0xFFE0E0E0),
                ),
                child: (book.coverImageUrl == null || book.coverImageUrl!.isEmpty)
                    ? const Center(child: Icon(Icons.book_rounded, color: Colors.white, size: 40))
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(book.title ?? 'Untitled', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis),
            Text(book.author ?? 'Unknown', 
              style: const TextStyle(color: Colors.grey, fontSize: 12), 
              maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 60, color: Colors.grey[300]),
          const Text('ยังไม่มีหนังสือในคลัง', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCellWithBook(DateTime day, bool isToday, bool isSelected) {
    final books = _getBooksForDay(day);
    final maxVisible = 2; // แสดงรูปซ้อนกันสูงสุด 2 เล่ม

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.black, width: 1) : null,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text('${day.day}', 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal, 
                  color: day.weekday == 7 ? Colors.red : Colors.black
                )),
            ),
          ),
          
          if (books.isNotEmpty)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 55,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // สร้างการซ้อนกันของปกหนังสือ
                      for (int i = (books.length > maxVisible ? maxVisible - 1 : books.length - 1); i >= 0; i--)
                        Positioned(
                          left: (i * 8.0) - ((books.length > maxVisible ? maxVisible : books.length) * 4),
                          top: (maxVisible - 1 - i) * 2.0,
                          child: Transform.rotate(
                            angle: (i % 2 == 0 ? 0.05 : -0.05) * i,
                            child: Container(
                              width: 35,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white, width: 1),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: const Offset(1, 1))
                                ],
                                image: (books[i].coverImageUrl != null && books[i].coverImageUrl!.isNotEmpty)
                                    ? DecorationImage(image: NetworkImage(books[i].coverImageUrl!), fit: BoxFit.cover)
                                    : null,
                                color: const Color(0xFFD9D9D9),
                              ),
                              child: (books[i].coverImageUrl == null || books[i].coverImageUrl!.isEmpty)
                                  ? const Icon(Icons.book, size: 15, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
          // Badge บอกจำนวนเล่ม
          if (books.length > 1)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                child: Text('${books.length}', 
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}