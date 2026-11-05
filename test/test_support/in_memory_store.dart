import 'package:paisapath/models/expense.dart';
import 'package:paisapath/services/database_service.dart';

/// Deterministic in-memory [TransactionStore] used across provider and
/// widget tests. Mirrors the SQLite service semantics including the
/// "already deleted → rows affected 0" contract.
class InMemoryStore implements TransactionStore {
  InMemoryStore({this.seed = const <Expense>[]}) {
    // Seed records are loaded into the live map immediately so that
    // [loadAll] serves them without an explicit reset() call.
    reset();
  }

  final Map<int, Expense> _records = <int, Expense>{};
  int _nextId = 1;

  /// Simulated storage failure switch used by error-state tests.
  bool failOnLoad = false;

  List<Expense> seed = const <Expense>[];

  @override
  Future<void> open() async {}

  @override
  Future<List<Expense>> loadAll() async {
    if (failOnLoad) {
      throw StateError('Simulated storage failure');
    }
    final List<Expense> list = _records.values.toList();
    list.sort((Expense a, Expense b) {
      final int byDate =
          b.date.millisecondsSinceEpoch - a.date.millisecondsSinceEpoch;
      if (byDate != 0) return byDate;
      return (b.createdAt.millisecondsSinceEpoch -
          a.createdAt.millisecondsSinceEpoch);
    });
    return list;
  }

  @override
  Future<int> insert(Expense expense) async {
    final int id = _nextId++;
    _records[id] = expense.copyWith(id: id);
    return id;
  }

  @override
  Future<int> update(Expense expense) async {
    final int? id = expense.id;
    if (id == null || !_records.containsKey(id)) return 0;
    _records[id] = expense.copyWith(id: id);
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    if (!_records.containsKey(id)) return 0;
    _records.remove(id);
    return 1;
  }

  @override
  Future<int> clearAll() async {
    final int count = _records.length;
    _records.clear();
    return count;
  }

  @override
  Future<void> close() async {}

  /// Restores the configured seed data.
  void reset() {
    _records.clear();
    _nextId = 1;
    for (final Expense e in seed) {
      _records[_nextId++] = e;
    }
  }

  int get count => _records.length;
}
