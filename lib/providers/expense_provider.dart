import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import '../utils/date_formatter.dart';

/// Central state holder for all transactions and derived analytics.
///
/// Screens never read the database directly; they observe this provider and
/// it notifies them whenever persisted data, filters or sort orders change.
class ExpenseProvider extends ChangeNotifier {
  /// Creates the provider, starts initial load immediately.
  ExpenseProvider({TransactionStore? store})
      : _store = store ?? DatabaseService.instance {
    // Initial load kicked off lazily via [ensureLoaded] by the dashboard so
    // widget tests can pump first and control timing deterministically.
  }

  final TransactionStore _store;

  List<Expense> _expenses = <Expense>[];
  bool _loading = false;
  bool _initialised = false;
  String? _error;
  bool _busy = false; // add / update / delete / clear in flight

  // --- Filters / search / sort --------------------------------------------
  String _searchQuery = '';
  String? _categoryFilter; // null = All categories
  String? _monthFilter; // null = All time; key = '2026-11'
  String _typeFilter = 'all'; // all | expense | income
  bool _newestFirst = true;

  // --- Read-only state ----------------------------------------------------
  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get loading => _loading;
  bool get initialised => _initialised;
  bool get busy => _busy;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  String? get monthFilter => _monthFilter;
  String get typeFilter => _typeFilter;
  bool get newestFirst => _newestFirst;
  bool get isEmptyState => !_loading && _error == null && _expenses.isEmpty;
  bool get hasFilters =>
      _searchQuery.isNotEmpty ||
      _categoryFilter != null ||
      _monthFilter != null ||
      _typeFilter != 'all';

  // --- Loading / retry ----------------------------------------------------

  /// Idempotent initial data load. Safe to call from multiple widgets.
  Future<void> ensureLoaded() async {
    if (_initialised || _loading) return;
    await loadExpenses();
  }

