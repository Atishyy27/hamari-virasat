import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/site_content.dart';
import '../theme.dart';
import 'add_memory_screen.dart' show formatBytes, kMaxAudioBytes, kMaxPhotos;
import 'site_ui.dart';
import 'ui.dart';

const _addCustom = '__add_custom__';

/// Add or edit a ritual. Started from a catalogue ritual ([templateKey], or an existing
/// ritual that has one) it becomes the website's guided form: that ritual's sub-sections
/// in order, with save and resume. Without one it is the free-form family ritual.
class RitualFormScreen extends StatefulWidget {
  final AppUser user;
  final Ritual? existing;
  final String? templateKey;

  const RitualFormScreen({super.key, required this.user, this.existing, this.templateKey});

  @override
  State<RitualFormScreen> createState() => _RitualFormScreenState();
}

class _RitualFormScreenState extends State<RitualFormScreen> {
  late final String _id;
  late final TextEditingController _title;
  late final TextEditingController _samagri;
  late final TextEditingController _steps;
  late final TextEditingController _roles;
  late final TextEditingController _songs;
  late final TextEditingController _info;
  late final TextEditingController _gotra;
  late final TextEditingController _kuldevi;
  late final TextEditingController _kuldevta;
  final Map<String, TextEditingController> _sectionCtl = {};
  final _picker = ImagePicker();
  RitualTemplate? _template;
  late String _status;
  List<String> _photoPaths = [];
  List<TextEditingController> _captionCtl = [];

