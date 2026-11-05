import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

/// Screen — Add / Edit Transaction (PaisaPath redesign).
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.editTarget});

  final Expense? editTarget;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String? _category;
  String? _paymentMethod;
  bool _saving = false;
  bool _triedToSubmit = false;

  bool get _isEditing => widget.editTarget != null;
  bool get _showIncompleteErrors => _triedToSubmit;

  @override
  void initState() {
    super.initState();
    final Expense? target = widget.editTarget;
    if (target != null) {
      _type = target.type;
      _amountController.text =
          target.amount == target.amount.truncateToDouble()
              ? target.amount.toStringAsFixed(0)
              : target.amount.toStringAsFixed(2);
      _descriptionController.text = target.description ?? '';
      _date = target.date;
      _category = target.category;
      _paymentMethod = target.paymentMethod;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? raw) {
    final String text = (raw ?? '').trim();
    if (text.isEmpty) return 'Amount is required';
    final String cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final double? parsed = double.tryParse(cleaned);
    if (cleaned.isEmpty || parsed == null || parsed.isNaN || parsed.isInfinite) {
      return 'Amount must be numeric';
    }
    final double amount = CurrencyFormatter.parseAmount(text);
    if (amount <= 0) return 'Amount must be greater than zero';
    if (amount > AppConstants.maxAmount) return 'Amount is too large';
    return null;
  }

  String? _validateDescription(String? raw) {
    final String text = (raw ?? '').trim();
    if (text.length > AppConstants.maxDescriptionLength) {
      return 'Description must be at most ${AppConstants.maxDescriptionLength} characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    final bool selectionsOk = _category != null && _paymentMethod != null;
    setState(() => _triedToSubmit = true);
    final bool formOk = _formKey.currentState?.validate() ?? false;
    if (!selectionsOk || !formOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields'), duration: Duration(seconds: 2)),
      );
      return;
    }

    setState(() => _saving = true);
    final ExpenseProvider provider = context.read<ExpenseProvider>();
    final double amount = CurrencyFormatter.parseAmount(_amountController.text);
    final DateTime original = widget.editTarget?.date ?? DateTime.now();
    final DateTime finalDate = DateTime(
      _date.year, _date.month, _date.day,
      original.hour, original.minute,
    );

    final Expense record = Expense(
      id: widget.editTarget?.id,
      type: _type,
      amount: amount,
      category: _category!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: finalDate,
      paymentMethod: _paymentMethod!,
      createdAt: widget.editTarget?.createdAt ?? DateTime.now(),
    );

    final bool ok = _isEditing
        ? await provider.updateExpense(record)
        : await provider.addExpense(record);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Transaction updated'
                : _type == TransactionType.income
                    ? 'Income saved successfully'
                    : 'Expense saved successfully',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      if (_isEditing) {
        Navigator.of(context).pop(true);
        return;
      }
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Update failed. The record may have been deleted.'
            : 'Could not save. Please try again.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isExpense = _type == TransactionType.expense;

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: <Widget>[
              // ── Type Selector ──────────────────────────────────────
              _PaisaTypeSelector(
                selected: _type,
                onChanged: (TransactionType t) => setState(() => _type = t),
              ),
              const SizedBox(height: 24),

              // ── Amount Card ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (isExpense ? AppTheme.accentCoral : AppTheme.secondaryTeal)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: (isExpense ? AppTheme.accentCoral : AppTheme.secondaryTeal)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isExpense ? 'Expense Amount' : 'Income Amount',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isExpense ? AppTheme.accentCoral : AppTheme.secondaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}\.?\d{0,2}')),
                      ],
                      validator: _validateAmount,
                      textInputAction: TextInputAction.next,
                      maxLength: 12,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isExpense ? AppTheme.accentCoral : AppTheme.secondaryTeal,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: '${CurrencyFormatter.symbol} ',
                        prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: (isExpense ? AppTheme.accentCoral : AppTheme.secondaryTeal)
                              .withValues(alpha: 0.5),
                        ),
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Category ───────────────────────────────────────────
              _FormSection(
                title: 'Category',
                errorText: _showIncompleteErrors && _category == null
                    ? 'Please select a category'
                    : null,
                child: _PaisaCategoryGrid(
                  selected: _category,
                  onChanged: (String c) => setState(() => _category = c),
                ),
              ),
              const SizedBox(height: 20),

              // ── Payment Method ─────────────────────────────────────
              _FormSection(
                title: 'Payment Method',
                errorText: _showIncompleteErrors && _paymentMethod == null
                    ? 'Please select a payment method'
                    : null,
                child: _PaymentDropdown(
                  selected: _paymentMethod,
                  onChanged: (String? p) => setState(() => _paymentMethod = p),
                ),
              ),
              const SizedBox(height: 20),

              // ── Date ───────────────────────────────────────────────
              _FormSection(
                title: 'Date',
                child: _DateField(
                  date: _date,
                  onChanged: (DateTime d) => setState(() => _date = d),
                ),
              ),
              const SizedBox(height: 20),

              // ── Description ────────────────────────────────────────
              _FormSection(
                title: 'Description (optional)',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLength: AppConstants.maxDescriptionLength,
                  maxLines: 3,
                  minLines: 2,
                  validator: _validateDescription,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Lunch at the canteen…',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────────
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppTheme.primaryPlum,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Transaction' : 'Save Transaction',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PaisaPath Type Selector
// ────────────────────────────────────────────────────────────────────────────
class _PaisaTypeSelector extends StatelessWidget {
  const _PaisaTypeSelector({required this.selected, required this.onChanged});
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _TypeButton(
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            selected: selected == TransactionType.expense,
            activeColor: AppTheme.accentCoral,
            onTap: () => onChanged(TransactionType.expense),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeButton(
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            selected: selected == TransactionType.income,
            activeColor: AppTheme.secondaryTeal,
            onTap: () => onChanged(TransactionType.income),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? activeColor : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? activeColor : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Form section wrapper
// ────────────────────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child, this.errorText});
  final String title;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child,
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PaisaPath Category grid
// ────────────────────────────────────────────────────────────────────────────
class _PaisaCategoryGrid extends StatelessWidget {
  const _PaisaCategoryGrid({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (int i = 0; i < AppConstants.categories.length; i++)
          _CategoryChip(
            label: AppConstants.categories[i],
            icon: AppConstants.categoryIcons[i],
            color: AppConstants.categoryColors[i],
            selected: selected == AppConstants.categories[i],
            onTap: () => onChanged(AppConstants.categories[i]),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15,
                color: selected ? color : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Payment Dropdown
// ────────────────────────────────────────────────────────────────────────────
class _PaymentDropdown extends StatelessWidget {
  const _PaymentDropdown({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      items: <String>[...AppConstants.paymentMethods].map((String method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: onChanged,
      hint: const Text('Select payment method'),
      decoration: const InputDecoration(hintText: null),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Date Field
// ────────────────────────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: AppConstants.firstSelectableDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
          helpText: 'Select transaction date',
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_month_rounded),
        ),
        child: SizedBox(
          height: 22,
          child: Text(
            _formatDate(date),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}
