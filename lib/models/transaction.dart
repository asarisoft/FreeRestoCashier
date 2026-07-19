import 'transaction_item.dart';

class Transaction {
  final String? id;
  final int number;
  final List<TransactionItem> items;
  final int subtotal;
  final int discount;
  final int total;
  final int paid;
  final int change;
  final String paymentMethod;
  final int profit;
  final DateTime? printedAt;
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.number,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.paid,
    this.change = 0,
    this.paymentMethod = 'cash',
    required this.profit,
    this.printedAt,
    required this.createdAt,
  });

  bool get hasDiscount => discount > 0 || items.any((i) => i.discount > 0);

  bool get isPrinted => printedAt != null;

  Map<String, dynamic> toJson() => {
        'number': number,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'paid': paid,
        'change': change,
        'paymentMethod': paymentMethod,
        'profit': profit,
        'printedAt': printedAt,
        'createdAt': createdAt,
      };

  factory Transaction.fromJson(Map<String, dynamic> json, String id) =>
      Transaction(
        id: id,
        number: json['number'] as int,
        items: (json['items'] as List)
            .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: json['subtotal'] as int,
        discount: json['discount'] as int? ?? 0,
        total: json['total'] as int,
        paid: json['paid'] as int,
        change: json['change'] as int? ?? 0,
        paymentMethod: json['paymentMethod'] as String? ?? 'cash',
        profit: json['profit'] as int,
        printedAt: json['printedAt'] != null
            ? (json['printedAt'] as dynamic).toDate()
            : null,
        createdAt: (json['createdAt'] as dynamic).toDate(),
      );
}
