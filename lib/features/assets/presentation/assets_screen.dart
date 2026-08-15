import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/web/asset_upload.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/asset_library_repository.dart';
import '../../events/domain/asset_library_entry.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _nameController = TextEditingController();
  AssetType _type = AssetType.image;
  String? _uploadedUrl;
  bool _submitting = false;
  bool _uploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _formValid => _nameController.text.trim().isNotEmpty && _uploadedUrl != null;

  Future<void> _add() async {
    setState(() => _submitting = true);
    await context.read<AssetLibraryRepository>().addEntry(
          name: _nameController.text.trim(),
          url: _uploadedUrl!,
          type: _type,
        );
    _nameController.clear();
    if (mounted) {
      setState(() {
        _uploadedUrl = null;
        _submitting = false;
      });
    }
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final result = await pickAndUploadAsset(_type);
      if (result != null && mounted) {
        setState(() {
          _uploadedUrl = result.url;
          if (_nameController.text.trim().isEmpty) _nameController.text = result.filename;
        });
      }
    } on CloudinaryNotConfiguredException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloudinary isn\'t configured yet — see cloudinary_config.dart.')),
        );
      }
    } on AssetTooLargeException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('File is too large (max 10 MB).')));
      }
    } on AssetUploadTimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Upload timed out. Please try again.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assets', style: AppTypography.display(fontSize: 24)),
              const SizedBox(height: AppSpacing.xs4),
              Text(
                'Reusable art and 3D model files, available from the Quests tab\'s asset pickers.',
                style: AppTypography.body(fontSize: 13, color: AppColors.creamDim),
              ),
              const SizedBox(height: AppSpacing.md20),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md20),
                decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: AppTypography.body(),
                            decoration: const InputDecoration(labelText: 'Name'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm12),
                        DropdownMenu<AssetType>(
                          initialSelection: _type,
                          onSelected: (value) => setState(() => _type = value ?? AssetType.image),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: AssetType.image, label: 'Image'),
                            DropdownMenuEntry(value: AssetType.model3d, label: '3D model'),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.sm12),
                        SizedBox(
                          height: AppSpacing.formFieldHeight,
                          child: OutlinedButton.icon(
                            onPressed: _uploading ? null : _upload,
                            icon: _uploading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.upload_outlined, size: 18),
                            label: Text(_uploadedUrl == null ? 'Choose file' : 'Replace file'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.cream,
                              side: BorderSide(color: AppColors.cream.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm12),
                        SizedBox(
                          height: AppSpacing.formFieldHeight,
                          child: ElevatedButton(
                            onPressed: _formValid && !_submitting ? _add : null,
                            child: _submitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm12),
                    if (_uploadedUrl != null)
                      Text(
                        'Uploaded ✓',
                        style: AppTypography.body(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal),
                      ),
                    Text(
                      _type == AssetType.model3d
                          ? 'Recommended: a compact glTF/GLB model, ideally under 5 MB — well inside the 10 MB upload limit.'
                          : 'Recommended: JPG/PNG around 1200×1200px, under 2 MB — plenty sharp for the in-app cards and well inside the 10 MB upload limit.',
                      style: AppTypography.body(fontSize: 11, color: AppColors.creamDim),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md20),
              Expanded(
                child: StreamBuilder<List<AssetLibraryEntry>>(
                  stream: context.read<AssetLibraryRepository>().watchAll(),
                  builder: (context, snapshot) {
                    final entries = snapshot.data ?? const <AssetLibraryEntry>[];
                    if (entries.isEmpty) {
                      return Center(
                        child: Text('No assets in the library yet.', style: AppTypography.body(color: AppColors.creamDim)),
                      );
                    }
                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm12),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.sm16),
                          decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (entry.type == AssetType.model3d ? AppColors.teal : AppColors.gold)
                                      .withValues(alpha: 0.16),
                                  borderRadius: AppRadii.pillShape,
                                ),
                                child: Text(
                                  entry.type == AssetType.model3d ? '3D' : 'IMG',
                                  style: AppTypography.body(fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.name, style: AppTypography.body(fontWeight: FontWeight.w700)),
                                    Text(
                                      entry.url,
                                      style: AppTypography.body(fontSize: 12, color: AppColors.creamDim),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () => context.read<AssetLibraryRepository>().deleteEntry(entry.id),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
