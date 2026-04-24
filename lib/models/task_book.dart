class TaskBook {
  String? id;
  String? userId;
  String? title;
  String? author;
  String? publisher;
  String? coverImageUrl;
  String? description;
  String? createdAt;
  bool isFavorite;

  // เพิ่มส่วนที่เชื่อมกับ journal_tb
  String? startDate;  // เก็บเป็น String เพื่อรอ parse เป็น DateTime ในหน้า UI
  String? finishDate;
  int? rating;
  String? descripFeel;

  TaskBook({
    this.id,
    this.userId,
    this.title,
    this.author,
    this.publisher,
    this.coverImageUrl,
    this.description,
    this.createdAt,
    this.startDate,
    this.finishDate,
    this.rating,
    this.descripFeel,
    this.isFavorite = false,
  });

  factory TaskBook.fromJson(Map<String, dynamic> json) => TaskBook(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        author: json['author'],
        publisher: json['publisher'],
        coverImageUrl: json['cover_image_url'],
        description: json['description'],
        createdAt: json['created_at'],
        startDate: json['start_date'],
        finishDate: json['finish_date'],
        rating: json['rating'],
        descripFeel: json['descrip_feel'],
        isFavorite: json['is_favorite'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'author': author,
        'publisher': publisher,
        'cover_image_url': coverImageUrl,
        'description': description,
        'is_favorite': isFavorite,
      };

      
}