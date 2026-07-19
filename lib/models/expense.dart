class Expense {
  final String? id;
  final String? category;
  final String? note;
  final int amount;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    this.id,
    this.category,
    this.note,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'note': note,
        'amount': amount,
        'date': date,
        'createdAt': createdAt,
      };

  factory Expense.fromJson(Map<String, dynamic> json, String id) => Expense(
        id: id,
        category: json['category'] as String?,
        note: json['note'] as String?,
        amount: json['amount'] as int,
        date: (json['date'] as dynamic).toDate(),
        createdAt: (json['createdAt'] as dynamic).toDate(),
      );
}
