import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/tables.dart';
import '../../core/providers.dart';
import '../../core/util/format.dart';

/// Preset category colors (the seed palette + a few extras).
const _palette = <int>[
  0xFF2C3E50, 0xFF2980B9, 0xFFF39C12, 0xFF7F8C8D, 0xFFC0392B, 0xFF2ECC71,
  0xFF54B2B6, 0xFF8E44AD, 0xFF27AE60, 0xFFE74C3C, 0xFF16A085, 0xFFD35400,
];

class EditExerciseScreen extends ConsumerStatefulWidget {
  const EditExerciseScreen({super.key, this.exerciseId});

  final int? exerciseId;

  @override
  ConsumerState<EditExerciseScreen> createState() =>
      _EditExerciseScreenState();
}

class _EditExerciseScreenState extends ConsumerState<EditExerciseScreen> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int? _categoryId;
  ExerciseType _type = ExerciseType.weightAndReps;

  @override
  void initState() {
    super.initState();
    if (widget.exerciseId != null) _load();
  }

  Future<void> _load() async {
    final ex = await ref
        .read(exerciseRepositoryProvider)
        .getExercise(widget.exerciseId!);
    setState(() {
      _nameCtrl.text = ex.name;
      _notesCtrl.text = ex.notes ?? '';
      _categoryId = ex.categoryId;
      _type = ex.type;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final editing = widget.exerciseId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Exercise' : 'New Exercise'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (cats) {
          _categoryId ??= cats.isNotEmpty ? cats.first.id : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _categoryId,
                          items: [
                            for (final c in cats)
                              DropdownMenuItem(
                                value: c.id,
                                child: Row(children: [
                                  CircleAvatar(
                                      radius: 6,
                                      backgroundColor: Color(c.colorArgb)),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ]),
                              ),
                          ],
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New category',
                    icon: const Icon(Icons.add),
                    onPressed: _addCategory,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ExerciseType>(
                    isExpanded: true,
                    value: _type,
                    items: [
                      for (final t in ExerciseType.values)
                        DropdownMenuItem(
                            value: t, child: Text(exerciseTypeLabel(t))),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addCategory() async {
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (_) => const _NewCategoryDialog(),
    );
    if (result == null) return;
    final id = await ref
        .read(exerciseRepositoryProvider)
        .createCategory(name: result.$1, colorArgb: result.$2);
    setState(() => _categoryId = id);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _categoryId == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Name and category are required')));
      return;
    }
    final repo = ref.read(exerciseRepositoryProvider);
    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    if (widget.exerciseId == null) {
      await repo.createExercise(
          name: name, categoryId: _categoryId!, type: _type, notes: notes);
    } else {
      await repo.updateExercise(
          id: widget.exerciseId!,
          name: name,
          categoryId: _categoryId!,
          type: _type,
          notes: notes);
    }
    nav.pop();
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _ctrl = TextEditingController();
  int _color = _palette.first;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _palette)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    backgroundColor: Color(c),
                    radius: 14,
                    child: _color == c
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = _ctrl.text.trim();
            if (name.isNotEmpty) Navigator.pop(context, (name, _color));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