  /// (Re)loads all records from the store.
  Future<void> loadExpenses() async {
    if (_loading) return; // guard against rapid retry taps
    _loading = true;
    // Only wipe the error now; keep displayed data during background reloads.
    _error = null;
    notifyListeners();
    try {
      final List<Expense> loaded = await _store.loadAll();
      _expenses = loaded;
      _initialised = true;
      _error = null;
    } catch (e) {
      _error = 'Could not load your expenses.\nPlease check your device storage and try again.';
      debugPrint('ExpenseProvider.loadExpenses failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Called by the Retry button in the error state.
  Future<void> retry() => loadExpenses();

  // --- CRUD ----------------------------------------------------------------

  /// Persists a new record. Returns true on success, false on failure
  /// (e.g. store error); also guards against duplicate submissions.
  Future<bool> addExpense(Expense expense) async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      final int id = await _store.insert(expense);
      // Avoid duplicate notification races when two adds overlap.
      _expenses = <Expense>[..._expenses, expense.copyWith(id: id)];
      _initialised = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ExpenseProvider.addExpense failed: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Persists edits to an existing record.
  Future<bool> updateExpense(Expense updated) async {
    if (updated.id == null || _busy) return false;
    _busy = true;
    notifyListeners();
    try {
      final int rows = await _store.update(updated);
      if (rows > 0) {
        _expenses = _expenses
            .map((Expense e) => e.id == updated.id
                ? updated.copyWith(id: updated.id)
                : e)
            .toList();
        _error = null;
        notifyListeners();
        return true;
      }
      // Record vanished (already deleted). Reload authoritative data.
      await loadExpenses();
      return false;
    } catch (e) {
      debugPrint('ExpenseProvider.updateExpense failed: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Deletes by id. Works for repeated deletes: a missing id still removes
  /// any lingering cached copy locally.
  Future<bool> deleteExpense(int id) async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      await _store.delete(id);
      _expenses = _expenses.where((Expense e) => e.id != id).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ExpenseProvider.deleteExpense failed: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Wipes all data (Settings screen, with confirmation in the UI).
  Future<bool> clearAllExpenses() async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      await _store.clearAll();
      _expenses = <Expense>[];
      _error = null;
      _resetFilters();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ExpenseProvider.clearAllExpenses failed: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // --- Search / filters / sort --------------------------------------------

  void setSearchQuery(String query) {
    final String normalised = query.trim();
    if (normalised == _searchQuery) return;
    _searchQuery = normalised;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    if (category == _categoryFilter) return;
    _categoryFilter = category;
    notifyListeners();
  }

  void setMonthFilter(String? monthKey) {
    if (monthKey == _monthFilter) return;
    _monthFilter = monthKey;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    if (type == _typeFilter) return;
    _typeFilter = type;
    notifyListeners();
  }

  void toggleSortOrder() {
    _newestFirst = !_newestFirst;
    notifyListeners();
  }

  void setSortOrder(bool newestFirst) {
    if (_newestFirst == newestFirst) return;
    _newestFirst = newestFirst;
    notifyListeners();
  }

  /// Clears every list filter (used by error widgets and "No results" CTA).
  void resetFilters() {
    if (!_hasAnyFilterInternal) return;
    _resetFilters();
    notifyListeners();
  }

  bool get _hasAnyFilterInternal =>
      _searchQuery.isNotEmpty ||
      _categoryFilter != null ||
      _monthFilter != null ||
      _typeFilter != 'all';

  void _resetFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _monthFilter = null;
    _typeFilter = 'all';
    _newestFirst = true;
  }

  // --- Derived lists (always computed from persisted data) -----------------

  /// Applies search + filters + sort. Powers the dashboard list, the
  /// statistics figures and the CSV export.
  List<Expense> get filteredExpenses {
    final Iterable<Expense> base = _searchFilterType();
    final List<Expense> result = base.toList()
      ..sort((Expense a, Expense b) {
        // Secondary sort key: created order, so same-day entries stay stable.
        final int byDate =
            b.date.millisecondsSinceEpoch - a.date.millisecondsSinceEpoch;
        if (byDate != 0) return byDate;
        return (b.createdAt.millisecondsSinceEpoch -
            a.createdAt.millisecondsSinceEpoch);
      });
    if (!_newestFirst) {
      return result.reversed.toList();
    }
    return result;
  }

  Iterable<Expense> _searchFilterType() {
    final String query = _searchQuery.toLowerCase();
    return _expenses.where((Expense e) {
      if (_typeFilter == 'expense' && !e.isExpense) return false;
      if (_typeFilter == 'income' && !e.isIncome) return false;
      if (_categoryFilter != null && e.category != _categoryFilter) return false;
      if (_monthFilter != null && DateFormatter.monthKey(e.date) != _monthFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final String haystack = '${e.description ?? ''} ${e.category} '
            '${e.paymentMethod}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    });
  }

  /// Months (keys) that actually contain saved data, newest first — used to
  /// build the month filter picker.
  List<String> get availableMonths {
    final Set<String> keys = _expenses.map((Expense e) => DateFormatter.monthKey(e.date)).toSet();
    final DateTime now = DateTime.now();
    keys.add(DateFormatter.monthKey(now));
    final List<String> sorted = keys.toList()..sort((String a, String b) => b.compareTo(a));
    return sorted;
  }

  // --- Summaries -----------------------------------------------------------

  double get totalIncome {
    double sum = 0;
    for (final Expense e in _expenses) {
      if (e.isIncome) sum += e.amount;
    }
    return sum;
  }

  double get totalExpense {
    double sum = 0;
    for (final Expense e in _expenses) {
      if (e.isExpense) sum += e.amount;
    }
    return sum;
  }

  double get netBalance => totalIncome - totalExpense;

  /// Count of currently visible (filtered) transactions.
  int get filteredCount {
    int count = 0;
    final Iterator<Expense> it = _searchFilterType().iterator;
    while (it.moveNext()) {
      count++;
    }
    return count;
  }

  /// Spending in the current calendar month (all data, unfiltered).
  double get monthlyExpense {
    final DateTime now = DateTime.now();
    return sumExpense(_expenses.where((Expense e) =>
        e.isExpense && DateFormatter.monthKey(e.date) == DateFormatter.monthKey(now)));
  }

  /// Spending that happened today.
  double get todaysExpense {
    final DateTime today = DateFormatter.dateOnly(DateTime.now());
    return sumExpense(_expenses.where((Expense e) =>
        e.isExpense && DateFormatter.dateOnly(e.date) == today));
  }

  /// Total income in the current calendar month.
  double get monthlyIncome {
    final DateTime now = DateTime.now();
    return sumAll(_expenses.where((Expense e) =>
        e.isIncome && DateFormatter.monthKey(e.date) == DateFormatter.monthKey(now)));
  }

  /// Expenses in the current calendar month only, totalled.
  double get monthOnlyExpense {
    final DateTime now = DateTime.now();
    return sumExpense(_expenses.where((Expense e) =>
        e.isExpense && DateFormatter.monthKey(e.date) == DateFormatter.monthKey(now)));
  }

  /// Category → expense total over [rangeTotals] respected filters.
  Map<String, double> get categoryBreakdown {
    final Map<String, double> totals = <String, double>{};
    for (final Expense e in filteredExpenses.where((Expense e) => e.isExpense)) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final List<MapEntry<String, double>> sorted = totals.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(sorted);
  }

  /// Total spent in the highest category (0 when no data).
  MapEntry<String, double>? get highestCategory {
    final Map<String, double> breakdown = categoryBreakdown;
    if (breakdown.isEmpty) return null;
    final MapEntry<String, double> top = breakdown.entries.first;
    return top;
  }

  /// Average daily spending for the current month (unfiltered footer stat).
  double get averageDailySpend {
    final DateTime now = DateTime.now();
    final bool isCurrentMonth = _isCurrentMonthScope();
    final int dayOfNow = now.day;
    if (isCurrentMonth && dayOfNow > 0) {
      return monthOnlyExpense / dayOfNow;
    }
    final int daysInMonth = _daysInMonth(now.year, now.month);
    return daysInMonth > 0 ? monthOnlyExpense / daysInMonth : 0;
  }

  bool _isCurrentMonthScope() => true;

  static int _daysInMonth(int year, int month) {
    // DateTime truncation trick: day 0 of next month = last day of this month.
    if (month == 12) return DateTime(year, 12, 31).day;
    return DateTime(year, month + 1, 0).day;
  }

  /// Expense totals for the last [months] calendar months, oldest first.
  /// Keys are month keys (`2026-11`).
  Map<String, double> monthlyTotals(int months) {
    final Map<String, double> result = <String, double>{};
    final DateTime now = DateTime.now();
    for (int i = months - 1; i >= 0; i--) {
      final DateTime month = DateTime(now.year, now.month - i);
      result[DateFormatter.monthKey(month)] = 0;
    }
    for (final Expense e in _expenses) {
      if (!e.isExpense) continue;
      final String key = DateFormatter.monthKey(e.date);
      if (result.containsKey(key)) {
        result[key] = result[key]! + e.amount;
      }
    }
    return result;
  }

  /// Income totals for the last [months] calendar months, oldest first.
  /// Keys are month keys (`2026-11`) — mirrors [monthlyTotals].
  Map<String, double> monthlyIncomeTotals(int months) {
    final Map<String, double> result = <String, double>{};
    final DateTime now = DateTime.now();
    for (int i = months - 1; i >= 0; i--) {
      final DateTime month = DateTime(now.year, now.month - i);
      result[DateFormatter.monthKey(month)] = 0;
    }
    for (final Expense e in _expenses) {
      if (!e.isIncome) continue;
      final String key = DateFormatter.monthKey(e.date);
      if (result.containsKey(key)) {
        result[key] = result[key]! + e.amount;
      }
    }
    return result;
  }

  /// Daily expense totals for the visible month
  /// (day-of-month → amount). Used by the dashboard overview chart.
  Map<int, double> dailyTotalsForMonth(DateTime month) {
    final Map<int, double> totals = <int, double>{};
    final int days = _daysInMonth(month.year, month.month);
    final DateTime today = DateTime.now();
    final int lastVisibleDay =
        (month.year == today.year && month.month == today.month)
            ? today.day
            : days;
    for (int d = 1; d <= lastVisibleDay; d++) {
      totals[d] = 0;
    }
    for (final Expense e in _expenses) {
      if (!e.isExpense) continue;
      if (e.date.year != month.year || e.date.month != month.month) continue;
      totals[e.date.day] = (totals[e.date.day] ?? 0) + e.amount;
    }
    return totals;
  }

  /// Last-seven-days daily expense series (for dashboard overview).
  Map<DateTime, double> last7DaysTotals() {
    final DateTime today = DateFormatter.dateOnly(DateTime.now());
    final Map<DateTime, double> result = <DateTime, double>{};
    for (int i = 6; i >= 0; i--) {
      result[today.subtract(Duration(days: i))] = 0;
    }
    for (final Expense e in _expenses) {
      if (!e.isExpense) continue;
      final DateTime key = DateFormatter.dateOnly(e.date);
      if (result.containsKey(key)) {
        result[key] = result[key]! + e.amount;
      }
    }
    return result;
  }

  static double sumExpense(Iterable<Expense> items) {
    double sum = 0;
    for (final Expense e in items) {
      if (e.isExpense) sum += e.amount;
    }
    return sum;
  }

  static double sumAll(Iterable<Expense> items) {
    double sum = 0;
    for (final Expense e in items) {
      sum += e.amount;
    }
    return sum;
  }
}
