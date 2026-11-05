import 'package:flutter/material.dart';

/// Loading state widget (dashboard statistics re-generate while data loads).
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.label = 'Loading your expenses…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(strokeWidth: 2.6),
            const SizedBox(height: 16),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
