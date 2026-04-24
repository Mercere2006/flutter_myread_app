class TaskJournal {
  String? id;
  String? bookId;
  String? userId;
  String? descripFeel;
  String? startDate;
  String? finishDate;
  int? rating;
  String? createdAt;

  TaskJournal({
    this.id,
    this.bookId,
    this.userId,
    this.descripFeel,
    this.startDate,
    this.finishDate,
    this.rating,
    this.createdAt,
  });

  factory TaskJournal.fromJson(Map<String, dynamic> json) => TaskJournal(
        id: json['id'],
        bookId: json['book_id'],
        userId: json['user_id'],
        descripFeel: json['descrip_feel'],
        startDate: json['start_date'],
        finishDate: json['finish_date'],
        rating: json['rating'],
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        'book_id': bookId,
        'user_id': userId,
        'descrip_feel': descripFeel,
        'start_date': startDate,
        'finish_date': finishDate,
        'rating': rating,
      };
}