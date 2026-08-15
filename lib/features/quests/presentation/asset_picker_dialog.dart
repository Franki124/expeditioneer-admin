import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/asset_library_repository.dart';
import '../../events/domain/asset_library_entry.dart';

/// Lets the admin pick an existing library entry (filtered to [type]) instead
/// of pasting a URL by hand. Returns the picked URL, or null if cancelled.
Future<String?> showAssetPickerDialog(BuildContext context, {required AssetType type}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => RepositoryProvider.value(
      value: context.read<AssetLibraryRepository>(),
      child: _AssetPickerDialog(type: type),
    ),
  );
}

class _AssetPickerDialog extends StatelessWidget {
  const _AssetPickerDialog({required this.type});

  final AssetType type;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.navyPanel2,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pick from library', style: AppTypography.display(fontSize: 18)),
              const SizedBox(height: AppSpacing.md20),
              Flexible(
                child: StreamBuilder<List<AssetLibraryEntry>>(
                  stream: context.read<AssetLibraryRepository>().watchAll(),
                  builder: (context, snapshot) {
                    final entries =
                        (snapshot.data ?? const <AssetLibraryEntry>[]).where((e) => e.type == type).toList();
                    if (entries.isEmpty) {
                      return Text(
                        'No ${type == AssetType.image ? 'image' : '3D model'} entries in the library yet.',
                        style: AppTypography.body(color: AppColors.creamDim),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          title: Text(entry.name, style: AppTypography.body(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            entry.url,
                            style: AppTypography.body(fontSize: 12, color: AppColors.creamDim),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(entry.url),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
