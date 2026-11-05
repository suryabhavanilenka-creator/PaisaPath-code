import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

/// Screen — Settings (PaisaPath redesign).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Settings',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Preferences & data',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        children: <Widget>[
          // ── Brand header ──────────────────────────────────────────────
          _BrandHeader(),
          const SizedBox(height: 24),

          // ── Appearance ────────────────────────────────────────────────
          _SectionLabel(label: 'Appearance'),
          const SizedBox(height: 10),
          const _ThemeModeSelector(),
          const SizedBox(height: 24),

          // ── Data ──────────────────────────────────────────────────────
          const _SectionLabel(label: 'Data Management'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.file_download_outlined,
            iconColor: AppTheme.secondaryTeal,
            title: 'Export to CSV',
            subtitle: kIsWeb
                ? 'Download all transactions as a CSV file'
                : 'Share or save your transactions as a CSV file',
            onTap: () => _exportCsv(context),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.delete_sweep_outlined,
            iconColor: Theme.of(context).colorScheme.error,
            title: 'Clear All Data',
            subtitle: 'Permanently delete all saved transactions',
            destructive: true,
            onTap: () => _confirmClearAll(context),
          ),
          const SizedBox(height: 24),

          // ── About ─────────────────────────────────────────────────────
          const _SectionLabel(label: 'About PaisaPath'),
          const SizedBox(height: 10),
          _AboutCard(),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final ExpenseProvider provider = context.read<ExpenseProvider>();
    if (provider.expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export yet'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    try {
      final String path = await const StorageService().exportToCsv(provider.expenses);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle_outlined,
                color: AppTheme.secondaryTeal, size: 40),
            title: const Text('Export complete'),
            content: Text(
              kIsWeb
                  ? 'Your CSV file "$path" was downloaded.'
                  : 'Share sheet opened — choose where to save.\n\nA copy is saved at:\n$path',
              style: const TextStyle(fontSize: 13),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export failed. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final ExpenseProvider provider = context.read<ExpenseProvider>();
    if (provider.expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to clear'), duration: Duration(seconds: 2)),
      );
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.error, size: 40),
          title: const Text('Clear all data?'),
          content: Text(
            'This permanently deletes all ${provider.expenses.length} saved transactions. This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final bool ok = await provider.clearAllExpenses();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'All data cleared' : 'Could not clear data. Please try again.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Brand Header
// ────────────────────────────────────────────────────────────────────────────
class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.primaryPlum,
            const Color(0xFF6B3A6A),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RichText(
                  text: const TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Paisa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'Path',
                        style: TextStyle(
                          color: AppTheme.secondaryTeal,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppConstants.appTagline,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'v${AppConstants.appVersion}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Section label
// ────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryPlum,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryPlum,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Theme Mode Selector
// ────────────────────────────────────────────────────────────────────────────
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (BuildContext context, ThemeProvider themeProvider, _) {
        final ThemeMode mode = themeProvider.themeMode;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            children: <Widget>[
              _modeTile(context, ThemeMode.system, 'System Default',
                  Icons.brightness_auto_rounded, mode,
                  () => context.read<ThemeProvider>().setMode(ThemeMode.system)),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              _modeTile(context, ThemeMode.light, 'Light Mode',
                  Icons.light_mode_rounded, mode,
                  () => context.read<ThemeProvider>().setMode(ThemeMode.light)),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              _modeTile(context, ThemeMode.dark, 'Dark Mode',
                  Icons.dark_mode_rounded, mode,
                  () => context.read<ThemeProvider>().setMode(ThemeMode.dark),
                  isLast: true),
            ],
          ),
        );
      },
    );
  }

  Widget _modeTile(
    BuildContext context,
    ThemeMode value,
    String title,
    IconData icon,
    ThemeMode current,
    VoidCallback onSelect, {
    bool isLast = false,
  }) {
    final bool selected = current == value;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: value == ThemeMode.system ? const Radius.circular(18) : Radius.zero,
        bottom: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryPlum.withValues(alpha: 0.10)
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      size: 18,
                      color: selected
                          ? AppTheme.primaryPlum
                          : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppTheme.primaryPlum : null,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      size: 20, color: AppTheme.primaryPlum),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Settings tile
// ────────────────────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    return Material(
      color: isLight ? Colors.white : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: destructive ? theme.colorScheme.error : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// About Card
// ────────────────────────────────────────────────────────────────────────────
class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          _aboutRow(context, Icons.apps_rounded, AppTheme.primaryPlum,
              'App', 'PaisaPath - Expenses Tracker  v${AppConstants.appVersion}'),
          _divider(context),
          _aboutRow(context, Icons.wifi_off_rounded, AppTheme.secondaryTeal,
              'Offline', 'Works fully without internet'),
          _divider(context),
          _aboutRow(context, Icons.currency_rupee_rounded, AppTheme.accentCoral,
              'Currency', 'Indian Rupees (₹)'),
          _divider(context),
          _aboutRow(context, Icons.storage_rounded, AppTheme.primaryPlum,
              'Storage', 'Local SQLite on this device'),
          _divider(context),
          _aboutRow(context, Icons.lock_outline_rounded, AppTheme.secondaryTeal,
              'Privacy', 'No accounts, no tracking — ever'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryPlum.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Built with Flutter 💙 · ${AppConstants.appTagline}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
    );
  }

  Widget _aboutRow(BuildContext context, IconData icon, Color color, String label, String value) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
