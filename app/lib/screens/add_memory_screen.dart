import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'ui.dart';

// Limits that keep storage use low. Photos are also resized and recompressed on pick.
const int kMaxPhotos = 6;
const int kMaxVideoBytes = 25 * 1024 * 1024;
const int kMaxAudioBytes = 10 * 1024 * 1024;

/// "840 KB", "3.2 MB"
String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _Picked {
  final String path;
  final int bytes;
  const _Picked(this.path, this.bytes);
  String get name => path.split('/').last;
}

/// Capture: add a photo, video, voice note or story to the family's memories.
class AddMemoryScreen extends StatefulWidget {
  final AppUser user;
  final String? initialKind;
  const AddMemoryScreen({super.key, required this.user, this.initialKind});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _title = TextEditingController();
  final _story = TextEditingController();
  final _tag = TextEditingController();
  final _picker = ImagePicker();

  late String _kind;
  final List<_Picked> _files = [];
  final List<String> _tags = [];
  bool _picking = false;
  bool _saving = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    const kinds = ['photo', 'video', 'voice', 'story'];
    _kind = kinds.contains(widget.initialKind) ? widget.initialKind! : 'photo';
    _title.addListener(() {
      if (_showErrors) setState(() {});
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _story.dispose();
    _tag.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _title.text.trim().isNotEmpty || _story.text.trim().isNotEmpty || _files.isNotEmpty || _tags.isNotEmpty;

  void _setKind(String kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _files.clear(); // a memory holds one kind of media
    });
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      switch (_kind) {
        case 'photo':
          final room = kMaxPhotos - _files.length;
          if (room <= 0) {
            showError(context, 'A memory can hold up to $kMaxPhotos photos');
            return;
          }
          // Resized to 1600 px wide and recompressed before anything is uploaded.
          final images = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 75, limit: room);
          for (final image in images.take(room)) {
            _files.add(_Picked(image.path, await File(image.path).length()));
          }
          if (images.length > room && mounted) {
            showInfo(context, 'Kept the first $room. A memory can hold up to $kMaxPhotos photos.');
          }
        case 'video':
          final video = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 60),
          );
          if (video == null) return;
          final bytes = await File(video.path).length();
          if (bytes > kMaxVideoBytes) {
            if (mounted) {
              showError(
                context,
                'This video is ${formatBytes(bytes)}. Please choose one under 25 MB, about a minute long.',
              );
            }
            return;
          }
          _files
            ..clear()
            ..add(_Picked(video.path, bytes));
        case 'voice':
          final file = await FilePicker.pickFile(type: FileType.audio);
          final path = file?.path;
          if (file == null) return;
          if (path == null) {
            if (mounted) showError(context, 'Could not read the selected file');
            return;
          }
          final bytes = await File(path).length();
          if (bytes > kMaxAudioBytes) {
            if (mounted) {
              showError(context, 'This recording is ${formatBytes(bytes)}. Please choose one under 10 MB.');
            }
            return;
          }
          _files
            ..clear()
            ..add(_Picked(path, bytes));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _commitTag([String? raw]) {
    final parts = (raw ?? _tag.text).split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);
    setState(() {
      for (final t in parts) {
        if (!_tags.contains(t) && _tags.length < 12) _tags.add(t);
      }
      _tag.clear();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    _commitTag();
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _showErrors = true);
      showError(context, 'Give this memory a title');
      return;
    }
    if (_kind != 'story' && _files.isEmpty) {
      showError(context, 'Add a ${_kind == 'voice' ? 'recording' : _kind} first, or choose Story');
      return;
    }
    if (_kind == 'story' && _story.text.trim().isEmpty) {
      showError(context, 'Write the story you want to keep');
      return;
    }
    final familyId = widget.user.familyId;
    if (familyId == null) {
      showError(context, 'This account is not part of a family');
      return;
    }
    setState(() => _saving = true);
    final id = newId();
    final ok = await guardOk(context, () async {
      final paths = <String>[];
      for (final f in _files) {
        paths.add(await repo.uploadMemoryMedia(memoryId: id, localPath: f.path));
      }
      await repo.saveMemory(
        Memory(
          id: id,
          familyId: familyId,
          kind: _kind,
          title: title,
          story: _story.text.trim(),
          tags: List.of(_tags),
          mediaPaths: paths,
          createdByName: widget.user.name,
          createdAt: DateTime.now(),
        ),
      );
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showInfo(context, 'Preserved for your family');
      Navigator.pop(context);
    }
  }

  Future<void> _leave() async {
    final discard = await confirm(
      context,
      'This memory has not been saved yet.',
      title: 'Leave without saving?',
      yes: 'Discard',
      no: 'Keep editing',
    );
    if (discard && mounted) {
      setState(() {
        _files.clear();
        _tags.clear();
        _title.clear();
        _story.clear();
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleMissing = _showErrors && _title.text.trim().isEmpty;
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: kCream,
        bottomNavigationBar: PinnedBar(
          child: FilledButton(
            onPressed: _saving || _picking ? null : _save,
            child: _saving
                ? const ButtonSpinner()
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Preserve This Memory'),
                    ],
                  ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Add a Memory', back: true),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    const FieldLabel('What would you like to capture?'),
                    Row(
                      children: [
                        for (final k in const ['photo', 'video', 'voice', 'story']) ...[
                          if (k != 'photo') const SizedBox(width: 10),
                          Expanded(child: _kindTile(k)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_kind != 'story') ...[
                      _dropArea(),
                      for (var i = 0; i < _files.length; i++) _fileTile(i),
                      const SizedBox(height: 22),
                    ] else
                      const SizedBox(height: 4),
                    const FieldLabel('Memory title'),
                    TextField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: "e.g. Nani's 70th birthday",
                        errorText: titleMissing ? 'Give this memory a title' : null,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const FieldLabel('Story behind this memory'),
                    TextField(
                      controller: _story,
                      minLines: _kind == 'story' ? 6 : 3,
                      maxLines: 12,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Write what you remember...'),
                    ),
                    const SizedBox(height: 22),
                    const FieldLabel('Tags'),
                    TextField(
                      controller: _tag,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) {
                        if (v.contains(',')) _commitTag(v);
                      },
                      onSubmitted: _commitTag,
                      decoration: const InputDecoration(
                        hintText: 'Diwali, Dadi, Jaipur',
                        helperText: 'Type a tag and press comma or done',
                        prefixIcon: Icon(Icons.sell_outlined, size: 20),
                      ),
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final t in _tags)
                            InputChip(
                              label: Text(t),
                              deleteIconColor: kMaroon,
                              onDeleted: () => setState(() => _tags.remove(t)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kindTile(String kind) {
    final selected = _kind == kind;
    return Material(
      color: selected ? kBlush : kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? kMaroon : kLine, width: selected ? 1.6 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _setKind(kind),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(memoryIcon(kind), color: selected ? kMaroon : kMuted, size: 24),
              const SizedBox(height: 8),
              Text(
                memoryKindLabel(kind),
                style: body(12.5, weight: 600, color: selected ? kMaroon : kInk),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropArea() {
    final String title;
    final String hint;
    switch (_kind) {
      case 'video':
        title = 'Add a video';
        hint = 'Up to 1 minute and 25 MB';
      case 'voice':
        title = 'Add a voice recording';
        hint = 'Any audio file up to 10 MB';
      default:
        title = 'Add photos or videos';
        hint = _files.isEmpty
            ? 'Tap to choose from your library'
            : '${_files.length} of $kMaxPhotos photos added. Tap to add more';
    }
    return CustomPaint(
      foregroundPainter: const _DashedBorder(),
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _picking || _saving ? null : _pick,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
              child: Column(
                children: [
                  _picking
                      ? const ButtonSpinner(color: kMaroon)
                      : Icon(
                          _kind == 'photo' ? Icons.add_photo_alternate_outlined : memoryIcon(_kind),
                          color: kMaroon,
                          size: 30,
                        ),
                  const SizedBox(height: 14),
                  Text(title, style: body(15, weight: 600)),
                  const SizedBox(height: 6),
                  Text(hint, textAlign: TextAlign.center, style: body(12.5, color: kMuted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fileTile(int i) {
    final f = _files[i];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 46,
              height: 46,
              child: _kind == 'photo'
                  ? Image.file(File(f.path), fit: BoxFit.cover, cacheWidth: 200)
                  : Container(
                      color: kBlush,
                      alignment: Alignment.center,
                      child: Icon(memoryIcon(_kind), color: kMaroon, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13.5, weight: 600)),
                const SizedBox(height: 2),
                Text(formatBytes(f.bytes), style: body(12, color: kMuted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close, size: 20, color: kMuted),
            onPressed: _saving ? null : () => setState(() => _files.removeAt(i)),
          ),
        ],
      ),
    );
  }
}

/// The dashed gold outline of the "Add photos or videos" area.
class _DashedBorder extends CustomPainter {
  const _DashedBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
