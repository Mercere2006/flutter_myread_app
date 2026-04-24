import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_myread_app/models/task_book.dart';
import 'package:flutter_myread_app/services/supabase_service.dart';

class EditMyreadUi extends StatefulWidget {
  final TaskBook book;
  EditMyreadUi({required this.book});

  @override
  _EditMyreadUiState createState() => _EditMyreadUiState();
}

class _EditMyreadUiState extends State<EditMyreadUi> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _publisherController;
  late TextEditingController _descController;
  File? _newImage;
  bool _isSaving = false;
  final _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _publisherController = TextEditingController(text: widget.book.publisher);
    _descController = TextEditingController(text: widget.book.description);
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
    }
  }

  Future<void> _updateBook() async {
    setState(() => _isSaving = true);
    try {
      if (_newImage != null) {
        widget.book.coverImageUrl = await _service.uploadFile(_newImage!);
      }
      widget.book.title = _titleController.text.trim();
      widget.book.author = _authorController.text.trim();
      widget.book.publisher = _publisherController.text.trim();
      widget.book.description = _descController.text.trim();

      await _service.updateBook(widget.book);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update ล้มเหลว: $e')),
      );
    }
  }

  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Book?'),
        content: Text('ต้องการลบหนังสือเล่มนี้ออกจากคลังใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteBook(widget.book.id!);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Book', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: _deleteBook)
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _showPicker(context), // เปลี่ยนมาเรียกเมนูเลือกรูป
                child: Container(
                  width: 140,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    color: Color(0xFFF3F3F3),
                    image: _newImage != null 
                        ? DecorationImage(image: FileImage(_newImage!), fit: BoxFit.cover)
                        : (widget.book.coverImageUrl != null && widget.book.coverImageUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(widget.book.coverImageUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: (_newImage == null && (widget.book.coverImageUrl == null || widget.book.coverImageUrl!.isEmpty))
                      ? Icon(Icons.camera_alt_outlined, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 30),
            _buildTextField('Book Title', _titleController, Icons.book_outlined),
            _buildTextField('Author', _authorController, Icons.person_outline),
            _buildTextField('Publisher', _publisherController, Icons.business_outlined),
            _buildTextField('Description', _descController, Icons.description_outlined, maxLines: 3),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: Text('Cancel', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateBook,
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xff7AAACE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: _isSaving 
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black54),
          filled: true,
          fillColor: Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}