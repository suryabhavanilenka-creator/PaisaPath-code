import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/expense.dart';

/// Storage abstraction implemented by SQLite on-device and by the
/// in-memory fake in `test/`, keeping unit and widget tests offline-safe.
abstract class TransactionStore {
  /// Opens/creates the underlying storage. Must be idempotent.
  Future<void> open();

  /// Returns every transaction ordered newest-first by date.
  Future<List<Expense>> loadAll();

  /// Inserts a record and returns its database id.
  Future<int> insert(Expense expense);

  /// Updates an existing record. Returns rows affected (0 if missing).
  Future<int> update(Expense expense);

  /// Deletes a record. Returns rows affected (0 if already deleted).
  Future<int> delete(int id);

  /// Deletes every record. Returns rows affected.
  Future<int> clearAll();

  Future<void> close();
}

/// SQLite-backed implementation of [TransactionStore] using the `sqflite`
/// package. All queries run on the SQLite helper's background thread pool so
/// heavy reads never block the UI.
class DatabaseService implements TransactionStore {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  bool _opening = false;
  final List<Future<void>> _pendingOpens = <Future<void>>[];

  /// Public constructor used by tests that want to inject a custom DB path.
  DatabaseService.forTest(this._dbPath);

  String? _dbPath;

  Future<Database> get database async {
    if (_opening) {
      // Someone is already opening: await the same future instead of
      // opening a second connection.
      await Future.wait(_pendingOpens);
    }
    final Database? local = _db;
    if (local != null && local.isOpen) return local;
    return _open();
  }

  @override
  Future<void> open() => database;

  Future<Database> _open() async {
    _opening = true;
    final Future<Database> pending = _doOpen();
    _pendingOpens.add(pending.then<void>((_) {}));
    try {
      return await pending;
    } finally {
      _opening = false;
      _pendingOpens.remove(pending.then<void>((_) {}));
      _pendingOpens.clear();
    }
  }

  Future<Database> _doOpen() async {
    if (_db != null && _db!.isOpen) return _db!;
    if (kIsWeb) {
      // Browser: route sqflite through the SQLite-WASM factory instead of
      // the unavailable mobile plugin. The WASM database is persisted by
      // the browser (OPFS/IndexedDB), so data survives page reloads.
      databaseFactory = databaseFactoryFfiWeb;
    }
    final String dir = _dbPath ?? (await _databasesDirectory());
    final Database db = await openDatabase(
      '$dir/paisapath.db',
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _db = db;
    return db;
  }

  Future<String> _databasesDirectory() async {
    return (await databaseFactory.getDatabasesPath());
  }

  Future<void> _onConfigure(Database db) async {
    if (kIsWeb) {
      // The WASM build runs on the browser-managed OPFS filesystem; the
      // journal-mode pragma is unnecessary there.
      return;
    }
    // Foreign keys are not required (single table) but WAL improves speed.
    await db.execute('PRAGMA journal_mode=WAL;');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        type          TEXT NOT NULL,
        amount        REAL NOT NULL,
        category      TEXT NOT NULL,
        description   TEXT,
        date          INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        created_at    INTEGER NOT NULL
      );
      ''');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date);');
    await db.execute(
        'CREATE INDEX idx_transactions_category ON transactions(category);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Reserved for schema migrations in future releases.
  }

  @override
  Future<List<Expense>> loadAll() async {
    try {
      final Database db = await database;
      final List<Map<String, Object?>> rows = await db.query(
        'transactions',
        orderBy: 'date DESC, id DESC',
      );
      return rows.map(Expense.fromMap).toList();
    } catch (_) {
      rethrow; // Provider turns this into an error state + Retry button.
    }
  }

  @override
  Future<int> insert(Expense expense) async {
    if (expense.amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
    try {
      final Database db = await database;
      final int id = await db.insert('transactions', expense.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return id;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<int> update(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Cannot update a record without an id.');
    }
    try {
      final Database db = await database;
      final int rows = await db.update(
        'transactions',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[expense.id],
      );
      return rows;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final Database db = await database;
      final int rows =
          await db.delete('transactions', where: 'id = ?', whereArgs: <Object?>[id]);
      return rows;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<int> clearAll() async {
    try {
      final Database db = await database;
      final int rows = await db.delete('transactions');
      return rows;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    final Database? db = _db;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _db = null;
  }
}