  List<RitualCategory> _categories = const [];
  String? _category;
  String _phase = '';
  List<Recipe> _recipes = [];
  List<String> _audioPaths = [];
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  bool _dirty = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _id = e?.id ?? newId();
    _title = TextEditingController(text: e?.title ?? '');
    _samagri = TextEditingController(text: e?.samagri ?? '');
    _steps = TextEditingController(text: e?.steps ?? '');
    _roles = TextEditingController(text: e?.relativeRoles ?? '');
    _songs = TextEditingController(text: e?.songs ?? '');
    _info = TextEditingController(text: e?.additionalInfo ?? '');
    final saved = e?.sections ?? const <String, String>{};
    _gotra = TextEditingController(text: saved['Gotra'] ?? '');
    _kuldevi = TextEditingController(text: saved['Kuldevi'] ?? '');
    _kuldevta = TextEditingController(text: saved['Kuldevta'] ?? '');
    _template = templateFor(e?.templateKey ?? widget.templateKey ?? '');
    final template = _template;
    if (template != null) {
      if (e == null && !template.isDiy) _title.text = template.title;
      for (final s in template.subSections) {
        if (s.kind == SectionKind.text) {
          _sectionCtl[s.name] = TextEditingController(text: saved[s.name] ?? '');
        }
      }
    }
    // A new guided ritual starts as a draft; a free-form one is final as soon as it is saved.
    _status = e?.status ?? (template == null ? kStatusApproved : kStatusDraft);
    _photoPaths = List.of(e?.photoPaths ?? const []);
    _captionCtl = [
      for (var i = 0; i < _photoPaths.length; i++)
        TextEditingController(text: i < (e?.photoCaptions.length ?? 0) ? e!.photoCaptions[i] : ''),
    ];
    for (final c in [
      _title,
      _samagri,
      _steps,
      _roles,
      _songs,
      _info,
      _gotra,
      _kuldevi,
      _kuldevta,
      ..._sectionCtl.values,
      ..._captionCtl,
    ]) {
      c.addListener(_markDirty);
    }
    _category = (e == null || e.category.isEmpty) ? template?.stage : e.category;
    _phase = e?.phase ?? '';
    _recipes = List.of(e?.recipes ?? const []);
    _audioPaths = List.of(e?.audioPaths ?? const []);
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _samagri.dispose();
    _steps.dispose();
    _roles.dispose();
    _songs.dispose();
    _info.dispose();
    _gotra.dispose();
    _kuldevi.dispose();
    _kuldevta.dispose();
    for (final c in [..._sectionCtl.values, ..._captionCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    // While errors are showing, rebuild on every keystroke so they clear as soon as they are fixed.
    if (_dirty && !_showErrors) return;
    setState(() => _dirty = true);
  }

  Future<void> _loadCategories() async {
    final categories = await guard(context, () => repo.listCategories());
    if (!mounted) return;
    // Gotra, Kuldevi and Kuldevta start from what the family has already saved.
    Family? family;
    if (_gotra.text.isEmpty && _kuldevi.text.isEmpty && _kuldevta.text.isEmpty) {
      try {
        family = await repo.myFamily();
      } catch (_) {}
    }
    if (!mounted) return;
    final wasDirty = _dirty;
    if (family != null) {
      _gotra.text = family.gotra;
      _kuldevi.text = family.kuldevi;
      _kuldevta.text = family.kuldevta;
    }
    setState(() {
      _categories = categories ?? _categories;
      _loading = false;
      _dirty = wasDirty;
    });
  }

  Future<void> _pickPhotos() async {
    final room = kMaxPhotos - _photoPaths.length;
    if (room <= 0) {
      showError(context, 'A ritual can hold up to $kMaxPhotos photos');
      return;
    }
    setState(() => _uploading = true);
    try {
      // Same limits as memories: resized and recompressed on the phone before upload.
      final images = room == 1
          ? [await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 75)]
              .whereType<XFile>()
              .toList()
          : await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 75, limit: room);
      for (final image in images.take(room)) {
        final stored = await repo.uploadRitualPhoto(ritualId: _id, localPath: image.path);
        if (!mounted) return;
        final caption = TextEditingController()..addListener(_markDirty);
        setState(() {
          _photoPaths.add(stored);
          _captionCtl.add(caption);
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  List<String> get _phases {
    for (final c in _categories) {
      if (c.name == _category) return c.phases;
    }
    return const [];
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add a custom ritual'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(c, true),
          decoration: const InputDecoration(
            labelText: 'Ritual category name',
            hintText: 'e.g. Griha Pravesh',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Add')),
        ],
      ),
    );
    final name = controller.text.trim();
    if (save != true || name.isEmpty || !mounted) return;
    final ok = await guardOk(context, () => repo.addCustomCategory(name));
    if (!ok || !mounted) return;
    await _loadCategories();
    if (!mounted) return;
    setState(() {
      _category = name;
      _phase = '';
      _dirty = true;
    });
  }

  Future<void> _editRecipe([int? index]) async {
    final existing = index == null ? null : _recipes[index];
    final name = TextEditingController(text: existing?.name ?? '');
    final ingredients = TextEditingController(text: existing?.ingredients ?? '');
    final method = TextEditingController(text: existing?.method ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(existing == null ? 'Add recipe' : 'Edit recipe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Recipe name', hintText: 'e.g. Gud ki Kheer'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ingredients,
                maxLines: 5,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ingredients',
                  hintText: 'One ingredient per line',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: method,
                maxLines: 7,
                minLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Method',
                  hintText: 'One step per line',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (save != true || !mounted) return;
    if (name.text.trim().isEmpty) {
      showError(context, 'Recipe name cannot be empty');
      return;
    }
    final recipe = Recipe(
      id: existing?.id ?? newId(),
      name: name.text.trim(),
      ingredients: ingredients.text.trim(),
      method: method.text.trim(),
    );
    setState(() {
      if (index == null) {
        _recipes.add(recipe);
      } else {
        _recipes[index] = recipe;
      }
      _dirty = true;
    });
  }

  Future<void> _pickAudio() async {
    setState(() => _uploading = true);
    try {
      // file_picker API: pickFile() returns a PlatformFile, or null when cancelled.
      final file = await FilePicker.pickFile(type: FileType.audio);
      final path = file?.path;
      if (file == null) return;
      if (path == null) {
        if (mounted) showError(context, 'Could not read the selected file');
        return;
      }
      // Keeps storage use low: long recordings are turned away before any upload.
      final bytes = await File(path).length();
      if (bytes > kMaxAudioBytes) {
        if (mounted) {
          showError(context, 'This recording is ${formatBytes(bytes)}. Please choose one under 10 MB.');
        }
        return;
      }
      final stored = await repo.uploadAudio(ritualId: _id, localPath: path);
      if (mounted) {
        setState(() {
          _audioPaths.add(stored);
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save({String? status}) async {
    FocusScope.of(context).unfocus();
    final title = _title.text.trim();
    final category = _category;
    if (title.isEmpty || category == null) {
      setState(() => _showErrors = true);
      showError(context, title.isEmpty ? 'Give the ritual a title' : 'Choose a ritual category');
      return;
    }
    final familyId = widget.existing?.familyId ?? widget.user.familyId;
    if (familyId == null) {
      showError(context, 'This account is not part of a family');
      return;
    }
    final ritual = Ritual(
      id: _id,
      familyId: familyId,
      title: title,
      category: category,
      phase: _phase,
      samagri: _samagri.text.trim(),
      steps: _steps.text.trim(),
      relativeRoles: _roles.text.trim(),
      recipes: _recipes,
      audioPaths: _audioPaths,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      status: status ?? _status,
      templateKey: _template?.key ?? widget.existing?.templateKey ?? '',
      songs: _songs.text.trim(),
      additionalInfo: _info.text.trim(),
      photoPaths: _photoPaths,
      photoCaptions: [for (final c in _captionCtl) c.text.trim()],
      sections: {
        // Keep answers saved earlier under names this form no longer shows.
        ...?widget.existing?.sections,
        for (final e in _sectionCtl.entries) e.key: e.value.text.trim(),
        'Gotra': _gotra.text.trim(),
        'Kuldevi': _kuldevi.text.trim(),
        'Kuldevta': _kuldevta.text.trim(),
      },
    );
    setState(() => _saving = true);
    final ok = await guardOk(context, () => repo.saveRitual(ritual));
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _dirty = false;
        _status = ritual.status;
      }
    });
    if (ok) {
      showInfo(
        context,
        status == kStatusSubmitted
            ? 'Submitted. Your draft will be ready within 7 days.'
            : (ritual.status == kStatusDraft ? 'Draft saved. Come back any time.' : 'Saved to your Virasat'),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    final ok = await confirm(
      context,
      'Your answers go to the Hamari Virasat team, who prepare a draft document for your approval. '
      'You can still edit this ritual afterwards.',
      title: 'Submit for documentation?',
      yes: 'Submit',
      no: 'Not yet',
    );
    if (ok && mounted) await _save(status: kStatusSubmitted);
  }

  Future<void> _leave() async {
    final discard = await confirm(
      context,
      'Your changes to this ritual have not been saved.',
      title: 'Leave without saving?',
      yes: 'Discard',
      no: 'Keep editing',
    );
    if (!discard || !mounted) return;
    setState(() => _dirty = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Keep a saved category selectable even if it is no longer in the catalogue.
    final names = [for (final c in _categories) c.name];
    if (_category != null && !names.contains(_category)) names.add(_category!);
    final titleMissing = _showErrors && _title.text.trim().isEmpty;
    final categoryMissing = _showErrors && _category == null;
    final template = _template;
    final guided = template != null;

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: kCream,
        bottomNavigationBar: _loading
            ? null
            : PinnedBar(
                child: guided && _status == kStatusDraft
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving || _uploading ? null : () => _save(status: kStatusDraft),
                              child: const Text('Save draft'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _saving || _uploading ? null : _submit,
                              child: _saving ? const ButtonSpinner() : const Text('Submit for documentation'),
                            ),
                          ),
                        ],
                      )
                    : FilledButton(
                        onPressed: _saving || _uploading ? null : _save,
                        child: _saving
                            ? const ButtonSpinner()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bookmark_added_outlined, size: 20),
                                  const SizedBox(width: 10),
                                  Text(guided ? 'Save changes' : 'Save to our Virasat'),
                                ],
                              ),
                      ),
              ),
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: guided ? 'Document ritual' : (widget.existing == null ? 'Add ritual' : 'Edit ritual'),
                back: true,
              ),
              Expanded(
                child: SoftSwitcher(
                  child: _loading
            ? const Loading(key: ValueKey('loading'))
            : ListView(
                key: const ValueKey('form'),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                children: [
                  if (template != null) _guidedHeader(template),
                  if (template == null || template.isDiy) ...[
                  SectionCard(
                    icon: Icons.temple_hindu_outlined,
                    title: 'Which ritual is this?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _title,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Ritual title *',
                            hintText: 'e.g. Chatti / Shashti Puja',
                            errorText: titleMissing ? 'Give the ritual a title' : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: ValueKey('category-$_category-${names.length}'),
                          initialValue: _category,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Main event category *',
                            errorText: categoryMissing ? 'Choose a ritual category' : null,
                          ),
                          hint: const Text('Choose main event category'),
                          items: [
                            for (final n in names)
                              DropdownMenuItem(
                                value: n,
                                child: Text(n, overflow: TextOverflow.ellipsis),
                              ),
                            const DropdownMenuItem(
                              value: _addCustom,
                              child: Text(
                                '+ Add custom primary ritual...',
                                style: TextStyle(fontWeight: FontWeight.w600, fontVariations: kW6),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == _addCustom) {
                              _addCustomCategory();
                              // Rebuild so the dropdown drops the "+ Add custom" selection.
                              setState(() {});
                              return;
                            }
                            setState(() {
                              _category = v;
                              _phase = '';
                              _dirty = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  ],
                  if (template == null) ...[
                  if (_phases.isNotEmpty)
                    SectionCard(
                      icon: Icons.explore_outlined,
                      title: 'Phase of the ceremony',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Optional. Pick the part of the ceremony this entry is about.',
                            style: TextStyle(color: kMuted, fontSize: 13.5),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final p in _phases)
                                ChoiceChip(
                                  label: Text(p),
                                  selected: _phase == p,
                                  showCheckmark: false,
                                  onSelected: (on) => setState(() {
                                    _phase = on ? p : '';
                                    _dirty = true;
                                  }),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  _profileCard(),
                  for (final s in _formSections(template)) _sectionFor(s),
                ],
              ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The sub-sections to show: the catalogue ritual's own, then any of the standard
  /// ones it leaves out, so every ritual can hold roles, songs, photos and notes.
  List<SubSection> _formSections(RitualTemplate? template) {
    final list = <SubSection>[
      if (template != null)
        for (final s in template.subSections)
          if (s.kind != SectionKind.title && s.kind != SectionKind.profile) s,
    ];
    const standard = [
      SubSection('Samagri needed', SectionKind.samagri),
      SubSection('Steps of the ritual', SectionKind.steps),
      SubSection('Food and recipes', SectionKind.food),
      SubSection('Roles of relatives', SectionKind.roles),
      SubSection('Songs, prayers & mantras', SectionKind.songs),
      SubSection('Photos', SectionKind.photos),
      SubSection('Additional Information', SectionKind.info),
    ];
    for (final s in standard) {
      if (!list.any((x) => x.kind == s.kind)) list.add(s);
    }
    return list;
  }

  Widget _guidedHeader(RitualTemplate template) {
    return MaroonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(template.stage.toUpperCase(), style: eyebrow()),
          const SizedBox(height: 8),
          Text(template.title, style: display(22, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusChip(_status, onDark: true),
              Pill(plural(template.subSections.length, 'sub-section', 'sub-sections'), onDark: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Fill at your own pace. Save a draft and come back after speaking to your elders.',
            style: body(13, color: Colors.white.withValues(alpha: 0.9)).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _profileCard() {
    return SectionCard(
      icon: Icons.account_balance_outlined,
      title: 'Ancestral Profile',
      child: Column(
        children: [
          TextField(
            controller: _gotra,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Family surname / Gotra', hintText: 'e.g. Mishra / Kashyap'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kuldevi,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Kuldevi', hintText: 'e.g. Vindhyavasini Mata'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kuldevta,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Kuldevta', hintText: 'e.g. Baba Vishwanath'),
          ),
        ],
      ),
    );
  }

  Widget _sectionFor(SubSection s) {
    switch (s.kind) {
      case SectionKind.samagri:
        return SectionCard(
          icon: Icons.shopping_basket_outlined,
          title: s.name,
          child: _multiline(_samagri, 'One item per line, e.g.\nHaldi, kumkum, akshat\nNaye kapde'),
        );
      case SectionKind.steps:
        return SectionCard(
          icon: Icons.format_list_numbered,
          title: s.name,
          child: _multiline(_steps, 'Write the steps in order, one per line'),
        );
      case SectionKind.food:
        return _foodCard(s.name);
      case SectionKind.roles:
        return SectionCard(
          icon: Icons.people_outline,
          title: s.name,
          child: _multiline(_roles, 'Who does what, one per line, e.g.\nMama: brings the bhaat'),
        );
      case SectionKind.songs:
        return _songsCard(s.name);
      case SectionKind.photos:
        return _photosCard(s.name);
      case SectionKind.info:
        return SectionCard(
          icon: Icons.notes_outlined,
          title: s.name,
          child: _multiline(_info, 'Anything else your family does or believes about this ritual'),
        );
      case SectionKind.title:
      case SectionKind.profile:
      case SectionKind.text:
        final controller = _sectionCtl[s.name];
        if (controller == null) return const SizedBox.shrink();
        return SectionCard(
          icon: Icons.edit_note_outlined,
          title: s.name,
          child: _multiline(controller, 'Describe it the way your family does it'),
        );
    }
  }

  Widget _foodCard(String title) {
    return SectionCard(
                    icon: Icons.soup_kitchen_outlined,
                    title: title,
                    trailing: TextButton.icon(
                      onPressed: () => _editRecipe(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                    child: _recipes.isEmpty
                        ? const EmptyNote('No recipe yet. Add the prasad and dishes cooked for this ritual.')
                        : Column(
                            children: [
                              for (var i = 0; i < _recipes.length; i++)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const IconBadge(Icons.soup_kitchen_outlined, size: 36),
                                  title: Text(_recipes[i].name, style: body(15, weight: 600)),
                                  subtitle: _recipes[i].ingredients.isEmpty
                                      ? const Text('Tap to add ingredients and method')
                                      : Text(
                                          _recipes[i].ingredients.replaceAll('\n', ', '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  onTap: () => _editRecipe(i),
                                  trailing: IconButton(
                                    tooltip: 'Remove',
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => setState(() {
                                      _recipes.removeAt(i);
                                      _dirty = true;
                                    }),
                                  ),
                                ),
                            ],
                          ),
                  );
  }

  Widget _songsCard(String title) {
    return SectionCard(
      icon: Icons.music_note_outlined,
      title: title,
      trailing: _uploading
                        ? const Padding(padding: EdgeInsets.all(12), child: ButtonSpinner())
                        : TextButton.icon(
                            onPressed: _pickAudio,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload'),
                          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _multiline(_songs, 'Write the songs, prayers and mantras as your family says them'),
          const SizedBox(height: 12),
          _audioPaths.isEmpty
                        ? const EmptyNote('No recording yet. Upload the songs sung during this ritual.')
                        : Column(
                            children: [
                              for (var i = 0; i < _audioPaths.length; i++)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const IconBadge(Icons.graphic_eq, size: 36),
                                  title: Text(
                                    _audioPaths[i].split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Remove',
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => setState(() {
                                      _audioPaths.removeAt(i);
                                      _dirty = true;
                                    }),
                                  ),
                                ),
                            ],
                          ),
        ],
      ),
    );
  }

  Widget _photosCard(String title) {
    return SectionCard(
      icon: Icons.photo_library_outlined,
      title: title,
      trailing: TextButton.icon(
        onPressed: _uploading ? null : _pickPhotos,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add'),
      ),
      child: _photoPaths.isEmpty
          ? const EmptyNote('No photo yet. Add up to 6 photos and say what each one shows.')
          : Column(
              children: [
                for (var i = 0; i < _photoPaths.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: MediaImage(_photoPaths[i], cacheWidth: 200),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _captionCtl[i],
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(hintText: 'Caption: who and what is in this photo'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() {
                            _photoPaths.removeAt(i);
                            _captionCtl.removeAt(i).dispose();
                            _dirty = true;
                          }),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _multiline(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 8,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(hintText: hint, hintMaxLines: 3),
    );
  }
}
