import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../data/repositories.dart';

/// Camera or library → preview → optional caption → upload to a task.
/// Pops `true` when a photo was uploaded so Task Detail can refresh.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    super.key,
    required this.taskId,
    this.taskTitle,
  });

  final String taskId;
  final String? taskTitle;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  final _caption = TextEditingController();

  Uint8List? _bytes;
  String? _fileName;
  bool _processing = false;
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _error = null;
      _processing = true;
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        requestFullMetadata: false,
      );
      if (picked == null) return; // user cancelled
      final bytes = await _compress(picked);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _fileName = 'IMG_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.jpg';
      });
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = _pickerError(e, source));
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't read that photo: $e");
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Resizes to the photo-quality setting and re-encodes as JPEG, which also
  /// converts iPhone HEIC photos into something browsers can show.
  Future<Uint8List> _compress(XFile picked) async {
    final o = RepositoryScope.of(context).settings.value.photoQuality;
    final out = await FlutterImageCompress.compressWithFile(
      picked.path,
      minWidth: o.maxDimension,
      minHeight: o.maxDimension,
      quality: o.jpegQuality,
      format: CompressFormat.jpeg,
    );
    if (out == null) throw Exception('compression failed');
    return out;
  }

  String _pickerError(PlatformException e, ImageSource source) {
    if (e.code.contains('access_denied')) {
      final what = source == ImageSource.camera ? 'camera' : 'photo library';
      return 'LEAN Hub needs $what access. Turn it on in '
          'Settings → Privacy & Security, then try again.';
    }
    if (e.code == 'no_available_camera') {
      return 'This device has no camera (the Simulator doesn\'t). '
          'Choose from the library instead.';
    }
    return e.message ?? e.code;
  }

  Future<void> _upload() async {
    final bytes = _bytes;
    final fileName = _fileName;
    if (bytes == null || fileName == null) return;
    final repos = RepositoryScope.of(context);
    final userId = repos.auth.currentUserId;
    if (userId == null) return;

    if (repos.settings.value.wifiOnlyUploads &&
        !await repos.connectivity.isOnUnmeteredNetwork()) {
      if (!mounted || !await _confirmCellularUpload()) return;
    }
    if (!mounted) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await repos.files.uploadToTask(
        userId: userId,
        taskId: widget.taskId,
        fileName: fileName,
        bytes: bytes,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'Upload failed: ${friendlyError(e)}';
        });
      }
      return;
    }

    // The files table has no caption column, so the caption is posted as a
    // comment on the task, naming the photo it belongs to.
    final caption = _caption.text.trim();
    String? warning;
    if (caption.isNotEmpty) {
      try {
        await repos.comments.add(
          taskId: widget.taskId,
          authorId: userId,
          content: 'Photo $fileName: $caption',
        );
      } catch (e) {
        warning = "Photo uploaded, but the caption couldn't be saved: ${friendlyError(e)}";
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(warning ?? 'Photo uploaded')));
    context.pop(true);
  }

  Future<bool> _confirmCellularUpload() async {
    final kb = (_bytes!.length / 1024).toStringAsFixed(0);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not on Wi-Fi'),
        content: Text('Wi-Fi-only uploads is turned on in Settings. '
            'Upload this $kb KB photo using cellular data anyway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Wait for Wi-Fi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload anyway'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add photo'),
        bottom: widget.taskTitle == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(widget.taskTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: _processing
            ? const LoadingView()
            : _bytes == null
                ? _buildPicker()
                : _buildReview(),
      ),
    );
  }

  Widget _buildPicker() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MessageView(
              icon: Icons.add_a_photo_outlined,
              title: 'Attach a photo to this task',
              message: 'It will appear under Attachments on the website too.',
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Take photo'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from library'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorText(_error!),
            ],
          ],
        ),
      );

  Widget _buildReview() {
    final kb = (_bytes!.length / 1024).toStringAsFixed(0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(_bytes!, fit: BoxFit.contain),
        ),
        const SizedBox(height: 6),
        Text('$_fileName · $kb KB',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(
          controller: _caption,
          enabled: !_uploading,
          maxLength: 500,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Caption (optional)',
            helperText: 'Posted as a comment on the task',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _uploading ? null : _upload,
          icon: _uploading
              ? const SizedBox.square(
                  dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(_uploading ? 'Uploading…' : 'Upload'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _uploading
              ? null
              : () => setState(() {
                    _bytes = null;
                    _fileName = null;
                    _error = null;
                  }),
          child: const Text('Choose a different photo'),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
}
