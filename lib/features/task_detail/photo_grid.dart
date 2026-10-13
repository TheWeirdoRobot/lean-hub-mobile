import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../models/task_file.dart';

/// Thumbnails for image attachments. Signed URLs change on every load, so the
/// image cache is keyed by the stable storage path instead.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key, required this.photos, required this.urls});

  final List<TaskFile> photos;

  /// Signed URL per file_path; a missing entry shows a broken-image tile.
  final Map<String, String> urls;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, i) {
          final photo = photos[i];
          final url = urls[photo.filePath];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: InkWell(
                onTap: url == null
                    ? null
                    : () => Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            fullscreenDialog: true,
                            builder: (_) => PhotoViewer(photo: photo, url: url),
                          ),
                        ),
                child: url == null
                    ? const _BrokenTile()
                    : Semantics(
                        label: photo.fileName,
                        image: true,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          cacheKey: photo.filePath,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          placeholder: (_, _) => const Center(
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, _, _) => const _BrokenTile(),
                        ),
                      ),
              ),
            ),
          );
        },
      );
}

class _BrokenTile extends StatelessWidget {
  const _BrokenTile();

  @override
  Widget build(BuildContext context) => Center(
        child: Icon(Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

/// Full-screen, pinch-to-zoom view of one photo.
class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.photo, required this.url});

  final TaskFile photo;
  final String url;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (photo.uploaderName != null) photo.uploaderName!,
      if (photo.createdAt != null) fmtDate(photo.createdAt, pattern: 'MMM d, h:mm a'),
      if (photo.formattedSize.isNotEmpty) photo.formattedSize,
    ].join(' · ');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(photo.fileName, style: const TextStyle(fontSize: 16)),
            if (details.isNotEmpty)
              Text(details, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: url,
            cacheKey: photo.filePath,
            fit: BoxFit.contain,
            placeholder: (_, _) => const CircularProgressIndicator(),
            errorWidget: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}
