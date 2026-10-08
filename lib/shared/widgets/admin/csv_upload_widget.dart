import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../features/admin/domain/services/csv_template_service.dart';
import '../common/shimmer_loading.dart';

class CsvUploadWidget extends ConsumerStatefulWidget {
  final Function(File) onFileSelected;
  final bool isLoading;

  const CsvUploadWidget({
    super.key,
    required this.onFileSelected,
    this.isLoading = false,
  });

  @override
  ConsumerState<CsvUploadWidget> createState() => _CsvUploadWidgetState();
}

class _CsvUploadWidgetState extends ConsumerState<CsvUploadWidget> {
  final bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDragging
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.outline,
            width: _isDragging ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: _isDragging
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Quiz CSV',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Drag and drop your CSV file here or click to browse',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                // Use column layout for narrow screens
                if (constraints.maxWidth < 400) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: widget.isLoading ? null : _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Browse Files'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: widget.isLoading ? null : _downloadTemplate,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Template'),
                      ),
                    ],
                  );
                }
                // Use row layout for wider screens
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.isLoading ? null : _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Browse Files'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.isLoading ? null : _downloadTemplate,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Template'),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (widget.isLoading) ...[
              const SizedBox(height: 24),
              const ShimmerLoading.rectangular(
                width: double.infinity,
                height: 8,
              ),
              const SizedBox(height: 8),
              const ShimmerLoading.rectangular(
                width: double.infinity,
                height: 8,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        widget.onFileSelected(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      await CsvTemplateService.downloadTemplate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
