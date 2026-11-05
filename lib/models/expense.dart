/// Domain model for every financial record stored by PaisaPath.
///
/// A single [Expense] row represents either an expense or an income
/// transaction (marked by [type]). Records are persisted in the local SQLite
/// database via `DatabaseService` and are mapped with [toMap] / [fromMap].
library;

/// The kind of financial record.
enum TransactionType {
  expense,
  income;

  /// Stable key persisted in the database.
  String get key {
    switch (this) {
      case TransactionType.expense:
        return 'expense';
      case TransactionType.income:
        return 'income';
    }
  }

  static TransactionType fromKey(String key) {
    switch (key) {
      case 'income':
        return TransactionType.income;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }
}

class Expense {
  final int? id;
  final TransactionType type;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final String paymentMethod;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.paymentMethod,
    required this.createdAt,
  });

  /// Snapshot copy used by the edit flow.
  Expense copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? paymentMethod,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialises for SQLite storage. `date` and `createdAt` are stored as
  /// epoch milliseconds so they round-trip losslessly and sort correctly.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'type': type.key,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'payment_method': paymentMethod,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Deserialises a row defensively: unknown values fall back to safe
  /// defaults so a malformed database row never crashes the app.
  factory Expense.fromMap(Map<String, Object?> map) {
    final Object? amount = map['amount'];
    double parsedAmount = 0.0;
    if (amount is num) {
      parsedAmount = amount.toDouble();
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount) ?? 0.0;
    }

    final Object? dateMs = map['date'];
    final Object? createdAtMs = map['created_at'];

    return Expense(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      type: TransactionType.fromKey('${map['type']}'),
      amount: parsedAmount,
      category: '${map['category'] ?? 'Other'}',
      description: map['description'] == null ? null : '${map['description']}',
      date: dateMs is int
          ? DateTime.fromMillisecondsSinceEpoch(dateMs)
          : DateTime.now(),
      paymentMethod: '${map['payment_method'] ?? 'Cash'}',
      createdAt: createdAtMs is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : DateTime.now(),
    );
  }

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Signed amount as used in summaries: expenses are negative.
  double get signedAmount =>
      isIncome ? amount : -amount;

  @override
  String toString() =>
      'Expense(id: $id, type: ${type.key}, amount: $amount, '
      'category: $category, date: $date)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.type == type &&
        other.amount == amount &&
        other.category == category &&
        other.description == description &&
        other.date.millisecondsSinceEpoch == date.millisecondsSinceEpoch &&
        other.paymentMethod == paymentMethod &&
        other.createdAt.millisecondsSinceEpoch ==
            createdAt.millisecondsSinceEpoch;
  }

  @override
  int get hashCode => Object.hash(
        id,
        type,
        amount,
        category,
        description,
        date.millisecondsSinceEpoch,
        paymentMethod,
        createdAt.millisecondsSinceEpoch,
      );
}
