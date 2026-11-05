import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

/// Screen — Profile / About (PaisaPath redesign).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              'About',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'The PaisaPath story',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── App identity card ─────────────────────────────────────
            _AppIdentityCard(),
            const SizedBox(height: 22),

            // ── Mission ───────────────────────────────────────────────
            _MissionCard(),
            const SizedBox(height: 22),

            // ── Team ──────────────────────────────────────────────────
            _sectionLabel(context, 'The Team'),
            const SizedBox(height: 12),
            const _TeamMember(
              name: 'L. Surya Bhavani',
              role: 'Team Lead · Core engineering, database & deployment',
              icon: Icons.engineering_rounded,
              accentColor: AppTheme.primaryPlum,
            ),
            const SizedBox(height: 8),
            const _TeamMember(
              name: 'K. Lakshmi Prasanna',
              role: 'Dashboard & statistics UI, charts and theming',
              icon: Icons.insights_rounded,
              accentColor: AppTheme.secondaryTeal,
            ),
            const SizedBox(height: 8),
            const _TeamMember(
              name: 'M. Divya',
              role: 'Forms, validation, detail screen, CSV export & settings',
              icon: Icons.edit_note_rounded,
              accentColor: AppTheme.accentCoral,
            ),
            const SizedBox(height: 22),

            // ── Thank you note ────────────────────────────────────────
            _ThankYouCard(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
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
// App Identity Card
// ────────────────────────────────────────────────────────────────────────────
class _AppIdentityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppTheme.primaryPlum, Color(0xFF6B3A6A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryPlum.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: 'Paisa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Path',
                  style: TextStyle(
                    color: AppTheme.secondaryTeal,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppConstants.appTagline,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _InfoBadge(label: 'Version', value: 'v${AppConstants.appVersion}'),
              const SizedBox(width: 12),
              const _InfoBadge(label: 'Platform', value: 'Flutter'),
              const SizedBox(width: 12),
              const _InfoBadge(label: 'DB', value: 'SQLite'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Mission Card
// ────────────────────────────────────────────────────────────────────────────
class _MissionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          _missionRow(context, Icons.offline_bolt_rounded, AppTheme.primaryPlum,
              'Offline-first', 'All data stays on your device in SQLite'),
          _divider(context),
          _missionRow(context, Icons.privacy_tip_outlined, AppTheme.secondaryTeal,
              'Private by design', 'No accounts, no analytics — your data never leaves'),
          _divider(context),
          _missionRow(context, Icons.palette_outlined, AppTheme.accentCoral,
              'Material 3', 'Light & dark themes, responsive across all screens'),
          _divider(context),
          _missionRow(context, Icons.analytics_outlined, AppTheme.primaryPlum,
              'Smart Insights', 'Spending trends, category breakdowns & savings rate'),
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

  Widget _missionRow(BuildContext context, IconData icon, Color color,
      String title, String subtitle) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Team Member
// ────────────────────────────────────────────────────────────────────────────
class _TeamMember extends StatelessWidget {
  const _TeamMember({
    required this.name,
    required this.role,
    required this.icon,
    required this.accentColor,
  });

  final String name;
  final String role;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(role,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Thank You card
// ────────────────────────────────────────────────────────────────────────────
class _ThankYouCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryPlum.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryPlum.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.favorite_rounded, color: AppTheme.primaryPlum, size: 18),
              const SizedBox(width: 8),
              Text('Thank You',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryPlum,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'We sincerely thank the IITM Pravartak and BodhBridge '
            'Flutter Lab for the guidance, sessions and handbooks '
            'that made this project possible, and our mentors and '
            'faculty at KHIT Guntur for their constant support.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Built with Flutter 💙 · PaisaPath - Expenses Tracker',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryPlum.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
