import 'package:flutter/material.dart';
import '../theme/meditrack_theme.dart';

/// Shows a standard confirmation dialog for destructive actions.
Future<bool?> showConfirmDeleteDialog(
  BuildContext context, {
  String title = 'Delete Item',
  String content = 'Are you sure you want to delete this item? This action cannot be undone.',
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.cards),
          side: BorderSide(color: context.colors.dividerColor, width: 0.8),
        ),
        title: Text(
          title,
          style: context.titleLarge.copyWith(color: context.colors.errorSos),
        ),
        content: Text(
          content,
          style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Cancel',
              style: context.bodyMedium.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w500),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.errorSos,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Confirm',
              style: context.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );
}

/// Shows normal ranges dialog for various vitals.
void showVitalInfoDialog(BuildContext context, String title, String rangeInfo) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.cards),
          side: BorderSide(color: context.colors.dividerColor, width: 0.8),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: context.colors.primary),
            const SizedBox(width: 8),
            Text(title, style: context.titleLarge),
          ],
        ),
        content: Text(
          'Normal reference range:\n\n$rangeInfo',
          style: context.bodyLarge.copyWith(color: context.colors.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Close',
              style: context.bodyMedium.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
